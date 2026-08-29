# Screen Specification: 15_final_survey_report_generator

## 1. Screen Objective & Context
- **Screen Name**: Final Survey Report (FSR) Generator & Document Engine
- **Stage Mapping**: Stage 14 of 15 (Preparation of the Final Survey Report)
- **Purpose**: Centralized report compilation workstation. Assembles the complete 9-section industry-standard Final Survey Report (FSR), executes the **Primary AI Narrative Drafter** for Sections C, D, H, and I, formats the Loss Assessment table (Section F), organizes the high-resolution Photo Annexure plates with captions and GPS watermarks, and generates a fully styled, editable Microsoft Word (`.docx`) file.

---

## 2. Layout & UI Architecture

### 2.1 Primary Mobile App View (iOS & Android) - Core Mobile Experience
- **Mobile Report Studio & Exporter**:
  - Horizontal Section Drawer / Stepper to navigate through Sections A to I + Photo Annexure.
  - Section-by-section preview with inline touch-to-edit capabilities.
  - Prominent "Regenerate AI Draft" floating button for Sections C, D, H, and I with custom tone selection.
  - Mobile Photo Annexure Organizer (Drag-to-reorder photos, edit captions).
  - Sticky Bottom Action Bar: "Export Editable Word (.docx)" and "Proceed to Pre-Submission Review".
  - **Mandatory Human Approval Gate Modal**: Triggers prior to `.docx` generation or final export.

### 2.2 Responsive Desktop Web View
- **Two-Column Master Document Studio**:
  - **Left Pane (30% width)**: 9-Section Document Navigator (Sections A through I + Photo Annexure).
  - **Right Pane (70% width)**: Full-featured Rich Text & Table Editor for active section, with live AI Narrative Regeneration tools, Human Approval Gate verification widget, and Word Document Export Toolbar.

---

## 3. Detailed UI Component Hierarchy
1. **FSR Section Navigator & Progress Bar**:
   - `ReportProgressBar` (Shows completeness score across all 9 sections).
   - `SectionList`: Interactive tree showing completion status checkmarks for Sections A through I + Annexures.
2. **Section Editor Workspace (Active Section)**:
   - **For Structured Sections (A, B, E, G)**: Clean form view auto-populated from Stages 1, 2, 7, 8.
   - **For Narrative Sections (C, D, H, I)**:
     - `SectionHeader` with `AIRegenerateDraftButton` (Triggers AI drafting with custom tone controls: *Standard Surveyor / Technical / Concise*).
     - `RichDocumentEditor` (Bold, italic, lists, indentations, headers).
     - `SourceFactCitationsBox` (Lists the exact verified data points used by AI to generate the narrative).
   - **For Section F (Loss Assessment Table)**:
     - `EmbeddedCalculationTable`: Renders the high-precision Claimed vs. Assessed grid with Depreciation, Salvage, and Excess.
   - **For Photo Annexure**:
     - `PhotoPlateLayoutSelector` (*2 Photos per page / 4 Photos per page*).
     - `AnnexurePhotoGrid` with drag-and-drop reordering, caption editors, and watermark inspectors.
3. **Mandatory AI Disclaimer & Human Approval Gate (Modal / Banner)**:
   - `ApprovalGateModal` (Enforced before `.docx` download):
     - `Checkbox1`: "Surveyor has reviewed all AI-generated narrative content and text."
     - `Checkbox2`: "Surveyor confirms factual accuracy of site observations, timelines, and damage items."
     - `Checkbox3`: "Surveyor confirms calculations, depreciation schedules, and policy terms interpretation."
     - `Checkbox4`: "Final professional and legal responsibility for the survey report remains with the licensed surveyor."
     - `ConfirmAndExportButton` (Enabled only when all 4 checkboxes are selected).
4. **Word Document Export Toolbar**:
   - `SurveyorLetterheadSelect` (Select firm template, logo, and registration details).
   - `SignOffBlockConfig` (Surveyor Name, SLA License Number, Membership Details, Signature upload).
   - `ExportDocxButton` (Compiles and downloads `.docx` with embedded Without Prejudice disclaimers).

---

## 4. Standard 9-Section Final Survey Report Structure

| Section | Title | Primary Content & Origin | AI Touchpoint |
| :--- | :--- | :--- | :--- |
| **Section A** | Basic Claim Information | Insurer, Policy #, Claim #, Insured Name, Loss Date, Survey Date (Stage 1) | Auto-compiled |
| **Section B** | Brief Description of Risk | Business nature, occupancy, building structure, surrounding risks (Stage 4) | Form-filled |
| **Section C** | Cause & Circumstances of Loss | Chronological sequence of events, origin, FIR/Fire findings (Stage 5) | **AI Narrative Drafter (AI-4)** |
| **Section D** | Physical Survey Findings | Damaged item inventory, inspection observations, repairability (Stage 6) | **AI Narrative Drafter (AI-4)** |
| **Section E** | Documents Considered | List of invoices, FAR extracts, stock ledgers, repair estimates (Stage 7, 10) | Auto-formatted list |
| **Section F** | Claim Assessment Statement | Tabular breakdown: Claimed vs Gross Assessed, Depr., Salvage, Excess (Stage 11) | High-precision table |
| **Section G** | Policy Terms & Conditions | Policy sums insured, warranties, excess clause, endorsements (Stage 2) | Auto-compiled |
| **Section H** | Discrepancies / Observations | Audit anomalies, inflated rates, duplicate items, location issues (Stage 10) | **AI Narrative Drafter (AI-4)** |
| **Section I** | Surveyor's Opinion & Recommendation | Factual conclusion, admissibility, net payable recommendation (Stage 13) | **AI Narrative Drafter (AI-4)** |
| **Annexure** | Photographic Evidence Plates | Watermarked photos with captions, GPS coordinates, timestamps (Stage 6) | 2/4 Plate Layout Engine |

---

## 5. AI Assistant Integration & Triggers
- **Primary AI Feature (Report Draft Generator - AI-4)**:
  - Synthesizes all verified inputs into professional, objective insurance surveyor prose.
  - Zero-Hallucination Policy: Operates strictly on deterministic prompt grounding. Missing facts trigger explicit `[SURVEYOR TO VERIFY]` placeholders.
  - Tone & Style: Complies with standard Indian and international loss adjusting conventions (e.g., uses formal phrases such as *"During our physical inspection on site...", "The insured has claimed...", "We have assessed the loss as under..."*).
- **Surveyor Full Control & Gatekeeping**: Every paragraph, heading, and sentence generated by AI is 100% editable in real time, and report export is locked behind the 4-point Human Approval Gate.

---

## 6. Offline State & Sync Indicators
- Report drafts and section texts are stored in SQLite and can be edited offline.
- Client-side `.docx` generation operates completely offline on both Web and Mobile devices.

---

## 7. Action Triggers & Navigation
- **Click "Export Editable Word (.docx)"**: Opens the Human Approval Gate modal; once confirmed, compiles full report into a formatted `.docx` file and triggers download.
- **Click "Proceed to Pre-Submission Review"**: Validates all sections and advances to Stage 15 (`16_internal_review_submission`).
