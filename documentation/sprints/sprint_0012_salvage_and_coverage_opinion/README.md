# Sprint 0012 — Salvage & Coverage Opinion (Stages 12–13)

| | |
| :-- | :-- |
| **Roadmap ref** | S3.3 |
| **Stage** | 3 — Supporting MVP Workflow |
| **Status** | Not started |
| **Depends on** | [`sprint_0011`](../sprint_0011_loss_quantification/) |
| **Blocks** | sprint_0013 (M2) |
| **Specs** | [`13_salvage_disposal_manager.md`](../../Screens/13_salvage_disposal_manager/13_salvage_disposal_manager.md) · [`14_coverage_liability_opinion.md`](../../Screens/14_coverage_liability_opinion/14_coverage_liability_opinion.md) |
| **Roadmap** | [`../README.md`](../README.md) |

---

## 1. Sprint Objective

Complete the loss picture with salvage realization, and record the surveyor's **decision-support** coverage opinion. Stage 13 is where the regulatory guardrails are most load-bearing: the platform must never make an autonomous coverage determination (`CLAUDE.md` §14.1, §14.2).

---

## 2. Features & Tasks

| # | Feature / module | Task | Dependency | Priority | Expected outcome |
| :-- | :-- | :-- | :-- | :-- | :-- |
| 1 | Salvage inventory | Record description, estimated weight/quantity, condition, and storage location for salvageable material. | sprint_0011 | Critical | FR-12.1; AC 12.1.1 |
| 2 | Disposal modes | Three modes: **Mode A — Retained by Insured** (agreed value plus the insured's recorded consent), **Mode B — Sold to Scrap Buyer** (buyer details, quote, delivery confirmation, GST sale invoice, payment receipt, realized value), **Mode C — Tender floated by Insurer** (tender bids, highest bidder, sale proceeds invoice, payment proof). | Task 1 | Critical | FR-12.2; D29; AC 12.1.2, AC 12.1.3 |
| 3 | Mode validation | Modes B and C require buyer/tender details and payment proof before saving. | Task 2 | Critical | §11.8 |
| 4 | Assessment linkage | The net realized salvage total feeds `assessment_line_items.salvage_amount` and FSR Section F; changing it re-flows the Stage 11 totals. | sprint_0011 | Critical | FR-12.3; AC 12.1.4 |
| 5 | Peril evaluation | Record whether the proximate cause falls within the policy's insured perils, based on physical evidence (for example short circuit versus overheating; accidental fire versus arson), with justification. | sprint_0011 | Critical | FR-13.1; AC 13.1.1 |
| 6 | Warranty compliance | Checklist verifying compliance with key warranties (fire-fighting appliances, housekeeping, security, maintenance) and identification of any breach or material fact requiring insurer consideration. | Task 5 | Critical | FR-13.1; AC 13.1.2 |
| 7 | Recommendation enum | Surveyor recommendation: `Admissible as Assessed` / `Subject to Insurer Liability Determination` / `Non-Admissible` / `Repudiation Recommended`. | Task 5 | Critical | FR-13.2; AC 13.1.3 |
| 8 | Mandatory notices | Every coverage remark stored or displayed bears: *"Decision-support analysis for surveyor review. Final liability determination remains with the insurer."* The standard "Without Prejudice" declaration is auto-included in the report. | Tasks 5–7 | Critical | AC 13.1.4, AC 13.1.5; §14.14 |

---

## 3. Acceptance Criteria

- [ ] **AC 12.1.1** — salvage items are recordable with quantity, condition, and estimated value.
- [ ] **AC 12.1.2** — all three disposal modes (A, B, C) are selectable.
- [ ] **AC 12.1.3** — buyer and tender records capture name, contact, quote amount, sale invoice number, and payment confirmation; Modes B and C block saving without them.
- [ ] **AC 12.1.4** — the realized salvage total automatically feeds the Section F assessment, and editing it updates the Stage 11 Net Recommended figure.
- [ ] **AC 13.1.1** — peril applicability is recorded against physical evidence.
- [ ] **AC 13.1.2** — the warranty-compliance checklist is completable, with breaches flagged.
- [ ] **AC 13.1.3** — the four-value recommendation enum is enforced (no free text substitute).
- [ ] **AC 13.1.4** — the decision-support notice is present on the screen and on every stored coverage remark.
- [ ] **AC 13.1.5** — the "Without Prejudice" declaration is automatically included.
- [ ] No screen, label, or output implies an autonomous approval or repudiation by the platform.

---

## 4. Dependencies

- sprint_0011: the assessment line items that salvage deducts from, and the loss engine that must re-compute on change.
- sprint_0006: policy warranties and exclusions from the Stage 2 schedule.

---

## 5. Risks & Open Questions

| Item | Detail |
| :-- | :-- |
| Re-flow correctness | Salvage edits must propagate back through the Stage 11 sequence in the correct position (after underinsurance, before excess). A naive recompute can silently produce a wrong Net Recommended figure. |
| Regulatory language | The disclaimer text is verbatim from the SRS and must not be paraphrased, shortened, or made dismissible. |
| Enum discipline | The recommendation values are an industry contract. Do not add a fifth value or allow free-text override. |
| Mode C detail | Tender-mode fields (bids, highest bidder) have less specification depth than Modes A and B; verify the schema covers what the FSR Section F needs. |

---

## 6. Definition of Done

Global DoD (see [`../README.md`](../README.md) §6) plus:

- The salvage → Stage 11 → Net Recommended re-flow is **Tested** with a numeric fixture, not visually inspected.
- Every mandatory notice is verified present in both the UI and the persisted record.
- Changes to salvage figures write immutable audit-log entries.
