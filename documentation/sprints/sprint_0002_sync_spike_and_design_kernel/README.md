# Sprint 0002 — Sync Spike & Design System Kernel

| | |
| :-- | :-- |
| **Roadmap ref** | S0.2 |
| **Stage** | 0 — Foundation & Technical Readiness |
| **Status** | Not started |
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
| 7 | Clarification | Answer **Q12** — is concurrent use by one surveyor on two devices in scope? It changes the sync design. | — | High | Written answer folded into the sync protocol. |

---

## 3. Acceptance Criteria

- [ ] The spike answers "WatermelonDB built-in sync or custom queue?" with reproducible evidence, and the answer is recorded as an accepted ADR.
- [ ] `sync-protocol.md` specifies field-level timestamp merging (explicitly **not** last-write-wins, per `CLAUDE.md` §14.8), the conflict-confirmation UX, media backoff, and delete semantics.
- [ ] `docx-template-contract.md` is reviewed and covers all 9 sections, the Section F table, photo plates, sign-off, and disclaimers.
- [ ] `packages/ui` tokens are consumable from `apps/mobile`; a sample screen renders the primary blue, the type scale, and a monospace right-aligned ₹ figure correctly.
- [ ] Q12 has a written answer.
- [ ] Spike code is **not** merged into any product branch.

---

## 4. Dependencies

- sprint_0001: physical schema (for the spike entity), backend and mobile skeletons, workspace tooling.

---

## 5. Risks & Open Questions

| Item | Detail |
| :-- | :-- |
| **R1** | WatermelonDB's built-in sync is oriented toward record-level reconciliation and may not natively support field-level merge with an interactive conflict prompt. This spike exists precisely to find out before sprint_0005 commits. If the answer is "custom queue", sprint_0005 grows — surface that immediately rather than absorbing it silently. |
| **R2** | The `.docx` contract is the only thing preventing the client (TS) and server (Go) engines from drifting. Weak contract now equals rework in sprint_0013. |
| **R6** | 16 of 19 screens have no visual design. The design workstream must stay one sprint ahead of the build from here on. |
| **Q12** | Multi-device concurrency changes the merge model. |

---

## 6. Definition of Done

Global DoD (see [`../README.md`](../README.md) §6) plus:

- Spike code is explicitly discarded or branch-quarantined; nothing from it ships as-is.
- The sync decision is recorded as an ADR, not only as sprint notes.
- `sync-protocol.md` and `docx-template-contract.md` are reviewed and approved before the sprints that consume them start.
