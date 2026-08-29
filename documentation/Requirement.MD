# Software Requirements Specification (SRS)
# Project: SurveyAssist MVP (AI-Assisted Claim Surveyor Platform)
**Version:** 1.0.0-MVP  
**Document Status:** Approved Baseline  
**Scope:** Insurance Survey & Loss Assessment Lifecycle (Appointment to Final Survey Report)

---

## 1. Executive Summary & Domain Context

### 1.1 Purpose & Vision
**SurveyAssist** is a professional, domain-specialized software system engineered for licensed General Insurance Claim Surveyors and Loss Assessors (SLA). The MVP focuses exclusively on eliminating administrative bottlenecks, preventing discrepancies, and accelerating the preparation of **Preliminary Survey Reports (PSR)** and **Final Survey Reports (FSR)** through deterministic calculations and grounded AI assistance.

The platform directly answers the **Five Core Questions of Every Loss Assessment**:
1. **What happened?** *(Accurate chronology, origin, peril, and incident dynamics)*
2. **What was damaged?** *(Systematic physical inventory, make/model/serial verification, extent of damage)*
3. **Is the damage connected to the reported incident?** *(Forensic consistency, peril alignment, and physical plausibility)*
4. **How much is the actual loss?** *(Detailed quantification, depreciation schedules, obsolescence, and betterment)*
5. **What amount is reasonably recommended under the policy terms?** *(Application of Average clause / Underinsurance, Salvage realization, and Policy Excess / Deductible)*

### 1.2 Core Architectural Principles
- **Zero-Hallucination AI Architecture**: AI narrative generators are strictly bound to verified surveyor inputs, OCR extractions, and physical evidence. Probabilistic speculation on numbers, policy terms, dates, or causes is architecturally prohibited.
- **Offline-First Operability**: 100% of field survey actions (evidence capture, GPS tagging, voice notes, damage itemization) function seamlessly without an active internet connection, using local storage with automatic bi-directional synchronization.
- **Local / On-Device LLM Readiness**: Modular AI architecture (`AIProviderInterface`) with cloud execution when online, and explicit integration slots for on-device quantized models (e.g., local Whisper STT, on-device SLM) when offline.
- **Future-Proof RBAC Schema**: Database schema embeds tenancy, user ownership, and role scopes (`SURVEYOR`, `REVIEWER`, `ADMIN`, `INSURER_VIEWER`) to support future multi-tier firm and insurer portals without complicating the MVP UI.
- **Editable Word Document (`.docx`) Export**: Native compilation of comprehensive, formatted `.docx` reports containing tables, deduction justification matrices, and high-resolution photo annexures.

---

## 2. Target Platforms & Technical Architecture

### 2.1 Target Platforms & Form Factors
1. **Mobile Application (iOS & Android)**:
   - Optimized for field surveys, physical site inspections, voice-to-text notes, GPS-stamped multi-photo capture, and offline recording.
2. **Web Desktop Application (Responsive Web)**:
   - Optimized for office desk operations: appointment intake, bulk invoice OCR verification, complex loss quantification matrices, narrative review, and Final Survey Report `.docx` generation.

### 2.2 System Architecture Overview

```
+-----------------------------------------------------------------------------------+
|                               USER INTERFACE LAYER                                |
|   +---------------------------------------+   +-------------------------------+   |
|   |    Mobile App (iOS & Android)         |   |    Web Desktop Application    |   |
|   |    - High-Res Field Photo Studio      |   |    - Policy & Document Audit  |   |
|   |    - Voice Note Field Assistant       |   |    - Head-Wise Loss Matrix    |   |
|   |    - Offline Damage Item Register     |   |    - FSR Builder & Docx Engine|   |
|   +---------------------------------------+   +-------------------------------+   |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
|                        OFFLINE-FIRST CLIENT DATA LAYER                            |
|   - Local Encrypted Database (SQLite / IndexedDB / WatermelonDB)                  |
|   - Local Media File Store (Compressed, Watermarked Photos & Audio)               |
|   - Bi-Directional Sync Queue & Conflict Resolution (Field-Level Timestamp Merging)|
+-----------------------------------------------------------------------------------+
                                         | (Sync when connected)
                                         v
+-----------------------------------------------------------------------------------+
|                             BACKEND API SERVICE LAYER                             |
|   - Claim Pipeline & State Machine (15 Stages)                                    |
|   - Document OCR & Parsing Microservice                                           |
|   - Media Storage & CDN Service (Encrypted S3 / Cloud Storage)                    |
|   - Report Compilation Engine (DOCX / XML Template Generator)                     |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
|                        MODULAR AI ORCHESTRATION LAYER                             |
|   +---------------------------------------------------------------------------+   |
|   |                 AI Provider Interface (IAssistantService)                 |   |
|   +-------------------------------------+-------------------------------------+   |
|                                         |                                         |
|                 +-----------------------+-----------------------+                 |
|                 | (Cloud Provider Mode) | (Local Mode - Offline)|                 |
|                 v                       v                       v                 |
|         +---------------+       +---------------+       +---------------+         |
|         | Cloud LLM API |       | Cloud OCR API |       | Local Models  |         |
|         | (Drafting,    |       | (Invoices,    |       | (Whisper STT, |         |
|         |  Audit)       |       |  Bills)       |       |  Local SLM)   |         |
|         +---------------+       +---------------+       +---------------+         |
+-----------------------------------------------------------------------------------+
```

---

## 3. End-to-End Functional Requirements (15-Stage Workflow)

### Stage 1: Receipt of Survey Appointment
- **FR-1.1**: The system shall allow creation of new survey assignments via manual form entry or smart extraction from insurer appointment letters (PDF/Email).
- **FR-1.2**: Mandatory Appointment Data Attributes:
  - `appointment_id`, `insurer_name`, `operating_office_division`, `insurer_claim_ref_no`, `appointment_date`.
  - `policy_number`, `insured_name`, `insured_phone`, `insured_email`, `representative_name_designation`.
  - `policy_risk_address`, `date_of_loss`, `time_of_loss`, `reported_nature_of_loss`, `preliminary_loss_estimate`.
  - `insurer_specific_instructions` (e.g., joint survey requirement, specific salvage guidelines, interim report deadlines).
- **FR-1.3**: The system shall assign an internal tracking reference (e.g., `SA-2026-00101`) and initialize the survey state machine at Stage 1.

### Stage 2: Preliminary Review of Policy & Claim Intimation
- **FR-2.1**: The system shall record and structure comprehensive policy schedule parameters:
  - Policy Type (Standard Fire & Special Perils, IAR, Burglary, Machinery Breakdown, Electronic Equipment, Marine Cargo).
  - Policy Validity Period (`inception_date` to `expiry_date`).
  - Section-wise Sums Insured (Building, Plant & Machinery, Furniture/Fixtures, Raw Materials, Work-in-Progress, Finished Goods, Stock in Open).
  - Perils Covered, Special Clauses (e.g., Designation of Property, Escalation, Reinstatement Value Clause).
  - Warranties & Conditions (e.g., FEA Warranty, Silent Warranty, Good Housekeeping, 24/7 Security).
  - Policy Excess / Deductible schedule (per section / percentage of claim subject to minimum).
- **FR-2.2**: The system shall record the Insured’s formal Claim Intimation letter and initial estimate.
- **FR-2.3**: **AI Policy Assistant**: Automatically highlights specific warranties, deductibles, and exclusions relevant to the reported peril.

### Stage 3: Initial Contact & Survey Visit Scheduling
- **FR-3.1**: The system shall record contact attempt logs with the insured (Call timestamp, Contact person, Phone number, Discussion summary, Availability of site).
- **FR-3.2**: The system shall schedule site inspection dates and synchronize with device calendars.
- **FR-3.3**: **Evidence & Loss Preservation Notice**: The system shall generate a standard communication dispatch (via WhatsApp/Email/SMS) instructing the insured:
  - Immediate preservation of affected items, debris, and burnt/water-damaged stock.
  - Active loss mitigation duties.
  - Prohibition of disposal, overhaul, or repair without prior surveyor inspection.

### Stage 4: Verification of Risk & Loss Location
- **FR-4.1**: The mobile app shall capture device GPS coordinates (Latitude, Longitude, Accuracy, Altitude, Timestamp) upon arrival at the survey site.
- **FR-4.2**: The system shall record the physical Loss Location (Postal Address, Landmarks, Geo-coordinates) and compare it against the Policy Risk Location.
- **FR-4.3**: **Location Discrepancy Protocol**:
  - If physical location does not match policy schedule, the system shall flag `LOCATION_DISCREPANCY_DETECTED`.
  - System enforces surveyor to document: nature of occupancy, business activities conducted, ownership of premises, and reason for discrepancy for insurer reference.

### Stage 5: Investigation of Cause & Circumstances
- **FR-5.1**: The system shall provide an **Incident Chronology Builder**:
  - Exact time of occurrence, discovery, and notification.
  - Events immediately prior to the incident (routine operations, maintenance, shutdown, power fluctuations).
  - Detailed sequence during the incident (origin point, spread vector, containment actions).
  - Post-incident containment (fire brigade attendance, water pumping, temporary roofing, police reporting).
- **FR-5.2**: The system shall record statutory and institutional evidence:
  - FIR / Police Station Diary (Number, Date, Police Station, Gist).
  - Fire Brigade Report (Station, Call time, Arrival time, Containment time, Stated cause).
  - Meteorological / IMD Weather Reports, Factory Shift Logs, CCTV Footage notes, Witness Statements.
- **FR-5.3**: **AI Chronology Consistency Checker**: Flags timeline discrepancies between reported loss time, fire brigade call time, and factory logbooks.

### Stage 6: Physical Inspection & Damage Documentation Studio
- **FR-6.1**: **Damaged Property Itemized Register**:
  - Item Head (Building, Plant & Machinery, Electrical, FFF, Stocks).
  - Description, Make, Model, Capacity, Serial Number / Asset Tag.
  - Quantity Affected, Unit of Measurement (Nos, Kgs, Meters, SqFt).
  - Nature & Extent of Damage (Total Destruction, Severe Submersion, Smoke Contamination, Repairable Component Burnout).
  - Surveyor Recommendation (*Repairable vs. Total Loss / Replace*).
  - Pre-existing Wear & Tear / Prior Deterioration Notes.
- **FR-6.2**: **Smart Photo Studio (Mobile & Desktop)**:
  - Camera capture with automated indelible watermark overlay (Timestamp, GPS Coordinates, Claim Ref ID, Surveyor ID).
  - Multi-category tagging: *1. Panoramic/Overall Site View, 2. Affected Section/Room, 3. Specific Damaged Machine/Asset, 4. Serial Number / Nameplate, 5. Close-up Damage Detail, 6. Origin / Point of Incident*.
  - Surveyor voice notes recorder attached directly to individual damage items.

### Stage 7: Verification of Ownership & Insurable Interest
- **FR-7.1**: The system shall record and link ownership verification records:
  - Original purchase invoices, Bill of Entry (for imported machinery), Delivery challans.
  - Fixed Asset Register (FAR) extracts with asset capitalization dates.
  - Stock Ledgers, Daily production logs, Monthly stock statements submitted to banks.
  - GST Returns (GSTR-1, GSTR-3B) and Audited Balance Sheet extracts.
  - Hypothecation / Leasehold / Bank Mortgage details.
- **FR-7.2**: The system shall verify whether affected property was in active custody, present at the risk location, and belonged to the insured prior to the incident.

### Stage 8: Document Requirement Notice & Preliminary Survey Report (PSR)
- **FR-8.1**: **Smart Document Requirement Generator**:
  - Dynamic checklist generator based on loss category (Fire, Flood, Burglary, Machinery Breakdown).
  - Generates official Document Requisition Letter exportable to `.docx` or shareable via email.
- **FR-8.2**: **Preliminary Survey Report (PSR) Engine**:
  - Auto-compiles key survey data into standard insurer PSR format: Basic claim info, date of survey, nature/cause of loss, preliminary damage observations, initial estimated loss reserve / exposure, and pending document list.
  - Exportable to editable `.docx`.

### Stage 9: Follow-Up Surveys & Re-Inspection Tracking
- **FR-9.1**: The system shall support logging multiple subsequent survey visits (e.g., Visit #2: Dismantling/Internal inspection; Visit #3: Post-repair verification; Visit #4: Salvage lifting).
- **FR-9.2**: Record follow-up survey findings, contractor discussions, repair invoice verification, and photographic proof of repaired/replaced assets.

### Stage 10: Verification of Claim Documents & Forensic Audit
- **FR-10.1**: **Document Locker & OCR Pipeline**:
  - Storage for Claim Bills, Contractor Repair Estimates, OEM Quotations, Purchase Invoices, and Salvage Offers.
  - OCR line-item extraction (Item name, Qty, Unit Rate, GST/Taxes, Total).
- **FR-10.2**: **AI Claim Audit & Discrepancy Detector**:
  - Cross-checks Claim Bill items against original purchase invoices and damage inspection register.
  - Flags duplicate claim entries, inflated labor rates, obsolete items, and items not damaged during the incident.
  - Identifies "Betterment" components (e.g., replacing old model with upgraded modern specification).

### Stage 11: Detailed Loss Assessment & Quantification Matrix
- **FR-11.1**: The system shall provide an enterprise-grade calculation grid structured by asset heads:
  - Head 1: Building / Civil Works
  - Head 2: Plant, Machinery & Equipment
  - Head 3: Furniture, Fixtures & Fittings
  - Head 4: Stocks (Raw Material, WIP, Finished Goods)
  - Head 5: Other Insured Property
- **FR-11.2**: Line-Item Mathematical Engine:
  - `Claimed Amount (₹)`
  - `Assessed Gross / Reinstatement Cost (₹)`
  - `Depreciation % & Depreciation Deduction (₹)` (Based on age, asset class, and standard surveyor depreciation scales)
  - `Betterment Deduction (₹)` (New for Old adjustment)
  - `Sub-Total Assessed Net of Depreciation (₹)`
  - `Underinsurance / Average Clause Factor & Deduction (₹)`  
    $$\text{If } \text{Value at Risk (VAR)} > \text{Sum Insured (SI)} \implies \text{Loss Factor} = \frac{\text{Sum Insured}}{\text{Value at Risk}}$$
  - `Salvage Value Realization (₹)`
  - `Policy Excess / Deductible (₹)` (Per policy terms: percentage of claim or fixed minimum)
  - `Net Recommended Loss (₹)`
- **FR-11.3**: Mandatory justification notes required for every rate reduction, depreciation rate, or disallowed claim item.

### Stage 12: Salvage Verification & Disposal Management
- **FR-12.1**: The system shall track salvageable inventory (Description, estimated weight/quantity, condition, storage location).
- **FR-12.2**: The system shall support both disposal modes:
  - **Mode A (Retained by Insured)**: Agreed salvage value deducted directly from the loss assessment.
  - **Mode B (Disposed via Buyer / Tender)**: Record tender bids, buyer details, delivery confirmation, sale invoice, and realized cash value.
- **FR-12.3**: Salvage values feed directly into the Head-wise quantification sheet.

### Stage 13: Coverage and Liability Consideration
- **FR-13.1**: The system shall structure the surveyor’s professional liability remarks:
  - Operative Peril evaluation (e.g., Short circuit vs. Overheating; Accidental Fire vs. Arson).
  - Policy terms, exclusions, and warranty compliance (e.g., Maintenance warranty, Fire fighting appliances warranty).
  - Identification of any breach or material fact requiring insurer special consideration.
- **FR-13.2**: Surveyor recommendation status: *Admissible / Non-Admissible / Subject to Insurer Liability Determination*.

### Stage 14: Final Survey Report (FSR) Generation
- **FR-14.1**: The system shall compile the standard 9-Section Final Survey Report:
  - **Section A**: Basic Claim & Appointment Information
  - **Section B**: Description of Risk, Premises & Insured Business Activity
  - **Section C**: Chronological Cause and Circumstances of Loss
  - **Section D**: Physical Survey Findings & Damage Verification
  - **Section E**: Schedule of Documents Considered & Relied Upon
  - **Section F**: Detailed Loss Assessment Statement (Head-wise Claimed vs. Assessed Table)
  - **Section G**: Policy Terms, Conditions, Warranties & Deductibles
  - **Section H**: Discrepancies, Irregularities & Material Observations
  - **Section I**: Surveyor’s Opinion and Final Net Recommendation (Without Prejudice)
- **FR-14.2**: **AI Report Narrative Drafter (Primary AI Feature)**:
  - Transforms structured field notes, timeline events, and audit findings into formal, objective, surveyor-grade prose for Sections C, D, H, and I.
- **FR-14.3**: **Editable Document Engine (`.docx`)**:
  - Compiles the complete FSR into a beautifully styled `.docx` file complete with header/footer, surveyor sign-off blocks, formatted calculation tables, and high-resolution photo plates with captions.

### Stage 15: Internal Review, Pre-Submission Audit & Submission
- **FR-15.1**: **Automated Consistency Auditor**:
  - Verifies math totals: Claimed, Depreciation, Salvage, Excess, and Net Recommended.
  - Validates cross-section data: Policy number, Claim number, Insured name, Loss date.
  - Ensures every photo has a caption, timestamp, and location tag.
- **FR-15.2**: Final sign-off record, report archiving, and dispatch tracking log.

---

## 4. AI System Specification & Zero-Hallucination Guardrails

### 4.1 AI Modules Specification
| AI Feature | Primary Role | Grounding Dataset | Guardrail Rules |
| :--- | :--- | :--- | :--- |
| **AI-1: Voice-to-Text Assistant** | Transcribe field speech to structured damage items | Surveyor microphone audio | Direct acoustic-to-text mapping; surveyor confirms extracted fields. |
| **AI-2: Document & Invoice OCR** | Extract line items, rates, taxes, totals from bills | Scanned PDF / Image documents | Bounding boxes mapped to source document; surveyor clicks to verify source. |
| **AI-3: Cross-Checking & Fraud Audit** | Detect duplicates, unlisted items, inflated rates | Claim bill + Invoices + Policy Schedule | Deterministic string matching and numeric variance checks. No guesswork. |
| **AI-4: Report Draft Generator (CORE)** | Draft narrative sections (C, D, H, I) of PSR/FSR | Verified facts from Stages 1–13 | Strict prompt boundaries: AI is forbidden from inventing facts or dates. Missing data produces `[SURVEYOR TO VERIFY]` placeholder. |
| **AI-5: Loss Assessment Calculator** | Calculate depreciation, average clause, excess | User-selected rates and asset ages | Pure deterministic formula engine. Zero probabilistic generation of numbers. |

### 4.2 Local / On-Device AI Architecture Strategy
The system encapsulates all AI operations behind a unified TypeScript/Python interface:

```typescript
interface IAssistantService {
  transcribeAudio(audioBlob: Blob): Promise<TranscriptionResult>;
  extractDocumentLineItems(documentFile: FileBlob): Promise<ExtractedDocumentTable>;
  auditClaimDiscrepancies(claimData: ClaimDataset): Promise<DiscrepancyReport>;
  generateReportNarrative(section: ReportSectionKey, context: GroundedContext): Promise<NarrativeDraft>;
}
```
- When network status is `ONLINE`, requests route to `CloudAssistantService`.
- When network status is `OFFLINE`, requests route to `LocalAssistantService` (integrating local on-device small models e.g., local Whisper STT).

---

## 5. Data Model & RBAC-Ready Schema

### 5.1 RBAC Schema Metadata (Zero UI Gates in MVP)
All database entities include standard multi-tenant and role management columns:
- `tenant_id`: UUID (Surveyor firm / organization)
- `created_by_user_id`: UUID (Author)
- `assigned_surveyor_id`: UUID (Field surveyor)
- `reviewer_id`: UUID (Senior surveyor / partner)
- `access_role_scope`: Enum (`['SURVEYOR', 'REVIEWER', 'ADMIN', 'INSURER_VIEWER']`)

### 5.2 Core Entities Schema Definition
1. **`claims`**: `id`, `tenant_id`, `claim_ref_no`, `policy_no`, `insurer_name`, `insured_name`, `loss_date`, `peril`, `status`, `current_stage`, `created_at`, `updated_at`.
2. **`policy_details`**: `id`, `claim_id`, `policy_type`, `inception_date`, `expiry_date`, `sum_insured_total`, `excess_clause`, `warranties_json`.
3. **`site_visits`**: `id`, `claim_id`, `visit_no`, `visit_date`, `gps_lat`, `gps_lng`, `actual_location_address`, `location_discrepancy_flag`.
4. **`cause_investigations`**: `id`, `claim_id`, `incident_datetime`, `discovery_datetime`, `reported_cause`, `sequence_of_events`, `fir_details`, `fire_report_details`.
5. **`damage_items`**: `id`, `claim_id`, `head_category`, `description`, `make_model_serial`, `qty`, `uom`, `damage_extent`, `repair_or_replace`, `pre_existing_damage`.
6. **`media_attachments`**: `id`, `claim_id`, `damage_item_id`, `file_uri`, `thumbnail_uri`, `media_type`, `category_tag`, `gps_lat`, `gps_lng`, `timestamp`, `caption`.
7. **`documents`**: `id`, `claim_id`, `doc_type`, `file_name`, `file_uri`, `ocr_status`, `ocr_data_json`, `verified_flag`.
8. **`assessment_line_items`**: `id`, `claim_id`, `head_category`, `description`, `claimed_amount`, `assessed_gross`, `depreciation_pct`, `depreciation_amount`, `betterment_amount`, `salvage_amount`, `underinsurance_deduction`, `excess_deduction`, `net_recommended`, `justification_remarks`.
9. **`salvage_records`**: `id`, `claim_id`, `description`, `qty_weight`, `disposal_mode`, `buyer_info`, `realized_amount`.
10. **`final_survey_reports`**: `id`, `claim_id`, `section_a_json` ... `section_i_json`, `docx_file_uri`, `generated_at`, `status`.

---

## 6. Non-Functional & Security Requirements

### 6.1 Offline Sync & Media Optimization
- **Media Compression**: Images compressed on-device to standard JPEG (1600x1200, 85% quality) with preserved EXIF and metadata overlay prior to cloud sync.
- **Sync Resilience**: Automatic retry with exponential backoff for media uploads; background synchronization queue.

### 6.2 Security & Data Integrity
- **Local Storage Encryption**: SQLite/WatermelonDB encrypted with SQLCipher (AES-256) on mobile devices.
- **Data in Transit**: Enforced TLS 1.3 for all API and media transport.
- **Audit Logging**: Immutable audit logs capturing every modification to loss assessment figures (User, Timestamp, Field, Old Value, New Value).

### 6.3 Document Generation Benchmark
- Full 9-section `.docx` generation with up to 50 embedded photo plates must complete in `< 5 seconds`.
