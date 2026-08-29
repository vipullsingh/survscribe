# Sprint 0010 — Follow-up & Document Audit (Stages 9–10)

| | |
| :-- | :-- |
| **Roadmap ref** | S3.1 |
| **Stage** | 3 — Supporting MVP Workflow |
| **Status** | Not started |
| **Depends on** | [`sprint_0009`](../sprint_0009_ownership_requisition_and_psr/) (M1) |
| **Blocks** | sprint_0011 |
| **Specs** | [`10_followup_investigation.md`](../../Screens/10_followup_investigation/10_followup_investigation.md) · [`11_document_verification_audit.md`](../../Screens/11_document_verification_audit/11_document_verification_audit.md) |
| **Roadmap** | [`../README.md`](../README.md) |

---

## 1. Sprint Objective

Record follow-up visits and run the **deterministic forensic audit** over claim documents. The audit findings feed FSR Section H and the Stage 15 contradiction gate, so this sprint is a prerequisite for a defensible report — not an optional extra.

The forensic checks here are **rules, not an LLM**: SRS §4.1 specifies AI-3 as "deterministic string matching and numeric variance checks. No guesswork."

---

## 2. Features & Tasks

| # | Feature / module | Task | Dependency | Priority | Expected outcome |
| :-- | :-- | :-- | :-- | :-- | :-- |
| 1 | Follow-up visits | Log subsequent visits with `visit_number` auto-incrementing from 2; visit date; purpose enum (dismantling / internal inspection, post-repair verification, salvage lifting); persons attended; detailed findings. | sprint_0009 | Medium | FR-9.1; AC 9.1.1 |
| 2 | Progress photos | Attach follow-up photos of repaired or dismantled parts, reusing the sprint_0008 Photo Studio and its watermarking. | Task 1 | Medium | AC 9.1.2 |
| 3 | Stock reconciliation | Record physical count verification notes against claimed stock losses. | Task 1 | Medium | AC 9.1.3 |
| 4 | Document locker | Storage for claim bills, contractor repair estimates, OEM quotations, purchase invoices, and salvage offers, with **manual** line-item entry (item name, quantity, unit rate, GST/taxes, total). | sprint_0009 | High | FR-10.1 |
| 5 | Duplicate detection | Flag `DUPLICATE_CLAIM_ITEM` when an item description or invoice number appears twice across claim bills. | Task 4 | High | AC 10.1.3; §11.2 |
| 6 | Rate variance | Flag `RATE_INFLATION_DETECTED` when a claimed rate exceeds the original purchase-invoice rate by more than **20%**. | Task 4 | High | AC 10.1.4; §11.2 |
| 7 | Additional flags | Flag unlisted items (not present in the Stage 6 damage register), obsolete items, and betterment components. | Task 4 | High | FR-10.2 |
| 8 | Mandatory remarks | `audit_deduction_reason` is mandatory whenever `audit_status != Verified`; saving is blocked without it. | Tasks 5–7 | High | §11.2 |
| 9 | Audit findings UI | Render discrepancies as structured audit boxes (`#FFFBEB` background, `1px #FDE68A` border, `#92400E` text) with a resolution action link — never as a chatbot or a "magic" panel. | `packages/ui` | High | Design System §5 / §12.5 |

---

## 3. Acceptance Criteria

- [ ] **AC 9.1.1** — multiple visits are recordable with `visit_number` correctly auto-incrementing from 2.
- [ ] **AC 9.1.2** — follow-up photos attach and carry the same watermarking as Stage 6.
- [ ] **AC 9.1.3** — stock reconciliation notes persist.
- [ ] **AC 10.1.3** — a duplicated item description or invoice number across bills raises `DUPLICATE_CLAIM_ITEM`.
- [ ] **AC 10.1.4** — a claimed rate more than 20% above the invoice rate raises `RATE_INFLATION_DETECTED`.
- [ ] An item flagged as anything other than Verified cannot be saved without a deduction reason.
- [ ] All forensic checks are pure deterministic functions, unit-tested, with **no network dependency** — they run identically offline.
- [ ] Findings render as structured audit boxes and pass the design-system anti-pattern checklist.

---

## 4. Dependencies

- sprint_0009: ownership invoices, which supply the original-rate baseline for the variance check.
- sprint_0008: the Stage 6 damage register, which supplies the "unlisted item" baseline.

---

## 5. Risks & Open Questions

| Item | Detail |
| :-- | :-- |
| OCR deferred | **AC 10.1.1 / 10.1.2** (OCR line-item extraction and side-by-side visual verification) are Low priority and deferred; manual line-item entry is the MVP path. Confirm stakeholders accept manual entry — for a large claim bill this is meaningful surveyor effort, and it is the second most visible deferral in the plan. |
| Matching strategy | Duplicate detection on free-text descriptions needs a documented normalisation rule (case, whitespace, punctuation) so results are reproducible and explainable in a report. |
| Data model readiness | The extracted line-item structure must already match what an OCR pipeline would later populate, so adding AI-2 post-MVP does not require a schema change. |

---

## 6. Definition of Done

Global DoD (see [`../README.md`](../README.md) §6) plus:

- Every forensic rule has unit tests covering both the trigger and the near-miss boundary (for example exactly 20% versus 20.01%).
- Rules are demonstrated running with the device offline.
- Flags and their mandatory remarks write audit-log entries.
