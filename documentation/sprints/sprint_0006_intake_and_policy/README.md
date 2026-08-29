# Sprint 0006 — Intake & Policy (Stages 1–2)

| | |
| :-- | :-- |
| **Roadmap ref** | S2.1 |
| **Stage** | 2 — Primary MVP Workflow |
| **Status** | Not started |
| **Depends on** | [`sprint_0005`](../sprint_0005_sync_engine_and_dashboard/) |
| **Blocks** | sprint_0007 onward |
| **Specs** | [`02_appointment_claim_intake.md`](../../Screens/02_appointment_claim_intake/02_appointment_claim_intake.md) · [`03_policy_coverage_review.md`](../../Screens/03_policy_coverage_review/03_policy_coverage_review.md) |
| **Roadmap** | [`../README.md`](../README.md) |

---

## 1. Sprint Objective

A surveyor can create a claim from an insurer appointment and record the complete policy schedule — **offline** — establishing the baseline against which admissibility and every later deduction is evaluated.

This sprint also establishes the repeatable stage-screen pattern reused by all remaining workflow sprints.

---

## 2. Features & Tasks

| # | Feature / module | Task | Dependency | Priority | Expected outcome |
| :-- | :-- | :-- | :-- | :-- | :-- |
| 1 | Stage 1 intake | Manual appointment form covering every FR-1.2 attribute: `appointment_id`, `insurer_name`, `operating_office_division`, `insurer_claim_ref_no`, `appointment_date`, `policy_number`, `insured_name`, `insured_phone`, `insured_email`, `representative_name_designation`, `policy_risk_address`, `date_of_loss`, `time_of_loss`, `reported_nature_of_loss`, `preliminary_loss_estimate`, `insurer_specific_instructions`. | sprint_0005 | Critical | FR-1.1, FR-1.2 |
| 2 | Intake validation | `appointment_date` not in the future; `date_of_loss ≤ appointment_date`; policy number ≥ 6 alphanumeric characters; insured phone 10 digits (India +91). | Task 1 | Critical | §11.6 |
| 3 | Duplicate warning | Warn (do not block) when a matching Policy Number + Date of Loss already exists. | Task 1 | High | `02_*.md` §5 |
| 4 | Special instructions | Capture insurer mandates and surface them prominently in the claim summary banner. | Task 1 | High | AC 1.1.3 |
| 5 | Offline creation | Creating a claim with no connectivity persists locally with a `TEMP-SS-XXXX` reference and is flagged for sync. | sprint_0005 | Critical | AC 1.1.4 |
| 6 | Stage 2 policy | Policy type (SFSP, IAR, Burglary, Machinery Breakdown, Electronic Equipment, Marine Cargo); `inception_date`/`expiry_date`; section-wise sums insured (Building, P&M, Furniture/Fixtures, Raw Materials, WIP, Finished Goods, Stock in Open); perils covered; special clauses; warranties (`warranties_json`); policy excess / deductible schedule. | Task 1 | Critical | FR-2.1; AC 2.1.1, AC 2.1.2 |
| 7 | Policy validation | Date of loss must fall within the inception–expiry period; `expiry_date ≥ inception_date`; at least one head with a sum insured greater than zero. | Task 6 | Critical | §11.5 |
| 8 | Claim intimation | Record the insured's formal claim intimation letter and initial estimate. | Task 6 | High | FR-2.2; AC 2.1.4 |
| 9 | Claim summary header | Sticky header (claim reference, insured name, sync/offline badge) built once in `packages/ui` and reused across all stage screens. | `packages/ui` | High | Design System §12.4 |

---

## 3. Acceptance Criteria

- [ ] **AC 1.1.1** — entering the required appointment fields saves the record and generates `SS-YYYY-XXXXX` (or `TEMP-SS-XXXX` offline).
- [ ] **AC 1.1.3** — insurer-specific instructions are captured and highlighted in the claim summary banner.
- [ ] **AC 1.1.4** — offline creation persists locally and is queued for sync.
- [ ] **AC 2.1.1** — section-wise sums insured are enterable per head.
- [ ] **AC 2.1.2** — policy excess terms are recordable in their documented form (for example "5% of claim amount subject to minimum ₹25,000 for SFSP").
- [ ] **AC 2.1.4** — the initial estimated claim amount is recorded.
- [ ] Every §11.5 and §11.6 validation is enforced and shows a specific, actionable message.
- [ ] Both screens work end-to-end in airplane mode and sync correctly on reconnection.
- [ ] "Save & Proceed" advances the state machine to the next stage.

---

## 4. Dependencies

- sprint_0005: sync engine, state machine, claim reference generation, dashboard entry point.
- Design workstream: `02` and `03` visuals, ideally delivered during sprint_0005.

---

## 5. Risks & Open Questions

| Item | Detail |
| :-- | :-- |
| OCR deferred | **AC 1.1.2** (appointment-letter OCR pre-fill) is explicitly deferred to post-MVP. Confirm stakeholders accept manual-only intake for the MVP — this is the most visible deferral in Stage 2 of the roadmap. |
| Warranties shape | `warranties_json` payload shape comes from the sprint_0001 physical schema. If it was left loosely specified there, it will bite here. |
| Policy type breadth | Six policy types each carry different section structures. Keep the MVP to the documented section list rather than modelling per-type variants. |

---

## 6. Definition of Done

Global DoD (see [`../README.md`](../README.md) §6) plus:

- Every field in the screen spec §4 table is implemented with its stated type and validation, or its absence is documented.
- Both screens pass the design-system anti-pattern checklist.
- The stage-advance action writes an audit-log entry.
