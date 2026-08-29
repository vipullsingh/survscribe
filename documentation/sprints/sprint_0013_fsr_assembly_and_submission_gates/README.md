# Sprint 0013 — FSR Assembly, Approval Gates & Server Engine (Stages 14–15) → Milestone M2

| | |
| :-- | :-- |
| **Roadmap ref** | S3.4 |
| **Stage** | 3 — Supporting MVP Workflow |
| **Status** | Not started |
| **Milestone** | **M2 — end-to-end product complete** |
| **Depends on** | [`sprint_0012`](../sprint_0012_salvage_and_coverage_opinion/) · [`sprint_0009`](../sprint_0009_ownership_requisition_and_psr/) · [`sprint_0002`](../sprint_0002_sync_spike_and_design_kernel/) |
| **Blocks** | sprint_0014, sprint_0015 |
| **Specs** | [`15_final_survey_report_generator.md`](../../Screens/15_final_survey_report_generator/15_final_survey_report_generator.md) · [`16_internal_review_submission.md`](../../Screens/16_internal_review_submission/16_internal_review_submission.md) · SRS FR-14.x, FR-15.x |
| **Roadmap** | [`../README.md`](../README.md) |

---

## 1. Sprint Objective

Assemble the **9-section Final Survey Report**, enforce the **4-point Human Approval Gate**, build the **authoritative server-side Go `.docx` engine**, and ship the **7 pre-submission compliance gates** with the SHA-256 hash lock.

**Milestone M2:** a claim goes Stage 1 → Stage 15 end-to-end and produces a submitted, audited, hash-locked FSR. This is the largest sprint in the plan; consider splitting it if the team's capacity is tight.

---

## 2. Features & Tasks

| # | Feature / module | Task | Dependency | Priority | Expected outcome |
| :-- | :-- | :-- | :-- | :-- | :-- |
| 1 | FSR assembly | Compose Sections **A–I** from Stage 1–13 data: A Basic Info, B Risk Description, C Cause & Circumstances, D Survey Findings, E Documents Considered, F Loss Assessment Statement, G Policy Terms/Warranties/Deductibles, H Discrepancies & Observations, I Surveyor's Opinion & Final Recommendation. Section identity and ordering must not change. | sprint_0012 | Critical | FR-14.1; AC 14.2.1; §14.12 |
| 2 | Section F table | Render the head-wise Claimed versus Assessed table as a clean bordered table with exact totals. | sprint_0011 | Critical | AC 14.2.2 |
| 3 | Photo annexure | Dedicated annexure with 2 or 4 photos per page, each with watermark, caption, timestamp, and GPS coordinates. | sprint_0008 | Critical | AC 14.2.3 |
| 4 | Letterhead & sign-off | Surveyor firm header metadata and formal signature blocks. **Requires License Number + Category (D35)** — prompt the surveyor to supply them if absent, and block FSR generation until they are. | sprint_0003 | Critical | AC 14.2.4; D35 |
| 5 | Human Approval Gate | The full 4-point gate blocks `.docx` generation and download until all four boxes are checked; acceptance is timestamped and written to the immutable audit log. | sprint_0009 component | Critical | FR-14.4; AC 14.2.5; §14.4 |
| 6 | Client FSR draft | Extend the client TypeScript engine to render the full 9-section FSR draft offline. | sprint_0009 | Critical | ADR-0001 D22 |
| 7 | **Server Go engine** | Authoritative `.docx` compiler in `apps/backend` implementing the same `docx-template-contract.md`; produces the final compiled report. | sprint_0002 contract | Critical | ADR-0001 D22 |
| 8 | Parity tests | An automated suite comparing client and server output from identical input against the contract's parity rules. | Tasks 6, 7 | Critical | §14.16 |
| 9 | Performance benchmark | The server engine generates 9 sections with 50 embedded photo plates in **under 5 seconds**. | Task 7 | Critical | SRS §6.3; CR-NF5 |
| 10 | Stage 15 audit gates | Implement all **7** gates: (1) Arithmetic Check to the rupee, (2) Metadata Consistency across all sections and photo captions, (3) Deduction Remarks present, (4) Photo Annexure Compliance, (5) Document Completeness for the peril, (6) Contradiction Scanner across Sections C/D/I, (7) Human Approval & AI Gate recorded in the audit log. All must pass before submission is enabled. | Tasks 1–5 | Critical | FR-15.1; D36; AC 15.1.1–15.1.4 |
| 11 | Submission lock | Final sign-off record, report archiving, immutable **SHA-256** hash snapshot, dispatch tracking log, status → `COMPLETED_SUBMITTED`, record becomes read-only. | Task 10 | Critical | FR-15.2; AC 15.1.5 |

---

## 3. Acceptance Criteria

- [ ] **AC 14.2.1** — all nine sections are present in the documented order.
- [ ] **AC 14.2.2** — Section F renders as a bordered table whose totals match the Stage 11 figures exactly.
- [ ] **AC 14.2.3** — the photo annexure renders 2 or 4 plates per page with watermark, caption, timestamp, and GPS.
- [ ] **AC 14.2.4** — letterhead and signature blocks are populated; FSR generation is blocked when License Number or Category is missing.
- [ ] **AC 14.2.5** — no `.docx` is generated or downloaded until all four approval checkboxes are accepted, and the acceptance is in the immutable audit log with a timestamp.
- [ ] **AC 15.1.1** — the arithmetic gate catches a deliberately introduced ₹1 mismatch.
- [ ] **AC 15.1.2** — the metadata gate catches a policy number altered in one section only.
- [ ] **AC 15.1.3** — the document-completeness gate flags a missing mandatory document for the peril (for example a missing FIR on a fire claim).
- [ ] **AC 15.1.4** — the human-approval gate audit validates all four points were affirmatively accepted.
- [ ] **AC 15.1.5** — submission records the dispatch date, recipient, a SHA-256 snapshot, and archives a read-only record.
- [ ] A failing gate blocks submission **with a specific reason naming the failure**, not a generic error.
- [ ] Client and server `.docx` output pass the parity suite from identical input.
- [ ] The server engine meets the `< 5 s` / 50-plate benchmark on representative infrastructure.
- [ ] **M2:** a full Stage 1 → 15 run completes, with Stage 1–13 capture performed offline.

---

## 4. Dependencies

- sprint_0012: coverage opinion and salvage, which feed Sections F and I.
- sprint_0011: the assessment figures underpinning Section F and gate 1.
- sprint_0009: the client `.docx` engine and the approval-gate component.
- sprint_0002: `docx-template-contract.md` — the only thing keeping the two engines aligned.

---

## 5. Risks & Open Questions

| Item | Detail |
| :-- | :-- |
| **Sprint size** | This is materially larger than the others. **Recommendation:** split into 13a (FSR assembly + 4-point gate + client draft) and 13b (server Go engine + parity + Stage 15 gates + hash lock) if capacity is uncertain, rather than letting M2 slip silently. |
| **R2** | Dual-engine parity is permanent maintenance debt. The parity suite is mandatory, not optional. **Recommendation:** under timeline pressure, consider narrowing the MVP to "client draft is preview-only, server output is authoritative" — a scope decision for the project owner, not a unilateral one. |
| Benchmark | `< 5 s` for 9 sections plus 50 embedded images in Go is non-trivial. Profile early in the sprint, not during sprint_0016. |
| **Q5** | Gate 6 (Contradiction Scanner) has no enumerated rule list in the SRS. Decide whether it is a deterministic rule set (for example an item marked "Repairable" in Stage 6 quantified as "Total Loss" in Stage 11) or AI-assisted. If AI-assisted, it creates a dependency on sprint_0014 and must be surfaced now. |
| Gate 5 completeness | "All mandatory documents for the reported peril" needs the peril→document mapping from sprint_0009's requisition presets to be reused, not re-invented. |

---

## 6. Definition of Done

Global DoD (see [`../README.md`](../README.md) §6) plus:

- Each of the 7 gates has a **negative test** proving it blocks, not only a positive test proving it passes.
- The generated FSR is **Verified** by opening it in Microsoft Word and checking all nine sections, the Section F table, and the annexure.
- The performance benchmark is **Tested** with a real 50-photo claim and the timing recorded.
- Immutability of the submitted record is proven by attempting a post-submission edit.
- M2 is demonstrated as one continuous run, not as individually passing screens.
