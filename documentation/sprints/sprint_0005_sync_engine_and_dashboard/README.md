# Sprint 0005 — Sync Engine v1 & Dashboard

| | |
| :-- | :-- |
| **Roadmap ref** | S1.3 |
| **Stage** | 1 — Core Data & Application Foundation |
| **Status** | Not started |
| **Depends on** | [`sprint_0002`](../sprint_0002_sync_spike_and_design_kernel/) · [`sprint_0004`](../sprint_0004_offline_vault_and_session/) |
| **Blocks** | Every stage-screen sprint |
| **Specs** | [`01_dashboard.md`](../../Screens/01_dashboard/01_dashboard.md) · SRS §2.2, FR-1.3 · Epic 16 |
| **Roadmap** | [`../README.md`](../README.md) |

---

## 1. Sprint Objective

Prove the **real** sync engine on one entity end-to-end, stand up the **15-stage state machine**, and ship the **dashboard** as the application's entry screen. In parallel, start the pure deterministic loss-engine package under TDD.

After this sprint, every subsequent stage screen is a repeatable pattern: local form → validate → persist → queue → advance stage.

---

## 2. Features & Tasks

| # | Feature / module | Task | Dependency | Priority | Expected outcome |
| :-- | :-- | :-- | :-- | :-- | :-- |
| 1 | Sync engine v1 | Implement `sync-protocol.md` for `claims` and `audit_log`: outbound queue, push/pull, **field-level timestamp merge**, conflict → surveyor-confirmation modal, deferral of media references, retry with exponential backoff. | sprint_0002 ADR; sprint_0004 | Critical | AC 16.1.2, AC 16.1.3 |
| 2 | State machine | `current_stage` on `claims`; a stage-advance API plus a client-side guard; illegal transitions rejected server-side. | sprint_0001 | Critical | CR-W1; every screen spec §7 |
| 3 | Claim reference | Server-assigned `SS-YYYY-XXXXX`; offline-created claims get `TEMP-SS-XXXX` and reconcile to the permanent reference on sync without losing local references. | Task 1 | Critical | FR-1.3; AC 1.1.1; `01_dashboard.md` §6 |
| 4 | Dashboard | Local claim list, stage filter pills, FAB to start a new survey, offline banner with pending-sync count, sync status widget, canonical 5-tab bottom navigation (*Dashboard · Claims · Field Studio · Reports · Profile*). | designs; `packages/ui` | Critical | `01_dashboard.md` §1–4, §6–7 |
| 5 | Claim card | Claim #, insured name, risk city, stage badge ("Stage 6 of 15"), sync status dot; tapping opens the claim's active stage. | Task 4 | Critical | `01_dashboard.md` §2.1 |
| 6 | Loss engine kickoff | Start `packages/loss-engine` as a **pure TypeScript package with no I/O**: implement the §11.1 deduction sequence and validations; encode the `12_*.md` §4 worked example as a test fixture. TDD from the first commit. | SRS FR-11.2 | Critical | The worked example yields **₹4,97,500**. |
| 7 | Clarification | Answer **Q1** — the rounding policy. Round per line item, or only at section and grand totals? Section F must reconcile to the rupee. | Task 6 | Critical | Documented decision encoded in the engine. |

---

## 3. Acceptance Criteria

- [ ] A claim created **offline** appears server-side with a permanent `SS-YYYY-XXXXX` reference after reconnection, and the local `TEMP-SS-XXXX` reference resolves without data loss.
- [ ] A concurrent edit to the same claim from another session raises the surveyor-confirmation dialog rather than silently overwriting (**not** last-write-wins — `CLAUDE.md` §14.8).
- [ ] Three sync scenarios pass: offline-create; offline-edit followed by a conflicting remote edit; delete while offline.
- [ ] **AC 16.1.1** — the offline banner shows "Working Offline" with an accurate pending-edit count.
- [ ] **AC 16.1.2** — reconnection triggers automatic sync with background media upload deferred correctly.
- [ ] The dashboard filters by stage correctly and the FAB opens Stage 1 intake.
- [ ] Illegal stage transitions are rejected by the backend, not only hidden in the UI.
- [ ] `packages/loss-engine` is green, including the worked-example fixture, and has zero I/O dependencies.
- [ ] Q1 is answered and the rounding policy is documented in the engine's README.

---

## 4. Dependencies

- sprint_0002: the sync ADR and `sync-protocol.md`; design tokens.
- sprint_0004: the encrypted local database and offline session.
- sprint_0001: schema, contract, and the `claims` OpenAPI paths.

---

## 5. Risks & Open Questions

| Item | Detail |
| :-- | :-- |
| **R1** | Merge correctness is subtle and the failure mode is silent data loss in the field. Invest in property-based tests over concurrent field edits, not only example tests. If sprint_0002 concluded "custom queue", this sprint is materially larger — re-plan rather than compress. |
| **R3 / Q1** | The rounding policy is unspecified in the SRS and the screen spec. Whatever is chosen must make Section F reconcile to the rupee (Stage 15 gate 1 depends on it). Decide once, here. |
| Dashboard design | The Screen 01 SVG referenced by an old commit is not present in the repository. The design workstream must deliver it, or the screen is built to written spec with rework risk (**R6**). |
| Bottom-nav labels | The design system §6.1 and `01_dashboard.md` §2.1 differed historically; the canonical 5-tab set is *Dashboard · Claims · Field Studio · Reports · Profile*. |

---

## 6. Definition of Done

Global DoD (see [`../README.md`](../README.md) §6) plus:

- Sync is **Tested** against all three scenarios above, with the test output quoted in the completion report.
- The loss-engine package has no dependency on React Native, the network, or the database.
- Audit-log entries are written for every stage advance.
