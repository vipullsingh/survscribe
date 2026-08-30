# Sync Protocol — Offline-First Bi-Directional Sync

> **Document type:** Protocol specification for the mobile ↔ server sync engine.
> **Version:** 1.0.0 · **Created:** 2026-08-30 (`sprint_0002` task 1, folding in task 7). **Status:** Reviewed protocol — awaiting project-owner approval alongside every other `sprint_0001`/`sprint_0002` artifact (`CLAUDE.md` §16 Q12).
> **Governing decisions:** ADR-0001 D20 (WatermelonDB local storage), **ADR-0010** (custom sync algorithm, not WatermelonDB's built-in `synchronize()`), ADR-0005 D41 (multi-device sessions), `physical-schema.md` §18 and §36.
> **Implements:** `CLAUDE.md` §14 constraints 7 and 8 (offline-first; field-level timestamp conflict resolution, not last-write-wins); `Requirement.MD` §6.1 (media compression, retry with exponential backoff); AC 16.1.3 (surveyor confirmation on concurrent edits).
> **Consumed by:** `sprint_0005` (sync engine implementation), and every stage sprint whose screens write data that must sync.

---

## 1. Why this document exists

`ADR-0010` establishes, with source-level evidence, that WatermelonDB's built-in sync engine cannot deliver field-level conflict detection with human confirmation — it silently prefers whichever side happens to hold a locally-dirty column, with no timestamp comparison at all. This document specifies the protocol that replaces it. WatermelonDB itself remains the mobile local database (ADR-0001 D20): this protocol is a layer on top of ordinary WatermelonDB reads/writes, not a replacement for WatermelonDB.

Everything below targets one entity type generically (`claims` is the worked example throughout, per `sprint_0002` task 2), but the protocol is the same for every synced table in `physical-schema.md` Part B — they all carry the three sync columns defined in `physical-schema.md` §18: `client_updated_at`, `field_updated_at`, `sync_revision`.

---

## 2. Model

### 2.1 The three sync columns, restated

Every synced table carries:

```sql
client_updated_at    TIMESTAMPTZ,                          -- device wall-clock at last local edit
field_updated_at     JSONB NOT NULL DEFAULT '{}'::jsonb,   -- { "column_name": "ISO-8601 timestamp" }
sync_revision         BIGINT NOT NULL DEFAULT 0,            -- server-assigned, monotonic per row
```

`field_updated_at` is the mechanism ADR-0010's spike validated: a map from column name to the timestamp at which *that specific column* was last written, tracked independently per field rather than once per row. `sync_revision` is a per-row version counter, bumped by the server on every accepted write, used for the pull side (§4) and as a cheap "has anything about this row changed" signal — it is not itself used for conflict detection, which is entirely field-scoped.

### 2.2 Device identity

Every device that syncs is a row in `user_devices` (`physical-schema.md` Part A §9), keyed by a stable `device_id` generated once at install and persisted for the app's lifetime. A push or pull always carries `device_id`; the server never infers device identity from IP or session alone, because ADR-0005 D41 makes multi-device — several devices for one surveyor — an explicit, supported case, not an edge case.

### 2.3 The device-side outbox

Every offline write is recorded on-device before it is attempted against the server. WatermelonDB's own local database *is* this record — a locally-created or locally-updated row already carries the new field values. What WatermelonDB does not track for us is field-level timestamps, so the device layer additionally maintains, per row, a `field_updated_at` map identical in shape to the server column, updated at the moment of every local write (not at sync time). This is the client-side mirror of `sync_queue` (`physical-schema.md` §36); the server-side `sync_queue` table exists for operational visibility (a support engineer looking at what a device is stuck on) and is explicitly a mirror, not the source of truth.

---

## 3. Push — the device sends its changes

### 3.1 Request shape

One push carries every locally-pending change since the last successful push, batched per entity:

```jsonc
POST /api/v1/sync/push
{
  "device_id": "…",
  "changes": [
    {
      "entity": "assessment_line_items",
      "entity_id": "…uuid, client-generated…",
      "claim_id": "…uuid…",
      "operation": "UPDATE",                 // CREATE | UPDATE | DELETE
      "payload": { "depreciation_pct": 20.00, "justification_remarks": "…" },
      "field_updated_at": {
        "depreciation_pct": "2026-04-02T09:40:00.000Z",
        "justification_remarks": "2026-04-02T09:40:00.000Z"
      },
      "base_sync_revision": 4,               // the sync_revision this device last pulled
      "client_updated_at": "2026-04-02T09:40:00.000Z"
    }
  ]
}
```

`payload` carries only the columns actually edited — never a full-row snapshot. A push that sent every column every time would make it impossible to tell an intentional edit from an unchanged value the device merely re-sent, and would silently overwrite fields the device never touched.

### 3.2 Per-field acceptance rule (ADR-0010's algorithm)

The server evaluates each pushed field independently, never the row as a whole:

```
for each (column, value) in payload:
    server_ts   = row.field_updated_at[column]         // null if never set
    device_ts   = the device's OWN prior field_updated_at[column],
                  i.e. what it believed the field's timestamp was
                  before making this edit (carried in the same request
                  as "known_field_updated_at" alongside field_updated_at
                  -- see 3.3)

    if server_ts is null OR device_ts >= server_ts:
        ACCEPT: row[column] = value
                row.field_updated_at[column] = payload.field_updated_at[column]
    else:
        CONFLICT: do not write. Surface both values (4.2).
```

A field is accepted if the device was not "behind" on that specific field when it made its edit — i.e. no one else changed that exact field after the device last knew about it. A field is a conflict only when two edits to the *same column* happened in a window where neither device knew about the other's change. Edits to different columns on the same row never conflict, no matter how close in time — this was verified explicitly as a control case in the `ADR-0010` spike.

### 3.3 What the device must send to make this possible

The rule in 3.2 needs one more piece of information than 3.1 showed: the device's belief about the field's timestamp *before* its own edit — not just the new timestamp *after*. The full per-field push entry is:

```jsonc
{
  "column": "depreciation_pct",
  "value": 20.00,
  "edited_at": "2026-04-02T09:40:00.000Z",        // when the device made this edit
  "known_as_of": "2026-04-02T08:00:00.000Z"        // the field's timestamp at the device's last successful pull of this row
}
```

`known_as_of` is simply whatever value the device last received in `field_updated_at[column]` from a pull (§4) or from the acceptance response of a prior push (§3.4) — it requires no extra tracking beyond keeping the last-seen server timestamp per field, which the device already needs to render "last updated" UI.

### 3.4 Response shape

```jsonc
{
  "accepted": [
    { "entity": "assessment_line_items", "entity_id": "…", "sync_revision": 5,
      "server_assigned": {} }
  ],
  "conflicts": [
    {
      "entity": "cause_investigations", "entity_id": "…",
      "fields": {
        "reported_cause": {
          "local": "Fire - overheating of transformer", "local_at": "2026-04-02T09:40:00.000Z",
          "server": "Fire - short circuit, LT panel",   "server_at": "2026-04-02T09:15:00.000Z"
        }
      }
    }
  ],
  "server_revision": 5
}
```

`server_assigned` carries values the device could not have known — most importantly `claims.claim_ref_no`, which `physical-schema.md` §20 allocates server-side because two offline devices cannot agree on the next number in a per-store sequence. A CREATE push for a new claim is always accepted (there is nothing to conflict with yet); the response's `server_assigned.claim_ref_no` is what turns the device's `temp_ref_no` into a real reference once connectivity returns.

**Every accepted field write is audited.** A push that changes `assessment_line_items.depreciation_pct` or any other loss-assessment figure writes an `audit_log` row (`physical-schema.md` §35) with `is_offline_origin = true` and `client_occurred_at` set to the device's `edited_at` — not the moment the push happened to reach the server. Without this, every offline edit would appear in the audit trail to have happened at the moment of reconnection, which would misrepresent when a surveyor actually made a change to a figure `CLAUDE.md` §14 constraint 10 requires immutably logged.

---

## 4. Pull — the device receives others' changes

### 4.1 Request and response

```jsonc
GET /api/v1/sync/pull?device_id=…&since_revision=4&limit=200

{
  "changes": [
    { "entity": "cause_investigations", "entity_id": "…", "claim_id": "…",
      "operation": "UPDATE",
      "payload": { "reported_cause": "Fire - short circuit, LT panel" },
      "field_updated_at": { "reported_cause": "2026-04-02T09:15:00.000Z" },
      "client_updated_at": "2026-04-02T09:15:00.000Z" }
  ],
  "server_revision": 7,
  "has_more": false
}
```

A pull is a plain replication feed: every row whose `sync_revision` exceeds the device's last-known revision, changed by *any* device or the server itself. It carries no conflict logic of its own — conflicts are detected only on push (§3.2), because that is the one moment a device's belief about a field and the server's current truth are compared. A pulled change is simply applied to the local WatermelonDB row (updating its own `field_updated_at` mirror), **unless** the device has a pending local edit to that exact field that has not yet been pushed — in which case the pulled value is held pending and surfaced through the same conflict-confirmation path as §4.2, rather than silently overwriting an edit the surveyor hasn't had a chance to sync yet.

### 4.2 The conflict-confirmation UX

A conflict — from a push rejection (§3.4) or a pull-vs-pending-local-edit collision (§4.1) — is never resolved automatically in either direction. It becomes a row in the device's local "needs your attention" list, rendered as a structured card per the design system's audit-box treatment (`Design System.md` §5): both values shown side by side, with their timestamps and (where available) the name of who made each edit, and two explicit actions — "Keep mine" or "Use theirs" — never a silent merge, never a "smart" auto-pick. The surveyor's choice is itself a new edit: it re-pushes the chosen value with a fresh `edited_at`, which is accepted normally because it is now strictly newer than both prior values. This satisfies AC 16.1.3's "surveyor confirmation" literally, not as a background reconciliation.

A claim with unresolved conflicts is not blocked from other edits — the surveyor can keep working on unrelated fields, stages, and even other claims. Only the specific conflicting field is held. This matters operationally: a field surveyor should never be stopped mid-inspection by a disagreement over one earlier field.

### 4.3 Multi-device concurrency (task 7 — closes Q12)

ADR-0005 D41 makes multi-device explicit: one surveyor may hold an `ACTIVE` session on a phone and a tablet simultaneously, one `ACTIVE` session per `(user_id, device_id)`. Nothing in §3–4.2 is device-count-specific — the protocol already treats "another device" and "the desk-side web reviewer" identically, both as a `device_id` distinct from the one pushing. The one place multi-device concurrency needs an explicit statement:

**A conflict is scoped to a row and a field, never to a device pair.** If a surveyor edits `damage_items.damage_severity` on their phone while their tablet (still open from an earlier session, also offline) holds a stale but unedited copy of the same row, there is no conflict when the tablet reconnects — it has no pending edit to that field, so the phone's pushed value simply arrives as an ordinary pull. A conflict only exists when **both** sides have an actual unpushed edit to the same field, regardless of whether those two sides are two different people or the same surveyor's two devices. The protocol needs no special case for "my own other device" versus "someone else" — treating every device identically is what makes the multi-device requirement free to support once the field-level design is right.

**One practical consequence for `sprint_0005`:** the "Keep mine / Use theirs" UI (§4.2) should show the device name (`user_devices.device_name`) alongside the actor, not just the actor's name — "Your edit (this iPhone), 9:40 AM" vs. "Your edit (Tablet — Site Office), 9:15 AM" is the case where the two conflicting values may both legitimately be the same surveyor's own intent, captured on two devices, and the UI should say so rather than implying a disagreement between two different people.

---

## 5. Deletes and tombstones

Every synced table is soft-deletable (`physical-schema.md` §18) — a hard `DELETE` on one device is invisible to another device's pull, since there is no row left to report as changed. A delete is therefore pushed as an ordinary change with `operation: "DELETE"`, which the server applies as `deleted_at = NOW()` rather than a real `DELETE`, and which then appears in every other device's next pull as a change with `operation: "DELETE"` — the device removes (or hides) its local copy in response, exactly as it would apply any other field update.

A delete can itself conflict: device A deletes a `salvage_records` row while device B, offline, has an unpushed edit to a field on that same row. This is treated identically to a field conflict (§4.2) — the surveyor sees "this record was deleted elsewhere; you edited it locally" as the conflict card, with "Keep my edit (undelete)" or "Confirm delete" as the two resolutions. A delete is never silently allowed to win over a pending edit, nor the reverse.

**Evidence tables never lose rows outright**, per `CLAUDE.md` §14 constraints 9–10: `media_attachments` and `documents` soft-delete the same way as every other table, and their tombstones are excluded from the FSR annexure and Stage 15 gate checks but are never purged automatically. Deletion of evidence is always a human, auditable action, never a sync side-effect.

---

## 6. Media upload: chunked, with exponential backoff

`Requirement.MD` §6.1 requires "upload retry with exponential backoff" and a "background sync queue" for media specifically, distinct from the field-sync protocol above because a photo or voice note is orders of magnitude larger than a row of JSON.

1. A captured photo is compressed and watermarked on-device (JPEG 1600×1200 @ 85%, per `CLAUDE.md` §14 constraint 9) **before** it is queued — the upload queue never holds an unprocessed original.
2. The `media_attachments` row itself syncs through the ordinary field protocol above (§3) immediately — its metadata (caption, category tag, GPS, capture timestamp) is small and should reach the server even while the binary is still queued. `upload_status` starts `PENDING`.
3. The binary uploads via `POST /media/uploads` (init) → `PUT /media/uploads/{id}/chunks/{n}` (chunked, so a large file survives a connection drop mid-transfer without restarting) → `POST /media/uploads/{id}/complete` (server recomputes SHA-256, rejects a mismatch), per the OpenAPI contract (`api-contract/openapi.yaml`).
4. On any failure — no connectivity, a timeout, a server error — the device retries with exponential backoff: 1s, 2s, 4s, 8s, ... capped at 5 minutes between attempts, indefinitely, until connectivity returns. `media_attachments.upload_attempts` tracks the count for observability; there is no maximum-attempts abandonment for evidence media, because a photo the surveyor captured in the field cannot simply be given up on.
5. `upload_status` moves `PENDING → IN_FLIGHT → SYNCED` on success, or reports `FAILED` transiently between backoff attempts (never a terminal failure state for evidence).

The backoff schedule is intentionally the same shape (doubling, capped) as the field-sync push retry, so the device's connectivity-recovery logic is one mechanism serving both paths rather than two independently-tuned ones.

---

## 7. What this protocol deliberately does not decide yet

Flagged for `sprint_0005`, which owns the full implementation:

1. **Batch size and pagination tuning** for push/pull under real field-connectivity conditions (2G/3G, high latency, intermittent).
2. **Conflict list UI details** beyond the two-value-two-action shape in §4.2 — ordering, grouping by claim vs. by field, badge counts.
3. **Server-side `sync_queue` retention** — how long a processed row is kept for the support-visibility use case before being pruned.
4. **Cross-entity ordering** — a push batch may reference a `damage_item_id` that itself was created in the same batch; the exact dependency-ordering rule for applying a batch server-side is not specified here.
5. **Whether `sync_revision` is per-row or a single global sequence** — this document treats it as per-row (simpler pull queries); a global sequence would simplify some "what changed since X" bookkeeping at the cost of contention on a single counter. Left to `sprint_0005`.

None of these affect the field-level conflict algorithm itself, which is what this sprint's spike was scoped to de-risk (`ADR-0010`).
