# Sprint 0009 — Ownership, Requisition & PSR (Stages 7–8) → Milestone M1

| | |
| :-- | :-- |
| **Roadmap ref** | S2.4 |
| **Stage** | 2 — Primary MVP Workflow |
| **Status** | Not started |
| **Milestone** | **M1 — first exportable report** |
| **Depends on** | [`sprint_0008`](../sprint_0008_damage_studio_and_photos/) · [`sprint_0002`](../sprint_0002_sync_spike_and_design_kernel/) (`.docx` contract) |
| **Blocks** | sprint_0010 onward |
| **Specs** | [`08_ownership_document_locker.md`](../../Screens/08_ownership_document_locker/08_ownership_document_locker.md) · [`09_preliminary_survey_report_psr.md`](../../Screens/09_preliminary_survey_report_psr/09_preliminary_survey_report_psr.md) |
| **Roadmap** | [`../README.md`](../README.md) |

---

## 1. Sprint Objective

Close the first half of the workflow: verify ownership and insurable interest, generate the peril-based document requisition notice, and produce the **first real report artifact — a PSR exported as an editable `.docx`**.

**Milestone M1:** a surveyor, fully offline, completes Stage 1 → Stage 8 and exports a PSR that opens correctly in Microsoft Word.

---

## 2. Features & Tasks

| # | Feature / module | Task | Dependency | Priority | Expected outcome |
| :-- | :-- | :-- | :-- | :-- | :-- |
| 1 | Stage 7 ownership | Record and link ownership documents: purchase invoices, Bill of Entry, delivery challans, Fixed Asset Register extracts, stock ledgers, production logs, bank stock statements, GST returns (GSTR-1, GSTR-3B), audited balance sheet extracts, hypothecation / leasehold / mortgage details. | sprint_0008 | High | FR-7.1; AC 7.1.1 |
| 2 | Insurable interest | Status enum with **four** states: `Established` / `Under Verification` / `Incomplete Documentation` / `Disputed`, with supporting remarks. Resolves **Q4** in favour of D34. | Task 1 | High | FR-7.2; D34; AC 7.1.2 (reconciled) |
| 3 | Document linkage | Attach specific invoices directly to their corresponding damage items from Stage 6. | Task 1; sprint_0008 | High | AC 7.1.3 |
| 4 | Requisition generator | Peril-preset dynamic checklist (Fire, Flood, Burglary, Machinery Breakdown) producing the required-document list, plus custom requirements, a due date, and the dispatch channel. Generates the requisition letter. | Task 1 | High | FR-8.1; AC 8.1.1 |
| 5 | PSR rendering | **Renamed from "client `.docx` engine" — ADR-0009 (2026-08-30) removed the client-side TypeScript engine from MVP scope entirely.** The PSR must render through the same server-side Go engine as the FSR (ADR-0009 D53), against `docx-template-contract.md`. **Sequencing gap, flagged not resolved:** the server engine's own build is sprint_0013 task 7, which comes *after* this sprint's M1 milestone. Either a minimal server-side renderer needs to land here ahead of sprint_0013's full engine, or M1's "exports a PSR .docx" criterion needs to move to whichever sprint actually has the engine. See roadmap `README.md` §11 R2. | sprint_0002 contract; **also, unmet:** an MVP-scope `.docx` engine | Critical | ADR-0009 D53 |
| 6 | PSR builder | Compile basic claim info, date of survey, nature and cause of loss, preliminary damage observations, the **surveyor-entered** preliminary loss reserve, and the pending-document list. Export to editable `.docx`. | Task 5 | Critical | FR-8.2; AC 8.1.2, AC 8.1.3 |
| 7 | Approval gate component | Build the reusable Human Approval Gate component here (the PSR export path), sized for the full 4-point gate used at Stage 14. Acceptance is timestamped into the immutable audit log. | audit log | Critical | FR-14.4; §14.4 |
| 8 | Export disclaimers | Every exported `.docx` embeds the standard regulatory disclaimer and "Without Prejudice" language. | Task 5 | Critical | FR-14.3; §14.14 |

---

## 3. Acceptance Criteria

- [ ] **AC 7.1.1** — the structured ownership checklist is completable.
- [ ] **AC 7.1.2** — insurable-interest status uses the 4-state enum with remarks.
- [ ] **AC 7.1.3** — invoices link to specific damage items and the linkage survives sync.
- [ ] **AC 8.1.1** — selecting a peril auto-generates the tailored required-document list.
- [ ] **AC 8.1.2** — the PSR compiles from real claim data with no AI-invented values; the loss reserve is surveyor-entered only.
- [ ] **AC 8.1.3** — the PSR exports as an editable `.docx` that opens in Microsoft Word with correct formatting.
- [ ] The Human Approval Gate blocks the export until accepted, and the acceptance is written to the immutable audit log with a timestamp.
- [ ] The exported document carries the mandatory disclaimers.
- [ ] **M1:** an end-to-end offline run of Stages 1 → 8 produces a valid PSR, and all data syncs cleanly on reconnection.

---

## 4. Dependencies

- sprint_0008: damage items and photos referenced by the PSR.
- sprint_0002: `docx-template-contract.md` — without it the client engine will drift from the server engine built in sprint_0013.

---

## 5. Risks & Open Questions

| Item | Detail |
| :-- | :-- |
| **R2** | This is where dual-engine drift begins. The client engine must be written **against the contract**, not against what looks right in Word, because sprint_0013 builds the authoritative Go engine to the same contract and they must match. |
| TypeScript `.docx` fidelity | Library choice matters for table borders, photo plates, and headers/footers. Evaluate against the contract's hardest requirement (the Section F table) before committing. |
| **Q10** | Whether the preliminary loss reserve has validation bounds, or is free surveyor entry, is unspecified. |
| **Q4** | The 3-state versus 4-state insurable-interest conflict is resolved here in favour of D34; `User Stories.md` AC 7.1.2 should be updated to match. |

---

## 6. Definition of Done

Global DoD (see [`../README.md`](../README.md) §6) plus:

- The exported `.docx` is **Verified** by opening it in Microsoft Word (not only a viewer) and confirming tables, headers, and disclaimers render.
- The gate acceptance is proven present in the audit log.
- M1 is demonstrated as a single continuous offline run, not as a set of individually passing screens.
