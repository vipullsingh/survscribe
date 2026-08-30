# `.docx` Template Contract — PSR & FSR

> **Document type:** Shared rendering contract for the PSR and FSR `.docx` generators.
> **Version:** 1.0.0 · **Created:** 2026-08-30 (`sprint_0002` task 5). **Status:** Reviewed — awaiting the same project-owner approval as every other `sprint_0001`/`sprint_0002` artifact (`CLAUDE.md` §16 Q12). Both engine owners (server, and — once built — client) must sign off before either is implemented against it.
> **Governing decisions:** `Requirement.MD` FR-8.2, FR-14.1–FR-14.4; `15_final_survey_report_generator.md`; ADR-0009 (MVP builds the server engine only; this contract exists precisely so a client engine can be added later without drift — `CLAUDE.md` §14 constraint 16).
> **Implements:** `physical-schema.md` §28.1 (`preliminary_survey_reports`), §33 (`final_survey_reports`).
> **Consumed by:** `sprint_0009` (PSR engine), `sprint_0013` (FSR engine, server-side).

---

## 1. Purpose

`CLAUDE.md` §14 constraint 16 requires the offline client engine and the authoritative server engine to "produce equivalent documents from the same shared template contract" and to never be allowed to drift. ADR-0009 defers the client engine, but the contract is written to the full two-engine spec now — the risk of writing it late is that the server engine bakes in Go-specific assumptions (a particular templating library's syntax, a particular page-break heuristic) that a future TypeScript engine cannot reproduce byte-for-byte. This document is the thing both engines are implementations *of*, not a description of one implementation.

Everything below applies to both the **PSR** (`preliminary_survey_reports`, Stage 8, FR-8.2) and the **FSR** (`final_survey_reports`, Stage 14, FR-14.1–14.3) — the FSR is the nine-section report; the PSR is a strict subset (§3 below) sharing every layout, disclaimer, and gate rule.

---

## 2. The section-block envelope

Every section of every report — PSR or FSR — is represented server- and client-side as the same JSON shape, first specified in `physical-schema.md` §33 and restated here as the authoritative contract:

```jsonc
{
  "title": "Cause and Circumstances of Loss",
  "blocks": [
    {
      "type": "paragraph",
      "text": "During our physical inspection on site on 03 March 2026, ...",
      "source": "AI_DRAFT",              // AI_DRAFT | SURVEYOR | SYSTEM
      "accepted_by_user_id": "…uuid…",   // required before export when source = AI_DRAFT
      "accepted_at": "2026-04-02T11:20:31+05:30",
      "edited": true,
      "placeholders": []                 // e.g. ["[SURVEYOR TO VERIFY]"]
    },
    { "type": "table", "table_id": "section_f_headwise", "rows": [ /* §5 */ ] },
    { "type": "photo_plate", "layout": "2_PER_PAGE", "media_ids": ["…", "…"] }
  ]
}
```

A **renderer** — either engine — walks this structure and never queries the database directly for section content. This is what makes format parity checkable: two engines fed the identical section-block JSON must produce documents differing only in binary encoding, never in the words, numbers, or layout on the page.

**Block types**, closed at four for MVP: `paragraph` (rich text: bold, italic, lists — §3.3 of the FSR screen spec), `table` (a named, structured table — currently only `section_f_headwise`, §5), `photo_plate` (a page of watermarked evidence photos, §6), and `heading` (a sub-heading inside a section, for sections with internal structure like Section E's document list).

**`source` and `accepted_by_user_id` are not decoration — they are what makes the human approval gate mechanically checkable.** A section containing any block with `"source": "AI_DRAFT"` and no `accepted_by_user_id` fails FR-14.4's approval gate (§7); a block with a non-empty `placeholders` array fails Stage 15 gate 6 (Contradiction Scanner extended to placeholder-completeness, per `physical-schema.md` §34). Neither engine may render a document that still contains an unaccepted AI block or an unresolved `[SURVEYOR TO VERIFY]` placeholder — this is enforced by the same `CHECK` constraints described in `physical-schema.md` §28.1 and §33 (`psr_gate_before_export`, `fsr_gate_before_export`), so a renderer that somehow bypassed the API-level check would still be unable to persist a `docx_document_id` against an incomplete report.

---

## 3. Section identity and order — fixed, never renumbered

Per `CLAUDE.md` §14 constraint 12, this table is an industry-standard contract and its identity/order must not change:

| § | Title | Origin (stage) | AI touchpoint | In PSR? |
| :-- | :-- | :-- | :-- | :-- |
| A | Basic Claim Information | Stage 1 | Auto-compiled | Yes (subset: appointment + policy header) |
| B | Brief Description of Risk | Stage 4 | Form-filled | No |
| C | Cause & Circumstances of Loss | Stage 5 | **AI-4** | No |
| D | Physical Survey Findings | Stage 6 | **AI-4** | Yes, as "Preliminary Damage Observations" |
| E | Documents Considered | Stages 7, 10 | Auto-formatted list | No |
| F | Claim Assessment Statement | Stage 11 | High-precision table | No (PSR carries `preliminary_loss_reserve` only, a single figure, not the grid) |
| G | Policy Terms & Conditions | Stage 2 | Auto-compiled | No |
| H | Discrepancies / Observations | Stage 10 | **AI-4** | No |
| I | Surveyor's Opinion & Recommendation | Stage 13 | **AI-4** | No |
| Annexure | Photographic Evidence Plates | Stage 6 | 2/4-plate layout engine | No |

**The PSR is not a truncated FSR object** — it is a distinct entity (`preliminary_survey_reports`, `physical-schema.md` §28.1) with its own field set (`psr_date_of_survey`, `preliminary_loss_reserve`, `psr_next_steps`, `pending_documents_json`). It shares this contract's disclaimer blocks (§7), sign-off block shape (§8), and approval-gate mechanics (§2, §7) — not its section content. A PSR document has no Section F table, no AI-drafted Section C/H/I, and no nine-part structure; it is one to two pages compiled from Stage 1–8 data plus the surveyor's preliminary reserve figure.

---

## 4. Header, footer, and letterhead

Every page of every generated document (PSR and FSR alike) carries:

- **Header:** the surveyor firm's letterhead, sourced from `stores.letterhead_config_json` — firm name, logo (if configured), registration/license reference. A store with no letterhead configured renders a plain text header (`stores.firm_name`), never a blank one — a report must always be attributable to a firm.
- **Footer:** page number (`Page X of Y`), and the claim reference (`claims.claim_ref_no`, or `temp_ref_no` if the document is somehow generated before first sync — which §7's approval gate should make impossible in practice, since export requires a synced report row).
- **Section G-derived claim identity strip:** insurer name, policy number, claim number and date of loss repeated as a running header on every page from Section C onward — this is what Stage 15 gate 2 (Metadata Consistency, `physical-schema.md` §34) checks against: the same four values must match verbatim across every section and every photo caption.

`letterhead_config_json` shape:

```jsonc
{ "logo_media_id": "…uuid, nullable…",
  "display_name": "Rajesh & Associates, Licensed Surveyors",
  "registration_line": "IRDAI Surveyor License: SLA-4471",
  "address_line": "302, Commerce House, Ashram Road, Ahmedabad - 380009",
  "color_accent": "#1E3A8A" }
```

`color_accent` defaults to the design system's primary blue (`#1E3A8A`) and is the only firm-customizable colour — the disclaimer and gate-related text (§7) is never themeable, so a firm cannot visually de-emphasize a mandatory notice.

---

## 5. Section F — the loss-assessment table

The one block type with fixed internal structure, because FR-15.1 gate 1 requires it to reconcile to the rupee exactly, and a table a human must audit line-by-line cannot vary between the two engines in column order, rounding, or subtotal placement.

**Column order, fixed:**

| # | Column | Source |
| :-- | :-- | :-- |
| 1 | Sr. No. | `assessment_line_items.line_no` |
| 2 | Description | `assessment_line_items.description` |
| 3 | Claimed Amount (₹) | `.claimed_amount` |
| 4 | Gross Assessed (₹) | `.assessed_gross` |
| 5 | Depreciation % / Amount (₹) | `.depreciation_pct` / `.depreciation_amount` |
| 6 | Betterment Deduction (₹) | `.betterment_amount` |
| 7 | Net of Depreciation (₹) | `.net_of_depreciation` |
| 8 | Underinsurance Deduction (₹) | `.underinsurance_deduction` |
| 9 | Salvage Deduction (₹) | `.salvage_amount` |
| 10 | Net Assessed Amount (₹) | `.net_recommended` |
| 11 | Justification Remarks | `.justification_remarks` |

Grouped by `head_category` (Building/Civil, Plant & Machinery, FFF, Stocks, Other Insured Property — `physical-schema.md` §19), each group followed by a **head subtotal row** sourced from `assessment_heads.total_*` (stored, not recomputed at render time — §30.1 explains why), and the whole table closed by:

1. `Gross Loss Payable` — sum of all head `total_net_recommended` before salvage and excess.
2. `Salvage Deduction (Total)` — sum of `salvage_amount` across all lines.
3. `Policy Excess Deduction` — sum of `excess_deduction` across all lines.
4. **`Net Recommended Payable`** — the final figure, rendered in the `financialTotal` type scale (`packages/ui/src/tokens.ts`: 15px/700, JetBrains Mono) and visually distinguished per the design system's loss-matrix spec (`Design System.md` §12.4: subtotal row top border `2px #0F172A`).

Every rupee value in this table is rendered from its `NUMERIC(15,2)` source **as a formatted string** (Indian lakh/crore grouping, `formatInr` in `packages/ui/src/tokens.ts`) — never through a floating-point intermediate step in either engine. This is the same discipline the API contract already enforces on the wire (`openapi.yaml`: money is a decimal string, never a JSON number) applied one layer further, into the rendered document.

---

## 6. Photo Annexure — plate layout

- **Layout options:** 2 photos per page or 4 photos per page, selected per report (`PhotoPlateLayoutSelector`, screen 15 §3.4) — not a global setting, since a report with few, large, high-detail photos (a machinery close-up) may warrant 2-per-page while a report with many routine site photos may warrant 4.
- **Per-photo caption block**, mandatory on every plate: category tag (one of the six FR-6.2 categories), capture timestamp, GPS coordinates, and the free-text caption — the same four fields Stage 15 gate 4 (Photo Annexure Compliance) checks for completeness.
- **The watermark is not re-rendered by the `.docx` engine.** It was burnt into the JPEG pixels at capture time (`media_attachments.watermark_applied`, `CLAUDE.md` §14 constraint 9) — the engine places the already-watermarked image as-is. This is a deliberate simplification that also closes a risk: a `.docx` engine that re-drew the watermark as an overlay could theoretically be asked to omit it, whereas a pixel-burnt watermark cannot be selectively hidden per export.
- **Ordering:** by `damage_items.item_no`, then by `media_attachments.created_at` within an item — matching the order the Section D narrative discusses items, so a reader can cross-reference the annexure without hunting.

---

## 7. Disclaimers and the Human Approval Gate — never removable, never themeable

Per `CLAUDE.md` §14 constraint 14, none of the following may be omitted, reworded per-firm, or made conditional by any UI affordance:

1. **Without Prejudice declaration** — on Section I (FSR) and wherever a coverage remark appears (`coverage_opinions.without_prejudice_declaration`, `physical-schema.md` §32). Rendered as a distinct, bordered block, not inline prose that could be missed on a skim.
2. **Decision-support notice**, verbatim per FR-13.2: *"Decision-support analysis for surveyor review. Final liability determination remains with the insurer."* — attached to every coverage-related remark, sourced from `coverage_opinions.decision_support_notice`.
3. **Regulatory export disclaimer**, per `Requirement.MD` §347: a statement that the report was compiled under the direct supervision and assessment of the licensed surveyor — rendered once, near the sign-off block (§8).
4. **AI-content note** — wherever a Section C/D/H/I block carries `"source": "AI_DRAFT"`, the rendered page carries no visible AI attribution (the design system explicitly forbids "sparkle" AI iconography and chatbot framing, §12.5) — the accountability record lives in `accepted_by_user_id`/`accepted_at` in the underlying data and in `audit_log`, not as reader-facing text. The document reads as the surveyor's own prose, because by the time it exports, every AI-drafted sentence has been explicitly accepted by them.

**The 4-point Human Approval Gate (FR-14.4) is a precondition of calling either engine, not a rendering step.** Neither engine ever renders a document for a report row that fails `psr_gate_before_export` / `fsr_gate_before_export` (`physical-schema.md` §28.1, §33) — the API layer refuses the export call before the engine is invoked at all. This contract's job is only to render the gate's *record* into the document: the four checkbox statements, each with its `accepted_at` timestamp, as a compliance appendix on the final page.

---

## 8. Sign-off block

Present on the FSR only (the PSR has no sign-off — it is a preliminary document, FR-8.2):

```jsonc
{ "surveyor_name": "…",
  "sla_license_no": "SLA-4471",      // copied at sign-off, per D35 -- see physical-schema.md §33
  "sla_category": "Associate",
  "signature_media_id": "…uuid…",
  "signed_off_at": "2026-04-05T16:02:11+05:30",
  "declaration_text": "I/We confirm that this Final Survey Report has been prepared based on..." }
```

`sla_license_no`/`sla_category` are read from `final_survey_reports.signoff_sla_license_no`/`.signoff_sla_category` — the **copied-at-sign-off** values, never a live join to `users.sla_license_no`. This is deliberate: `physical-schema.md` §33 explains that a later profile edit must not retroactively alter what a submitted, hashed (§9) report actually says.

---

## 9. What is generated once and never re-rendered

Once `final_survey_reports.snapshot_sha256` is set (Stage 15 sign-off, FR-15.2), the `.docx` binary itself is immutable — a subsequent edit to any underlying data produces a **new report version** (`final_survey_reports.version_no`, `physical-schema.md` §33), never a silent re-render of the signed-off file. This contract governs how a version is *produced*; it says nothing about mutating one after signature, because nothing may.

---

## 10. Format-parity checklist — what "equivalent documents" means in practice

For the client engine, whenever it is built (post-MVP, ADR-0009), format parity with the server engine means:

- [ ] Identical section order and identical section titles (§3).
- [ ] Identical Section F column order, grouping, and subtotal placement (§5), with identical rupee formatting (Indian grouping, two decimals, no floating-point rounding drift between the two implementations of `formatInr`-equivalent logic).
- [ ] Identical disclaimer text, verbatim, in identical positions (§7) — this is the one section where "equivalent" means byte-identical text, not merely equivalent meaning.
- [ ] Identical photo-plate ordering and caption field order (§6).
- [ ] Both engines refuse to render against a report row that fails its approval-gate `CHECK` (§2, §7) — parity includes parity of refusal, not only parity of successful output.

Font, exact page-break points, and binary `.docx` XML structure are explicitly **not** required to be identical — only what a reader sees and can audit needs to match.
