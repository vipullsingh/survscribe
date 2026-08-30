# ADR-0010 — Sync Protocol: Custom Field-Level Queue, Not WatermelonDB's Built-In Sync

- **Status:** Accepted
- **Date:** 2026-08-30
- **Deciders:** Project owner (vipul@tezminds.com)
- **Sprint:** `sprint_0002` tasks 2–3 (the sync spike)
- **Closes:** `sprint_0002` R1; the go/no-go this sprint exists to produce
- **Depends on:** ADR-0001 D20 (WatermelonDB as local storage), `physical-schema.md` §18 and §36, `CLAUDE.md` §14 constraint 8

---

## Context

`CLAUDE.md` §14 constraint 8 requires "bi-directional sync with field-level timestamp conflict resolution. **Not last-write-wins.**" AC 16.1.3 requires surveyor confirmation on a concurrent edit. `physical-schema.md` §18 and §36 already assume a design that satisfies both — per-field `field_updated_at` timestamps and a `sync_queue.conflict_fields` payload for an interactive resolution UI — but flagged those columns as **provisional**, deferred to this sprint's spike, because ADR-0001 D20 chose WatermelonDB for local storage without examining whether its *sync* engine (not just its local database) could deliver the same guarantee.

This ADR answers that question with source-level evidence rather than assumption, closing `sprint_0002` R1.

---

## Decision

**Use WatermelonDB purely as the local reactive database (D20 stands unchanged). Do not use WatermelonDB's built-in `synchronize()` sync engine. Implement a custom sync protocol** built around per-field timestamps, specified in [`sync-protocol.md`](../architecture/sync-protocol.md).

### The evidence

Both algorithms were run against the identical scenario: two devices, one claim, one field genuinely edited on both sides while disconnected from each other.

**Method.** `@nozbe/watermelondb@0.27.1` was installed and its actual sync implementation read directly from `node_modules/@nozbe/watermelondb/sync/impl/helpers.js`. The `resolveConflict` function — the exact code WatermelonDB runs to merge a pulled remote record against a locally-modified one — is reproduced in full below, unminified, logic unchanged:

```js
// resolveConflict(local, remote) — @nozbe/watermelondb 0.27.1
// node_modules/@nozbe/watermelondb/sync/impl/helpers.js
function resolveConflict(local, remote) {
  if (local._status === 'deleted') return local;

  const resolved = { ...local, ...remote, id: local.id, _status: local._status, _changed: local._changed };

  // Use local properties where changed
  local._changed.split(',').forEach((column) => {
    resolved[column] = local[column];
  });
  return resolved;
}
```

`local._changed` is WatermelonDB's per-record dirty-column tracking: a comma-separated list of columns touched locally since the last successful sync. **That list carries no timestamp.** It records *that* a column changed, never *when*.

A runnable spike (`node spike.js`, evidence retained outside the repository per this ADR's Consequences) exercised this function against a scenario built from `physical-schema.md`'s own domain: two devices disagree about `cause_investigations.reported_cause` after a fire — device B (desk-side, online) edits it at T1 and pushes; device A (a field surveyor, offline since before T1) independently edits the *same field* at T2 with no knowledge of B's change, then reconnects and syncs.

**Result of `resolveConflict(localA, remoteWithBsEdit)`:** A's value overwrites B's value completely. B's edit is silently discarded. No conflict is raised, no timestamp is compared — because none exists to compare. Whichever device happens to sync second when it holds a locally-dirty copy of the field wins, unconditionally, regardless of which edit is actually more recent in wall-clock time. This is not merely "last-write-wins" in the informal sense; it is *local*-write-wins irrespective of write order, which is a strictly weaker guarantee than the informal LWW that `CLAUDE.md` already rules out.

**The same scenario run against the custom design** (`field_updated_at: { column: ISO8601 }`, checked per push: accept the field only if the pushing device's own last-known timestamp for that exact field is not older than the server's current timestamp for it): the push for `reported_nature_of_loss` is **rejected and returned as a conflict** — `{ local: "...", local_at: T2, server: "...", server_at: T1 }` — with neither value discarded, in the exact shape `sync_queue.conflict_fields` (§36) already specifies for the surveyor-confirmation UI. A control case (two devices editing *different* fields) was also run and merges cleanly under both algorithms — the two approaches only diverge on the case that matters, a genuine same-field collision.

### Why not `conflictResolver`

WatermelonDB's sync API exposes one customization hook, `conflictResolver(table, local, remote, resolved) => resolved`. It looked, before inspection, like it might let a custom merge (or even a pause-for-human step) be substituted for the default. It cannot, for two structural reasons found in the type definition (`sync/index.d.ts`) and confirmed by how `synchronize()` invokes it:

1. **It is synchronous and must return within the sync transaction.** There is no path from this hook to a UI dialog awaiting a surveyor's tap — "pause sync, show a conflict card, resume on confirmation" is not an operation this hook can perform. It can only compute a different in-memory merge, immediately.
2. **It still receives only `local`/`remote`/WatermelonDB's own `resolved`, none of which carry a per-field timestamp**, because the underlying `_changed` tracking never captured one. A field-level *timestamp* comparison cannot be built inside a hook whose inputs contain no timestamp.

A custom `conflictResolver` could technically be written to *detect* that a field is dirty on both sides (compare `local[_changed]` against a supplied remote change-set) and refuse to resolve it — but at that point the hook is not customizing WatermelonDB's sync, it is replacing its reason for existing, while still being bound by point 1's synchronous constraint. There is no partial-credit configuration of the built-in engine that clears the bar.

---

## Consequences

- **`physical-schema.md` §18's sync columns move from provisional to confirmed**, with the qualification that the exact `sync_queue` shape is still `sprint_0005`'s to build in full (this ADR fixes the *algorithm*, not every implementation detail).
- **WatermelonDB stays the mobile local database** (D20 unchanged) — SQLite-backed, reactive, offline-capable. Only its `sync/` module is unused. The app calls WatermelonDB's ordinary write/query/observe API and layers a hand-written push/pull client on top, exactly as `sync-protocol.md` specifies.
- **`sprint_0005`'s scope is confirmed at the size `physical-schema.md` §38 item 1 already flagged**, not enlarged: a custom queue was always the fallback path envisioned there; this ADR removes the "or maybe WatermelonDB's engine handles it" branch rather than adding new work.
- **The spike code that produced this evidence is not part of this repository.** Per the sprint's own DoD ("spike code is not merged into any product branch") and this project's rule against creating git branches without explicit instruction, the throwaway prototype was written and executed outside the repository entirely — a session scratch directory, never staged, never committed — rather than committed to a branch for later deletion. The transcribed `resolveConflict` source above, and the merge-algorithm excerpts in `sync-protocol.md`, are the durable record; both are independently reproducible by anyone who installs `@nozbe/watermelondb@0.27.1` and reads the same file.
- A live end-to-end run — an actual WatermelonDB-backed mobile client talking to an actual Go pull/push endpoint over a network — was **not** performed. This decision rests on algorithmic analysis of the merge logic (both real, both executed, both exercised against the same domain scenario), not on an integration test. `sprint_0005` should still validate the full pipeline once real endpoints exist.

---

## Alternatives considered

**Use WatermelonDB's `synchronize()` with a custom `conflictResolver`.** Rejected for the two structural reasons above: the hook cannot pause for a human, and it has no timestamp to reason with even for a same-side comparison. Retrofitting one would mean maintaining a shadow field-timestamp store *alongside* WatermelonDB's own `_changed` tracking, duplicating exactly the mechanism a fully custom protocol needs anyway, while still being constrained by WatermelonDB's synchronous resolution point. No net simplification.

**Use WatermelonDB's built-in sync and accept local-wins semantics, with a background reconciliation job to catch same-field conflicts after the fact.** Rejected: it means every sync silently applies a resolution that may be wrong, with detection (if any) happening later and out of band from the edit itself. AC 16.1.3 asks for confirmation *at the point of conflict*, not a retrospective audit.

**A fully custom local store (no WatermelonDB) with a bespoke reactive layer.** Not evaluated in depth — out of scope for this spike, which only had to determine whether WatermelonDB's *sync engine* specifically was viable. Its local-database half (SQLite adapter, reactive queries, offline writes) is unaffected by this finding and D20 stands.
