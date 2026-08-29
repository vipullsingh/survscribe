# Sprint 0011 — Loss Quantification (Stage 11)

| | |
| :-- | :-- |
| **Roadmap ref** | S3.2 |
| **Stage** | 3 — Supporting MVP Workflow |
| **Status** | Not started |
| **Risk** | **Highest-consequence sprint in the plan** |
| **Depends on** | [`sprint_0010`](../sprint_0010_followup_and_document_audit/) · [`sprint_0005`](../sprint_0005_sync_engine_and_dashboard/) (loss-engine package) |
| **Blocks** | sprint_0012, sprint_0013 |
| **Specs** | [`12_loss_assessment_quantification.md`](../../Screens/12_loss_assessment_quantification/12_loss_assessment_quantification.md) · SRS FR-11.1–11.3 · [ADR-0001 D26](../../decisions/ADR-0001-foundational-stack-and-mvp-scope.md) |
| **Roadmap** | [`../README.md`](../README.md) |

---

## 1. Sprint Objective

Ship the **deterministic financial core**: the head-wise loss quantification matrix that produces the Net Recommended figure. These numbers carry professional and legal weight for a licensed surveyor, so correctness — not velocity — is the objective.

The engine is pure arithmetic. AI never generates, estimates, or alters a number (`CLAUDE.md` §14.2, §14.5).

---

## 2. Features & Tasks

| # | Feature / module | Task | Dependency | Priority | Expected outcome |
| :-- | :-- | :-- | :-- | :-- | :-- |
| 1 | Engine integration | Wire `packages/loss-engine` (started in sprint_0005) into the app: per-line computation, head-wise subtotals, and the grand summary. | sprint_0005 | Critical | FR-11.1, FR-11.2 |
| 2 | Deduction sequence | Enforce the strict order: **Gross Assessed → less Depreciation → less Betterment → less Underinsurance → less Salvage → less Policy Excess = Net Recommended.** | Task 1 | Critical | D26; AC 11.1.4 |
| 3 | Underinsurance | VAR input; sum insured pulled from the Stage 2 policy schedule; the Average Clause applied to the **Net-of-Depreciation** base: when `VAR > SI`, `Deduction = NetOfDepreciation × (1 − SI/VAR)`, otherwise `0`. Factor badge showing adequacy or the triggered percentage. | sprint_0006 | Critical | AC 11.1.3; D26 |
| 4 | Head-wise matrix | Head selector pills (Building/Civil, Plant & Machinery, Furniture/Fixtures/Fittings, Stocks, Other Insured Property, Summary); expandable item cards; steppers for depreciation %, betterment, and salvage; a sticky bar with the live Net Recommended and total deductions. | designs; `packages/ui` | Critical | `12_*.md` §2–3; AC 11.1.1 |
| 5 | Depreciation entry | Manual depreciation percentage entry with remarks, validated 0.0–90.0%. | Task 1 | Critical | AC 11.1.2 (manual path) |
| 6 | Field validations | `gross_assessed ≤ claimed_amount`; `depreciation_pct` between 0.0 and 90.0; all amounts ≥ 0. | Task 4 | Critical | `12_*.md` §5 |
| 7 | Mandatory remarks + block | `justification_remarks` required for every rate reduction, depreciation, betterment, salvage, or disallowance. **Report finalization is blocked while any deduction line has an empty remark.** | Task 4 | Critical | FR-11.3; AC 11.1.5; §14.6 |
| 8 | Financial presentation | JetBrains Mono, right-aligned, tabular figures, Indian lakh/crore grouping, ₹ prefix; the ledger styling from the design system (header `#F1F5F9`, alternating `#F8FAFC` rows, subtotal top border `2px #0F172A`). | `packages/ui` | High | Design System §12.4 |
| 9 | Domain sign-off | Obtain project-owner and domain-expert sign-off on the worked numeric example, closing `CLAUDE.md` §4 item 7 / §16 Q8. | Task 1 | High | Recorded approval. |

---

## 3. Acceptance Criteria

- [ ] **AC 11.1.1** — calculation rows are grouped by asset head.
- [ ] **AC 11.1.2** — depreciation percentages are enterable with mandatory remarks and are validated.
- [ ] **AC 11.1.3** — the Average Clause applies to the Net-of-Depreciation base exactly as specified.
- [ ] **AC 11.1.4** — the deduction sequence is enforced and cannot be reordered by input order.
- [ ] **AC 11.1.5** — finalization is blocked while any deduction line has an empty remark, with a message naming the offending line.
- [ ] The documented worked example reproduces exactly: Gross ₹10,00,000 → Depreciation 20% ₹2,00,000 → Betterment ₹50,000 → Net of Depreciation ₹7,50,000 → Underinsurance (SI ₹60,00,000 / VAR ₹80,00,000) ₹1,87,500 → After Underinsurance ₹5,62,500 → Salvage ₹40,000 → Excess ₹25,000 → **Net Recommended ₹4,97,500**.
- [ ] Head subtotals and the grand total reconcile **to the rupee** under the agreed rounding policy (Q1).
- [ ] The entire grid recalculates locally with **no server round-trip**, offline.
- [ ] Every change to a loss-assessment figure writes an immutable audit-log entry recording user, timestamp, field, old value, and new value.

---

## 4. Dependencies

- sprint_0005: the `packages/loss-engine` package, green with its fixture.
- sprint_0006: Stage 2 sums insured and the policy excess schedule.
- sprint_0010: audited line items feeding assessed amounts.

---

## 5. Risks & Open Questions

| Item | Detail |
| :-- | :-- |
| **R3** | Incorrect figures here are professionally and legally consequential for the surveyor. Mitigation: the engine is a pure package under TDD, the worked example is a locked fixture, and domain-expert sign-off is a task in this sprint — not an afterthought. |
| **Q1** | The rounding policy (per line item versus at totals only) should already be answered in sprint_0005. If it is not, this sprint cannot honestly claim rupee reconciliation. Stage 15 gate 1 depends on it. |
| AI-5 deferred | Depreciation-scale suggestions are Low priority and blocked by **Q6** (no authoritative scale data source exists in the project). Verify that pure manual percentage entry covers every test case before accepting the deferral. |
| **Q10** | Whether VAR has validation bounds is unspecified. |
| Salvage ordering | Salvage values arrive from Stage 12 (sprint_0012). Model the linkage now so the later feed does not require rework. |

---

## 6. Definition of Done

Global DoD (see [`../README.md`](../README.md) §6) plus:

- The worked example is a **committed regression fixture**, not a manual check.
- Rupee reconciliation across heads is **Tested**, with output quoted in the completion report.
- Domain-expert sign-off on the worked example is recorded in writing before the sprint is closed.
- The engine remains free of I/O, network, and framework dependencies.
