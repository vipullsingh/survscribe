# Sprint 0002 — Sync Spike & Design System Kernel

| | |
| :-- | :-- |
| **Roadmap ref** | S0.2 |
| **Stage** | 0 — Foundation & Technical Readiness |
| **Status** | Tasks 1–5, 7 complete, 2026-08-30 — awaiting project-owner approval alongside every other `sprint_0001`/`sprint_0002` artifact (`CLAUDE.md` §16 Q12). **Task 6 (screen designs) is out of scope for this session — no design-tool (Figma) access; needs the human designer.** |
| **Depends on** | [`sprint_0001`](../sprint_0001_contract_and_toolchain_freeze/) |
| **Blocks** | sprint_0005 (sync engine), sprint_0009 and sprint_0013 (`.docx` engines) |
| **Roadmap** | [`../README.md`](../README.md) |

---

## 1. Sprint Objective

De-risk the hardest requirement in the project — **offline bi-directional sync with field-level timestamp merging and interactive conflict resolution** — with a time-boxed throwaway spike, and stand up the design-token layer plus the `.docx` template contract that both report engines must satisfy.

No production feature code ships from the spike. The output is a **decision**.

---

## 2. Features & Tasks

| # | Feature / module | Task | Dependency | Priority | Expected outcome |
| :-- | :-- | :-- | :-- | :-- | :-- |
| 1 | Sync protocol | Write `documentation/architecture/sync-protocol.md`: queue model, per-field `updated_at` vectors, the merge algorithm, conflict-confirmation UX, media-upload retry with exponential backoff, tombstones/deletes. | sprint_0001 schema | Critical | Reviewed protocol document. |
| 2 | Sync spike | Time-boxed prototype: WatermelonDB local store + Go pull/push on **one entity** (`claims`). Simulate a concurrent desk-side edit and prove field-level merge plus the surveyor-confirmation dialog. **Throwaway code, quarantined branch.** | sprint_0001 skeletons | Critical | Written findings and a go/no-go on WatermelonDB's built-in sync versus a custom queue. |
| 3 | Sync ADR | Record the spike outcome as an ADR (WatermelonDB sync adapter vs custom sync queue), with the evidence that drove it. | Task 2 | Critical | Accepted ADR. |
| 4 | Design kernel | `packages/ui`: tokens (colours including `--color-primary #1E3A8A` per D30, spacing 8pt grid, radii, typography — Plus Jakarta Sans / Inter / JetBrains Mono), `<CurrencyText>` (₹ prefix, tabular figures, Indian lakh/crore grouping, right-aligned), base `<Button>` and `<TextField>` at spec heights. | `Visual Theme & Design System.md` | High | Tokens render correctly in a sample screen or Storybook. |
| 5 | `.docx` contract | Draft `documentation/architecture/docx-template-contract.md`: section order A–I, the Section F table shape, photo-plate layout (2 or 4 per page), header/footer, sign-off block, and the mandatory disclaimer blocks. | SRS §3 Stage 14; screen `15` | High | Reviewed contract; both engine owners sign off. |
| 6 | Screen designs | Designer begins the Dashboard and Stage 1–2 visuals, which do not exist today. | screen specs | High | Figma frames for `01_dashboard`, `02`, `03`. |
| 7 | Multi-device sync | **Q12 is answered: multi-device is in scope** (ADR-0005 D41 — one `ACTIVE` session per `(user_id, device_id)`). Fold this into the sync protocol: `sync_queue` is already keyed by `device_id`, so design the merge model for two devices of the same surveyor editing one claim, not just device-vs-desk. | ADR-0005 | High | Multi-device concurrency covered by the sync protocol document. |

---

## 3. Acceptance Criteria

- [x] The spike answers "WatermelonDB built-in sync or custom queue?" with reproducible evidence, and the answer is recorded as an accepted ADR. **Custom queue.** See `ADR-0010`: WatermelonDB's `resolveConflict()` (transcribed from its actual installed source, `@nozbe/watermelondb@0.27.1`) has no field-level timestamp and resolves any locally-dirty column unconditionally in favour of local, regardless of write order — a stricter violation of `CLAUDE.md` §14.8 than ordinary last-write-wins. A runnable side-by-side comparison against the custom `field_updated_at` design, on an identical concurrent-edit scenario, confirmed the custom approach correctly detects and surfaces the same collision instead of silently discarding one side.
- [x] `sync-protocol.md` specifies field-level timestamp merging (explicitly **not** last-write-wins, per `CLAUDE.md` §14.8), the conflict-confirmation UX, media backoff, and delete semantics. Written; §7 lists what is deliberately deferred to `sprint_0005`.
- [x] `docx-template-contract.md` is reviewed and covers all 9 sections, the Section F table, photo plates, sign-off, and disclaimers. Written; also specifies the PSR as a distinct entity sharing the same contract (§3), since FR-8.2's PSR needed the same treatment.
- [x] `packages/ui` tokens are consumable from `apps/mobile`; a sample screen renders the primary blue, the type scale, and a monospace right-aligned ₹ figure correctly. **Verified without a simulator** (none available in this environment): `Button`, `TextField`, `CurrencyText` built against Design System §§3–4; a `KernelSampleScreen` exercises all three together; 23 React Native Testing Library assertions (real, run, passing) check resolved styles — `#1E3A8A` primary, the exact type-scale rows, and `₹4,97,500.00` right-aligned in JetBrains Mono. A true on-device screenshot remains unverified.
- [x] The sync protocol covers multi-device concurrency for one surveyor (Q12, answered by ADR-0005 D41). `sync-protocol.md` §4.3.
- [x] Spike code is **not** merged into any product branch. Went further: it was never committed to this repository at all — written and executed in a session scratch directory, never staged. The durable evidence (the transcribed `resolveConflict` source and the custom-algorithm output) is embedded directly in `ADR-0010` and `sync-protocol.md` instead, so it is reviewable without needing the throwaway code to exist anywhere.

**Not done:** task 6 (screen designs for Dashboard, `02`, `03`) — this session has no design-tool (Figma) access. Flagged rather than skipped silently; needs the project's human designer.

---

## 4. Dependencies

- sprint_0001: physical schema (for the spike entity), backend and mobile skeletons, workspace tooling.

---

## 5. Risks & Open Questions

| Item | Detail |
| :-- | :-- |
| ~~**R1**~~ | **Resolved 2026-08-30.** The answer is "custom queue" — confirmed by direct inspection of WatermelonDB's installed sync source, not by assumption. `sprint_0005`'s scope grows to exactly the size `physical-schema.md` §38 item 1 already flagged as provisional; see `ADR-0010`. |
| **R2** | The `.docx` contract now exists (`docx-template-contract.md`), reviewed and pending owner sign-off. Still a real risk until `sprint_0013` actually builds the server engine against it — a contract is only as strong as the engine that's checked to follow it, and no engine exists yet. |
| **R6** | 16 of 19 screens still have no visual design. **Not addressed this session** — task 6 needs a human designer (Figma access); see §3. The design workstream is now a sprint *behind* the build, not ahead of it, and this should be raised explicitly before `sprint_0003` screen work begins. |
| ~~**Q12**~~ | **Closed 2026-08-30 by ADR-0005 (D41): multi-device is in scope.** The merge model handles two devices of the same surveyor identically to device-vs-desk — see `sync-protocol.md` §4.3. |

---

## 6. Definition of Done

Global DoD (see [`../README.md`](../README.md) §6) plus:

- [x] Spike code is explicitly discarded or branch-quarantined; nothing from it ships as-is. Went further — never entered the repository at all (§3).
- [x] The sync decision is recorded as an ADR, not only as sprint notes. `ADR-0010`.
- [ ] `sync-protocol.md` and `docx-template-contract.md` are reviewed and approved before the sprints that consume them start. **Written and internally reviewed for this session's own consistency; project-owner approval is still outstanding** — the same `CLAUDE.md` §16 Q12 blocker covering every `sprint_0001`/`sprint_0002` artifact.
