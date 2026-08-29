# User Stories & Acceptance Criteria
# Project: SurvScribe MVP (AI-Assisted Claim Surveyor Platform)
**Version:** 1.0.0-MVP  
**Document Status:** Approved Baseline  
**Scope:** 15-Stage Claim Survey Lifecycle + Offline Sync & AI Core  
**Design Paradigm:** **Mobile-First Application** — a single **React Native (TypeScript)** app for iOS & Android (touch ergonomics, offline WatermelonDB storage, hardware camera, push-to-talk voice everywhere). The companion desktop web app is **post-MVP**; the "Responsive Desktop Web View" sections in the screen specs are forward-looking design, not MVP acceptance criteria.

---

## ⚖️ Regulatory & Professional Responsibility Framework
> **Platform Legal Positioning Notice**:  
> **SurvScribe is a technology-assisted workflow platform and does not independently act as an Insurance Surveyor and Loss Assessor, insurer, insurance intermediary, or claims decision-maker.** All survey findings, loss assessments, coverage observations, recommendations, and reports generated or assisted by the platform shall be subject to review, validation, and professional approval by an appropriately licensed and authorised professional. Final claim liability and settlement decisions remain the responsibility of the relevant insurer in accordance with applicable policy terms and regulatory requirements.  
> 
> *Positioning Rule*: The platform is exclusively represented as *"A technology platform designed to assist licensed Insurance Surveyors and Loss Assessors in their professional workflow."*

---

## 📱 Global Mobile-First UX Baseline
Every Epic and User Story below is implemented with a **primary native Mobile View** featuring:
1. **Single-Hand & Field Ergonomics**: Sticky bottom action sheets, large touch targets ($\ge 48\text{px}$), swipe gestures for quick actions (Call, Navigate, Photo, Delete).
2. **Native Device Hardware Integration**: Direct hardware GPS geotagging, integrated camera with instant watermark overlay, native microphone for voice memos.
3. **100% Offline Field Usability**: Full local SQLite database persistence; all 15 survey steps operate with zero cellular connectivity.

---

## Epic 0: Surveyor Authentication & Registration Access Gate

### Story 0.1: Surveyor Sign In & Mobile/Email OTP (Screen 00_auth_login)
**As a** Licensed Claim Surveyor,  
**I want to** sign in using my email/password, custom username, or mobile phone/work email with OTP,  
**So that** I can securely access my assigned surveys and reports rapidly.

#### Acceptance Criteria
- **AC 0.1.1 (Universal Identifier Login)**: Entering a valid email address, username, or mobile number with password directs the surveyor to `01_dashboard`.
- **AC 0.1.2 (Mobile Phone SMS OTP Login)**: Entering a 10-digit mobile number sends a 6-digit SMS OTP; entering the valid OTP completes authentication.
- **AC 0.1.3 (Work Email OTP Verification)**: Allows one-tap login via official work email OTP modal with 6-digit token and 45s resend timer.
- **AC 0.1.4 (Offline Field Session)**: In remote field sites with zero cellular coverage, cached session credentials permit offline survey creation and editing.
- **AC 0.1.5 (Switch to Sign Up)**: Clicking "Register as Surveyor" seamlessly navigates to `00_auth_signup`.

### Story 0.2: New Surveyor Registration & Profile Setup (Screen 00_auth_signup)
**As a** New Surveyor or Firm Associate,  
**I want to** register an account with my firm name, SLA license number, and category,  
**So that** my survey reports automatically include my verified surveyor credentials.

#### Acceptance Criteria
- **AC 0.2.1 (Surveyor Profile Capture)**: Captures Full Name, Survey Firm Name, Mobile, and Email as **mandatory**. SLA License Number, Category (*Fellow / Associate / Licentiate / Trainee*), and Operating Territory / Base Location are **optional at signup**. However, **Final Survey Report (FSR) generation is blocked until the License Number and Category are supplied** (they populate the report sign-off block).
- **AC 0.2.2 (SLA License Format Validation & Disclaimer)**: When a license number is entered, the system validates that it matches expected formatting (regex `SLA-[0-9]{4,8}`) — syntax only, not regulatory verification. The UI displays an explicit disclaimer: *"License details are provided by the user and are subject to independent verification. Platform registration does not constitute regulatory approval or endorsement."*
- **AC 0.2.3 (Immediate Dashboard Access)**: Upon successful sign-up, the surveyor is redirected to the dashboard with initial onboarding guidance.
- **AC 0.2.4 (Switch to Sign In)**: Clicking "Already have an account? Sign In" navigates back to `00_auth_login`.

---

## Epic 1: Survey Appointment & Claim Intake (Stage 1)

### Story 1.1: Record & Intake Survey Appointment
**As a** Claim Surveyor,  
**I want to** log the insurer appointment letter details and claim basics,  
**So that** I have a single organized assignment record with all critical policy and insurer instructions.

#### Acceptance Criteria
- **AC 1.1.1 (Manual Entry)**: Given the surveyor is on the Appointment Intake screen, when they enter the Insurer Name, Claim Reference Number, Policy Number, Insured Legal Name, Risk Address, Date of Loss, and Reported Peril, then the system saves the record and generates an internal Survey Reference ID in the format `SS-YYYY-XXXXX` (e.g., `SS-2026-00101`).
- **AC 1.1.2 (Smart Appointment OCR Parsing)**: Given a PDF/Email appointment letter, when the surveyor uploads the document, then the AI pre-fills the form fields with an accuracy confidence score, allowing the surveyor to review and confirm.
- **AC 1.1.3 (Special Instructions)**: The system must capture insurer-specific mandates (e.g., "Joint survey required with Forensic team", "Collect salvage quotes immediately") and highlight them prominently in the claim summary banner.
- **AC 1.1.4 (Offline Creation)**: Given no cellular connection on mobile, when the surveyor creates a new claim assignment, it is stored in the local SQLite database and flagged for synchronization.

---

## Epic 2: Policy Schedule & Intimation Review (Stage 2)

### Story 2.1: Structure Policy Schedule & Coverage Sections
**As a** Claim Surveyor,  
**I want to** record the policy sections, sums insured, perils, deductibles, and warranties,  
**So that** I have a baseline against which to evaluate admissibility and loss quantification.

#### Acceptance Criteria
- **AC 2.1.1 (Section-Wise Sums Insured)**: The system allows entering sums insured for individual heads (Building, Plant & Machinery, Furniture/Fixtures, Raw Materials, WIP, Finished Goods).
- **AC 2.1.2 (Deductibles & Excess Terms)**: The system allows recording policy excess terms (e.g., "5% of claim amount subject to minimum ₹25,000 for SFSP policy").
- **AC 2.1.3 (AI Policy Clause Highlighter)**: Given the reported peril (e.g., "Inundation / Flood"), when the surveyor opens Policy Review, then the AI highlights applicable warranties (e.g., "Plinth Level Warranty") and standard exclusions without altering the original text.
- **AC 2.1.4 (Claim Intimation Amount)**: The system records the initial estimated claim bill submitted by the insured.

---

## Epic 3: Insured Contact & Site Visit Scheduling (Stage 3)

### Story 3.1: Contact Logging & Evidence Preservation Notice
**As a** Claim Surveyor,  
**I want to** log communications with the insured and issue a standard Loss Preservation Notice,  
**So that** evidence is protected and the site inspection is formally scheduled.

#### Acceptance Criteria
- **AC 3.1.1 (Communication Log)**: Given a phone conversation with the insured, when the surveyor records the date, time, contact person, and discussion notes, then a chronological log is appended to the claim.
- **AC 3.1.2 (Evidence Preservation Notice Dispatch)**: The system generates an official Loss Preservation Notice stating: (1) Preserve damaged property/debris, (2) Do not repair/overhaul without surveyor inspection, (3) Take loss mitigation steps.
- **AC 3.1.3 (Multi-Channel Dispatch)**: The notice can be copied, sent via WhatsApp, or emailed with one click.
- **AC 3.1.4 (Calendar Integration)**: The scheduled survey date/time can be synced to the mobile device’s native calendar.

---

## Epic 4: Risk & Location Verification (Stage 4)

### Story 4.1: Geo-Tag Risk Location & Flag Address Discrepancies
**As a** Field Surveyor,  
**I want to** capture the exact GPS coordinates and physical address of the loss site,  
**So that** I can verify whether the loss occurred at the policy-specified risk location.

#### Acceptance Criteria
- **AC 4.1.1 (GPS Auto-Capture)**: On mobile, clicking "Verify Location" captures latitude, longitude, altitude, accuracy radius, timestamp, and geocoded street address. A reading with accuracy worse than **10 m** warns and prompts re-capture (target `≤ 10 m`); a reading worse than **50 m** is rejected and cannot be saved (hard limit `≤ 50 m`).
- **AC 4.1.2 (Discrepancy Detection)**: If the physical address differs from the policy schedule address, the system prompts: "Address Discrepancy Detected - Is this loss location different from the policy schedule?".
- **AC 4.1.3 (Discrepancy Justification)**: If flagged, the surveyor must provide mandatory notes: occupancy description, nature of operations, and reason for discrepancy for insurer review.
- **AC 4.1.4 (Offline Geolocation)**: Works offline using native device GPS hardware without requiring cellular data.

---

## Epic 5: Cause & Circumstances Investigation (Stage 5)

### Story 5.1: Incident Chronology & Evidence Record
**As a** Claim Surveyor,  
**I want to** build an incident timeline and link statutory reports (FIR, Fire Brigade, CCTV),  
**So that** the cause and sequence of events are established with supporting proof.

#### Acceptance Criteria
- **AC 5.1.1 (Timeline Builder)**: The surveyor can add timestamped events (Occurrence, Discovery, Fire Service Arrival, Extinguishment, Police Intimation).
- **AC 5.1.2 (Statutory Evidence Vault)**: Allows entering and attaching FIR number/date, Fire Brigade incident report, IMD weather logs, and witness statements.
- **AC 5.1.3 (AI Chronology Consistency Check)**: When statutory documents are uploaded, the AI checks if the reported loss time contradicts the fire station dispatch log or factory shift log, displaying a warning if time gaps exceed 2 hours.

---

## Epic 6: Physical Inspection & Damage Documentation Studio (Stage 6)

### Story 6.1: Itemized Damaged Property Register
**As a** Field Surveyor,  
**I want to** catalog damaged assets with make, model, serial numbers, and damage extent,  
**So that** every damaged component is itemized for quantification.

#### Acceptance Criteria
- **AC 6.1.1 (Damage Item Entry)**: Record Item Name, Asset Head, Make/Model, Serial Number, Quantity, Unit of Measure, Extent of Damage (*Total Loss / Severe / Moderate / Repairable*).
- **AC 6.1.2 (Voice-to-Text Field Assistant)**: Given a surveyor speaking observations into the microphone (e.g., *"Siemens 50HP motor serial 8849 totally burnt due to short circuit, replacement required"*), the AI transcribes and populates the item fields automatically.
- **AC 6.1.3 (Pre-Existing Wear & Tear)**: Allows recording pre-existing rust, obsolete components, or maintenance defects with separate deduction notes.

### Story 6.2: High-Resolution Watermarked Photo Studio
**As a** Field Surveyor,  
**I want to** capture and tag photos with automatic metadata watermarking,  
**So that** visual proof is authenticated and organized for the survey report annexure.

#### Acceptance Criteria
- **AC 6.2.1 (Indelible Watermark)**: Every captured photo is embedded with non-editable text overlay: Date, Time, GPS Lat/Lng, Claim Ref Number, and Surveyor Name.
- **AC 6.2.2 (Category Tagging)**: Photos must be tagged with a category: *Overall Site View, Affected Room/Floor, Damaged Machine, Serial Plate, Point of Origin, Close-up Damage*.
- **AC 6.2.3 (Captions & Annotations)**: The surveyor can add descriptive captions to each photo.
- **AC 6.2.4 (Offline Storage & Compression)**: Photos are stored locally in compressed format (JPEG 1600x1200) and queued for cloud sync.

---

## Epic 7: Ownership & Insurable Interest Verification (Stage 7)

### Story 7.1: Verify Asset Ownership & Presence
**As a** Claim Surveyor,  
**I want to** verify purchase invoices, asset registers, and GST records against claimed items,  
**So that** I establish that the insured owned the property and it was present at the site.

#### Acceptance Criteria
- **AC 7.1.1 (Ownership Checklist)**: Complete a structured checklist: *1. Invoices verified, 2. Asset register cross-checked, 3. Stock register examined, 4. Bank hypothecation noted*.
- **AC 7.1.2 (Insurable Interest Status)**: Surveyor marks insurable interest as *Established / Disputed / Under Verification* with supporting remarks.
- **AC 7.1.3 (Document Linkage)**: Attach specific invoices directly to corresponding damage items in the register.

---

## Epic 8: Document Requirement & Preliminary Survey Report (Stage 8)

### Story 8.1: Document Requisition Letter & Preliminary Survey Report (PSR)
**As a** Claim Surveyor,  
**I want to** generate a document requisition checklist and assemble a PSR for the insurer,  
**So that** the insured knows what documents to submit and the insurer gets an initial loss reserve.

#### Acceptance Criteria
- **AC 8.1.1 (Dynamic Requisition Checklist)**: Select loss peril (Fire, Flood, Burglary) to auto-generate a tailored list of required documents (Claim form, Invoices, FIR, Audited Balance Sheet, Bank Stock Statements).
- **AC 8.1.2 (PSR Builder)**: Compiles basic claim details, preliminary loss observations, estimated loss exposure amount, and next steps into a formal PSR.
- **AC 8.1.3 (Editable .docx Export)**: Exports the PSR directly into an editable Microsoft Word (`.docx`) document.

---

## Epic 9: Follow-Up Surveys & Re-Inspection (Stage 9)

### Story 9.1: Log Re-Inspections & Repair Progress
**As a** Claim Surveyor,  
**I want to** record follow-up survey visits, dismantling findings, and repair verification,  
**So that** the progressive status of the claim is documented prior to final assessment.

#### Acceptance Criteria
- **AC 9.1.1 (Multi-Visit Log)**: Record Visit #2, Visit #3 with dates, purpose (e.g., "Internal inspection after motor dismantling"), and findings.
- **AC 9.1.2 (Progress Photos)**: Attach follow-up photos showing repaired or dismantled parts.
- **AC 9.1.3 (Stock Reconciliation)**: Record physical count verification notes against claimed stock losses.

---

## Epic 10: Document Verification & Forensic Audit (Stage 10)

### Story 10.1: OCR Line-Item Extraction & Discrepancy Detector
**As a** Claim Surveyor,  
**I want to** extract line items from claim bills and purchase invoices using OCR and run an automated cross-check,  
**So that** duplicate claims, inflated rates, and unlisted items are flagged automatically.

#### Acceptance Criteria
- **AC 10.1.1 (OCR Extraction)**: Upload repair estimates and invoices; AI extracts line item name, quantity, unit price, tax, and total.
- **AC 10.1.2 (Side-by-Side Visual Verification)**: Surveyor can view original document on one half of the screen and extracted fields on the other half.
- **AC 10.1.3 (Duplicate Item Alert)**: If an item description or invoice number appears twice across multiple claim bills, the system flags `DUPLICATE_CLAIM_ITEM`.
- **AC 10.1.4 (Rate Variance Flag)**: If claimed repair rate exceeds original purchase invoice rate by > 20%, the system flags `RATE_INFLATION_DETECTED` for surveyor review.

---

## Epic 11: Detailed Loss Assessment & Quantification Matrix (Stage 11)

### Story 11.1: Head-Wise Loss Quantification Spreadsheet
**As a** Claim Surveyor,  
**I want to** calculate the loss with automated deductions for depreciation, betterment, underinsurance, salvage, and policy excess,  
**So that** the final recommended amount is mathematically exact and justified.

#### Acceptance Criteria
- **AC 11.1.1 (Head-Wise Breakdown)**: Dedicated calculation rows grouped by Asset Heads (Building, Plant & Machinery, FFF, Stocks).
- **AC 11.1.2 (Depreciation Calculator)**: Entering asset age and category applies standard surveyor depreciation % or allows manual override with remarks.
- **AC 11.1.3 (Underinsurance / Average Clause Formula)**: The Average Clause is applied to the **Net of Depreciation** base (i.e. after depreciation and betterment, before salvage and excess). If Value at Risk (VAR) > Sum Insured (SI):
  $$\text{Underinsurance Deduction} = \text{Net of Depreciation} \times \left(1 - \frac{\text{SI}}{\text{VAR}}\right); \qquad \text{otherwise } 0$$
  equivalently, `After Underinsurance = Net of Depreciation × (SI / VAR)`.
- **AC 11.1.4 (Deductions Sequence)**: Deductions apply in strict regulatory order: Gross Assessed $\rightarrow$ Less: Depreciation $\rightarrow$ Less: Betterment $\rightarrow$ Less: Underinsurance (on Net of Depreciation) $\rightarrow$ Less: Salvage $\rightarrow$ Less: Policy Excess = **Net Recommended Amount**.
- **AC 11.1.5 (Mandatory Deduction Remarks)**: The system blocks report finalization if any line item deduction has an empty remark field.

---

## Epic 12: Salvage Verification & Disposal Management (Stage 12)

### Story 12.1: Track Salvage Inventory & Realization
**As a** Claim Surveyor,  
**I want to** inventory salvageable material and record buyer quotations or insured retention,  
**So that** accurate salvage deductions are credited against the claim.

#### Acceptance Criteria
- **AC 12.1.1 (Salvage Inventory)**: Record item, weight/quantity, condition, and estimated salvage value.
- **AC 12.1.2 (Disposal Mode Selection)**: Choose one of three modes — *Mode A: Retained by Insured*, *Mode B: Sold to Scrap Buyer*, or *Mode C: Tender floated by Insurer*.
- **AC 12.1.3 (Tender / Buyer Record)**: Record buyer name, contact, quote amount, sale invoice number, and payment confirmation.
- **AC 12.1.4 (Auto-Link to Assessment)**: Total realized salvage amount automatically feeds into the Section F loss assessment table.

---

## Epic 13: Coverage & Liability Consideration (Stage 13)

### Story 13.1: Formulate Professional Coverage Opinion (Decision Support)
**As a** Claim Surveyor,  
**I want to** record my factual analysis on peril applicability, policy warranties, and exclusions,  
**So that** I provide clear decision-support observations for the insurer's final liability determination without the AI making autonomous coverage decisions.

#### Acceptance Criteria
- **AC 13.1.1 (Peril Applicability)**: Record whether the proximate cause falls within the policy's insured perils based on physical evidence.
- **AC 13.1.2 (Warranty Compliance)**: Checklist verifying compliance with key warranties (e.g., Fire protection appliances, housekeeping, security).
- **AC 13.1.3 (Surveyor Recommendation Status)**: Select: *Admissible as Assessed / Subject to Insurer Liability Determination / Non-Admissible / Repudiation Recommended*.
- **AC 13.1.4 (Decision-Support Notice)**: Screen and report sections display the mandatory notice: *"Decision-support analysis for surveyor review. Final liability determination remains with the insurer."*
- **AC 13.1.5 (Without Prejudice Declaration)**: Report automatically includes the standard legal declaration: *"This assessment is issued without prejudice, subject to the terms and conditions of the policy and final acceptance by the insurer."*

---

## Epic 14: Final Survey Report (FSR) Generation (Stage 14)

### Story 14.1: AI Report Narrative Drafter (Primary AI Feature)
**As a** Claim Surveyor,  
**I want to** generate structured, formal narrative drafts for Sections C, D, H, and I from verified survey data,  
**So that** I can produce a thorough report in minutes without manual typing fatigue.

#### Acceptance Criteria
- **AC 14.1.1 (Zero-Hallucination Prompt Grounding)**: Narrative engine accepts ONLY structured data from Stages 1–13 (No open-ended web generation). If an input is missing, it inserts `[SURVEYOR TO VERIFY]` rather than inventing a detail.
- **AC 14.1.2 (Section C Drafting)**: Synthesizes the chronology, fire brigade timings, and sequence of events into a professional narration of "Cause & Circumstances of Loss".
- **AC 14.1.3 (Section D Drafting)**: Synthesizes physical findings, damaged item register, and inspection observations.
- **AC 14.1.4 (Section I Drafting)**: Generates surveyor opinion linking cause, physical proof, and quantification rationale.
- **AC 14.1.5 (Full In-Place Editing)**: Surveyor can directly edit, rewrite, or accept/reject AI draft text with a live word count.

### Story 14.2: Editable Word Document (`.docx`) Compilation & Human Approval Gate
**As a** Claim Surveyor,  
**I want to** complete a mandatory review verification before exporting the complete 9-section Final Survey Report into an editable `.docx` file,  
**So that** I maintain complete professional oversight and regulatory compliance over the generated report.

#### Acceptance Criteria
- **AC 14.2.1 (Standard 9 Sections)**: Document contains all sections: Section A (Basic Info), B (Risk Description), C (Cause & Circumstances), D (Survey Findings), E (Documents Considered), F (Loss Assessment Table), G (Policy Terms), H (Discrepancies), I (Surveyor Opinion & Recommendation).
- **AC 14.2.2 (Mathematical Tables)**: Section F is rendered as a clean, bordered table matching Claimed vs. Assessed figures with exact totals.
- **AC 14.2.3 (Photo Annexure Plates)**: Appends a dedicated Photo Annexure with 2 or 4 photos per page, complete with watermarks, captions, timestamps, and GPS coordinates.
- **AC 14.2.4 (Letterhead & Sign-Off)**: Includes surveyor firm header metadata and formal signature blocks.
- **AC 14.2.5 (Mandatory AI Review & Human Approval Gate)**: Before the `.docx` download/export is unlocked, the surveyor must check and confirm:
  1. `[x]` Surveyor has reviewed the AI-generated content.
  2. `[x]` Surveyor confirms factual accuracy of damage, timelines, and cause.
  3. `[x]` Surveyor confirms calculations, depreciation schedules, and policy interpretation.
  4. `[x]` Final professional responsibility remains with the licensed surveyor.

---

## Epic 15: Internal Review, Pre-Submission Audit & Submission (Stage 15)

### Story 15.1: Automated Consistency Audit & Dispatch Log
**As a** Claim Surveyor,  
**I want to** run an automated audit across all report sections and verify my sign-off before submission,  
**So that** errors, math mismatches, missing documentation, and unverified AI content are caught beforehand.

#### Acceptance Criteria
- **AC 15.1.1 (Arithmetic Verification)**: Verifies that Section F table totals match line item sums exactly to the rupee.
- **AC 15.1.2 (Metadata Consistency)**: Verifies that Policy Number, Claim Number, and Date of Loss match across all sections and photo captions.
- **AC 15.1.3 (Mandatory Document Gate)**: Flags missing required attachments (e.g., missing FIR copy for a fire claim).
- **AC 15.1.4 (Human Approval Gate Audit)**: Validates that all 4 points of the Human Approval Gate have been affirmatively accepted and logged in the immutable audit trail.
- **AC 15.1.5 (Submission Log & Hash Lock)**: Records report dispatch date, recipient insurer email/portal, generates an immutable SHA-256 hash snapshot, and archives a read-only record.

---

## Epic 16: Offline-First Engine & Future RBAC Infrastructure

### Story 16.1: Offline Data Synchronization Engine
**As a** Mobile Surveyor,  
**I want** all survey data, voice recordings, and photos to save locally and sync automatically when connected,  
**So that** I never lose data in remote survey locations.

#### Acceptance Criteria
- **AC 16.1.1 (Offline Indicator)**: Top bar displays "Offline Mode - Changes Saved Locally" with pending sync item count.
- **AC 16.1.2 (Auto-Sync on Reconnect)**: When device regains internet connection, local records sync to server with background media upload.
- **AC 16.1.3 (Conflict Resolution)**: Uses field-level timestamp merging with surveyor confirmation if a desk user edited the same claim concurrently.

### Story 16.2: Future RBAC & Insurer Data Governance
**As a** System Architect,  
**I want** all claim entities tagged with `tenant_id`, `created_by`, `assigned_surveyor_id`, and `role_scopes` with explicit insurer access governance rules,  
**So that** the platform supports multi-tier firm permissions and secure insurer portals without compromising surveyor independence.

#### Acceptance Criteria
- **AC 16.2.1 (Schema Tagging)**: Every created record is populated with active user ID and firm tenant ID.
- **AC 16.2.2 (Role Scopes)**: Role scopes (`SURVEYOR`, `REVIEWER`, `ADMIN`, `INSURER_VIEWER`) are stored as valid metadata without restricting MVP UI actions.
- **AC 16.2.3 (Insurer Access Controls)**: Access for `INSURER_VIEWER` requires explicit surveyor authorization, is strictly scoped to individual assigned claims, maintains immutable audit trails of all file accesses, and enforces surveyor data ownership boundaries.
