# Screen Specification: 09_preliminary_survey_report_psr

## 1. Screen Objective & Context
- **Screen Name**: Document Requisition Notice & Preliminary Survey Report (PSR)
- **Stage Mapping**: Stage 8 of 15 (Issue of Document Requirement / Preliminary Survey Report)
- **Purpose**: Generates the official **Document Requisition Notice** to be issued to the insured, and compiles the **Preliminary Survey Report (PSR)** for immediate submission to the appointing insurer. Establishes the initial loss reserve/exposure, summarizes initial site inspection observations, and outlines required next steps.

---

## 2. Layout & UI Architecture

### 2.1 Primary Mobile App View (iOS & Android) - Core Mobile Experience
- **Mobile Requisition & PSR Hub**:
  - Segmented toggle at top: *1. Request Documents* vs. *2. Preliminary Report (PSR)*.
  - Interactive document checklist with tap-to-toggle requirements and peril presets.
  - "Send Requisition to Insured" action button via native WhatsApp/Email share sheet.
  - PSR Preview card with estimated exposure reserve input.
  - "Generate & Export PSR (.docx)" one-tap compilation button.
  - Bottom CTA: "Save & Proceed to Follow-Up Visits".

### 2.2 Responsive Desktop Web View
- **Two-Tab Dual Output Workspace**:
  - **Tab 1: Document Requisition Checklist & Dispatch**: Peril-based smart document checklist selector, live Document Requisition Notice preview, and multi-channel dispatch controls.
  - **Tab 2: Preliminary Survey Report (PSR) Builder**: Pre-populated structured sections (Basic claim info, inspection date, preliminary cause, damage overview, estimated loss reserve) with live Word `.docx` preview and export.

---

## 3. Detailed UI Component Hierarchy
1. **Document Requisition Panel**:
   - `PerilChecklistPresets`: Quick buttons (*Fire Claim Preset*, *Flood Preset*, *Machinery Breakdown Preset*, *Burglary Preset*).
   - `DocumentRequirementChecklist`:
     - Standard Items: *Completed Claim Form, Detailed Claim Bill, Original Purchase Invoices, Asset Capitalization Register, Stock Statements (Last 12 Months), Bank Stock Statements, Repair Quotations & OEM Estimates, Police FIR, Fire Brigade Report, Salvage Proposals, Audited Balance Sheets*.
     - `CustomRequirementInput` (Add custom document demand, e.g., "Submit PLC error logbook").
     - `RequisitionLetterEditor` (Rich text editor for notice body).
     - `DispatchToolbar` (Buttons: *Send WhatsApp*, *Send Email to Insured*, *Export Docx*).
2. **Preliminary Survey Report (PSR) Builder**:
   - `BasicClaimParticularsBlock` (Read-only summary of Policy #, Insured, Date of Loss, Peril).
   - `SurveyVisitSummaryInput` (Date and time of visit, persons met).
   - `PreliminaryCauseNarrative` (AI-drafted summary from Stage 5).
   - `ApparentDamageOverview` (AI-drafted summary from Stage 6).
   - `EstimatedLossReserveInput` (₹ Estimated total insurer exposure).
   - `ImmediateNextStepsInput` (e.g., "Dismantling of motor scheduled for 15th Sept; salvage tenders to be floated").
   - `PSRDocxExportButton` (Generates fully styled editable Word `.docx` file).

---

## 4. Data Fields, Types & Validations

| Field | Type | Mandatory | Validation Rules | Description |
| :--- | :--- | :--- | :--- | :--- |
| `selected_required_docs`| Array<String> | Yes | At least 3 items selected | Required documents checklist |
| `requisition_due_date` | Date | Yes | Default: 15 days from issue | Deadline for document submission |
| `psr_date_of_survey` | Date | Yes | Cannot be in future | Date initial site survey was conducted |
| `preliminary_loss_reserve`| Currency (₹) | Yes | Numeric $> 0$ | Surveyor’s initial estimated exposure |
| `psr_next_steps` | Text | Yes | Min 20 chars | Planned follow-up actions |

---

## 5. AI Assistant Integration & Triggers
- **Smart Requisition Checklist Recommender**: AI analyzes the reported peril, insured business occupancy, and preliminary damage items to suggest specific forensic documents (e.g., suggests "Boiler Inspection Certificate" for boiler explosion claims).
- **PSR Narrative Synthesizer (AI-4)**: Automatically drafts the executive summary paragraphs of the Preliminary Survey Report in standard insurance surveyor terminology.
- **Zero-Hallucination Guardrail**: The preliminary loss reserve amount is entered exclusively by the surveyor; the AI never auto-generates or guesses financial reserves.

---

## 6. Offline State & Sync Indicators
- Requisition checklists and PSR drafts are created and saved locally in SQLite when offline.
- Document generation engine (`.docx` compiler) works entirely client-side using JavaScript/Docx templating.

---

## 7. Action Triggers & Navigation
- **Click "Export PSR (.docx)"**: Compiles and downloads the editable Word file.
- **Click "Save & Proceed to Follow-Up Investigation"**: Marks PSR as generated, advances to Stage 9 (`10_followup_investigation`).
