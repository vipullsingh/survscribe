# Software Requirements Specification (SRS)
# Project: SurvScribe MVP (AI-Assisted Claim Surveyor Platform)
**Version:** 1.0.0-MVP  
**Document Status:** Approved Baseline  
**Scope:** Insurance Survey & Loss Assessment Lifecycle (Appointment to Final Survey Report)

---

## 1. Executive Summary & Domain Context

### 1.1 Purpose & Vision
**SurvScribe** is a professional, domain-specialized software system engineered for licensed General Insurance Claim Surveyors and Loss Assessors (SLA). The MVP focuses exclusively on eliminating administrative bottlenecks, preventing discrepancies, and accelerating the preparation of **Preliminary Survey Reports (PSR)** and **Final Survey Reports (FSR)** through deterministic calculations and grounded AI assistance.

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

### 1.3 Regulatory & Professional Responsibility Framework
> **Regulatory & Professional Responsibility**
> 
> **SurvScribe is a technology-assisted workflow platform and does not independently act as an Insurance Surveyor and Loss Assessor, insurer, insurance intermediary, or claims decision-maker.** All survey findings, loss assessments, coverage observations, recommendations, and reports generated or assisted by the platform shall be subject to review, validation, and professional approval by an appropriately licensed and authorised professional. Final claim liability and settlement decisions remain the responsibility of the relevant insurer in accordance with applicable policy terms and regulatory requirements.

- **Platform Representation Baseline**: The platform is strictly positioned as *"A technology platform designed to assist licensed Insurance Surveyors and Loss Assessors in their professional workflow."* The platform and its marketing materials shall never claim or imply that it is an "IRDAI-approved" platform or an autonomous claims-adjudicating entity.
- **Professional Responsibility Retention**: The licensed surveyor retains full legal, professional, and ethical responsibility for all survey findings, reports, and loss assessments generated with assistance from the software.
- **Decision-Support Guardrails**: All automated calculations, clause extractions, and AI draft narratives serve exclusively as decision support for the licensed surveyor's expert review.

---

## 2. Target Platforms & Technical Architecture

### 2.1 Target Platforms & Form Factors (Mobile App First)
1. **Primary Platform (MVP): React Native (TypeScript) Mobile Application (iOS & Android)**:
   - Delivered as a **bare React Native** project (React Native 0.87.1 / React 19.2). The `ios/` and `android/` projects are **committed source**, not generated output, because the native configuration this product depends on — camera and location permissions, Keychain/Keystore custody, SQLCipher linkage — must be reviewable in version control (ADR-0011).
   - Built with a **Mobile-First paradigm** ensuring **every single stage and screen has a dedicated, touch-optimized Mobile View**.
   - Ergonomically designed for on-the-go single-hand and two-hand field operations: bottom navigation bars, swipe gestures, floating action buttons (FAB), hardware GPS integration, native camera photo studio with automatic watermarking, push-to-talk voice memo recording, an offline **WatermelonDB (over SQLite)** database encrypted with SQLCipher (AES-256), and on-device report preview/export.
2. **Companion Web Desktop Application — POST-MVP**:
   - Deferred beyond the MVP. When built: a secondary desktop web interface (React, sharing the monorepo's TypeScript packages) for in-office bulk document OCR analysis, multi-column loss quantification spreadsheets, and administrative oversight.
   - The "Responsive Desktop Web View" sections in the screen specifications are forward-looking design and are **not** MVP build targets.

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
|   - Local Encrypted Database: WatermelonDB over SQLite, SQLCipher AES-256         |
|   - Local Media File Store (Compressed, Watermarked Photos & Audio)               |
|   - Bi-Directional Sync Queue & Conflict Resolution (Field-Level Timestamp Merging)|
+-----------------------------------------------------------------------------------+
                                         | (Sync when connected)
                                         v
+-----------------------------------------------------------------------------------+
|                        BACKEND API & MICROSERVICES (GOLANG + GIN)                 |
|   - Go High-Performance REST/JSON API Engine (Gin Framework; no gRPC in MVP)      |
|   - Goroutine-Powered Concurrent Media Sync & Chunked Upload Pipeline            |
|   - Claim Pipeline State Machine & Audit Trail Engine (15 Stages)                 |
|   - Authoritative Server-Side Go Document Engine (DOCX compiler; final reports)   |
|   - PostgreSQL Database Layer (pgx Driver with Connection Pooling)               |
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

### 2.3 Confirmed Technology Stack (Decision Baseline — 2026-08-30)

| Concern | Decision |
| :--- | :--- |
| Product name | **SurvScribe** across all aspects — code, packages, UI, documentation, and the internal claim-reference prefix (`SS-YYYY-XXXXX`). |
| Mobile client (MVP) | **React Native (TypeScript)**, feature-first source layout. React Native 0.87.1 / React 19.2; `ios/` and `android/` are committed source (no Continuous Native Generation). Navigation via React Navigation v7. Build-time configuration via `react-native-dotenv`. (ADR-0011) |
| Mobile local database | **WatermelonDB** (reactive ORM over SQLite), encrypted with **SQLCipher (AES-256)**. |
| Desktop web | **Deferred to post-MVP.** |
| Backend | **Go (Golang) + Gin**, **REST/JSON**. gRPC is **out of scope for the MVP**. `pgx` + PostgreSQL. |
| `.docx` report engine | **Two engines, one shared template contract:** (a) a **client-side TypeScript engine** for offline PSR/FSR drafts on the mobile app; (b) an **authoritative server-side Go engine** for the final compiled report. The `< 5 s` / 50-photo-plate benchmark (§6.3) applies to the server engine. The two engines must produce equivalent output. |
| External integrations | Accessed through **provider-agnostic interfaces + config-driven adapters** (`AssistantService`, `NotificationService`, `GeocodingService`, …). Concrete vendors (cloud LLM, cloud OCR, SMS, email, WhatsApp, maps) are selected **per integration in an Architecture Decision Record** under `documentation/decisions/`, not fixed in this SRS. |
| Monorepo tooling | **pnpm workspaces + Turborepo** for the TypeScript packages (`apps/mobile`, future `apps/web`, `packages/*`). The Go backend keeps its own `go.mod` and is built separately. |
| Documentation root | Single root: **`documentation/`**. ADRs in `documentation/decisions/`; physical schema, API contract, and diagrams in `documentation/architecture/`. |
| Biometric unlock | **Deferred to post-MVP.** MVP offline re-entry uses a cached encrypted session token + device passcode only. |

---

## 3. End-to-End Functional Requirements (Auth & 15-Stage Workflow)

### Stage 0: Authentication, Registration & Mobile Access Gate (Screens 00_auth_login & 00_auth_signup)
- **FR-0.1 (Surveyor Sign In - Screen 00_auth_login)**: The system shall provide secure surveyor authentication supporting:
  - Universal Identifier (Email / Custom Username / Mobile Phone) + Password credentials with "Remember Me".
  - Mobile Phone Number + 6-digit SMS One-Time Password (OTP) with a **30-second** resend timer.
  - Work Email + 6-digit Email OTP verification modal with a **45-second** resend timer.
  - Password recovery and reset link dispatch.
  - Direct switch link to `00_auth_signup`.
- **FR-0.2 (Surveyor Registration / Sign Up - Screen 00_auth_signup)**: The system shall provide a dedicated onboarding screen capturing:
  - Full Legal Name, Surveyor Firm Name, Contact Number, Email Address (**mandatory**).
  - SLA / IRDAI License Number, License Category (*Fellow, Associate, Licentiate, Trainee*), and Operating Territory / Base Location — **all optional at signup**. The surveyor may use the full field workflow without them, but **Final Survey Report (FSR) generation is blocked until the License Number and Category are supplied** (required for the report sign-off block).
  - **Syntax / Format Validation Only**: When a license number is entered, the system shall validate that it conforms to expected alphanumeric format rules (e.g., regex pattern `SLA-[0-9]{4,8}`). The system shall explicitly document that this is syntax validation only and does not constitute regulatory license verification or endorsement.
  - **Mandatory Registration Disclaimer**: The registration screen shall display an explicit disclaimer: *"License details are provided by the user and are subject to independent verification. Platform registration does not constitute regulatory approval or endorsement."*
  - Secure Password creation with complexity meter and Terms of Service consent.
  - Direct switch link back to `00_auth_login`.
- **FR-0.3 (Offline Authentication & Security)**:
  - The mobile app shall securely cache an encrypted session token in hardware keystore / keychain.
  - When disconnected from cellular network, the surveyor shall authenticate via cached session token / device passcode to access cached claims.
  - Automatic session lock after 15 minutes of background inactivity.

### Stage 1: Receipt of Survey Appointment
- **FR-1.1**: The system shall allow creation of new survey assignments via manual form entry or smart extraction from insurer appointment letters (PDF/Email).
- **FR-1.2**: Mandatory Appointment Data Attributes:
  - `appointment_id`, `insurer_name`, `operating_office_division`, `insurer_claim_ref_no`, `appointment_date`.
  - `policy_number`, `insured_name`, `insured_phone`, `insured_email`, `representative_name_designation`.
  - `policy_risk_address`, `date_of_loss`, `time_of_loss`, `reported_nature_of_loss`, `preliminary_loss_estimate`.
  - `insurer_specific_instructions` (e.g., joint survey requirement, specific salvage guidelines, interim report deadlines).
- **FR-1.3**: The system shall assign an internal tracking reference in the format `SS-YYYY-XXXXX` (e.g., `SS-2026-00101`) and initialize the survey state machine at Stage 1. Offline-created claims receive a temporary `TEMP-SS-XXXX` identifier until synced.

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
- **FR-4.1**: The mobile app shall capture device GPS coordinates (Latitude, Longitude, Accuracy, Altitude, Timestamp) upon arrival at the survey site. **Accuracy handling**: a reading with accuracy radius **> 10 m** shall warn the surveyor and prompt a re-capture (target `≤ 10 m`); a reading with accuracy radius **> 50 m** is rejected and the surveyor cannot save the location capture (hard limit `≤ 50 m`).
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
- **FR-11.2**: Line-Item Mathematical Engine. Deductions are applied in this **strict order**:
  **Gross Assessed → less Depreciation → less Betterment → less Underinsurance → less Salvage → less Policy Excess = Net Recommended.**

  1. `Claimed Amount (₹)` — as claimed by the insured (reference only).
  2. `Gross Assessed / Reinstatement Cost (₹)` = `Assessed Quantity × Verified Unit Rate`.
  3. `Depreciation Deduction (₹)` = `Gross Assessed × (Depreciation % / 100)` (based on age, asset class, and standard surveyor depreciation scales).
  4. `Betterment Deduction (₹)` — New-for-Old adjustment.
  5. `Net of Depreciation (₹)` = `Gross Assessed − Depreciation Deduction − Betterment Deduction`.
  6. `Underinsurance / Average Clause Deduction (₹)` — **applied to the Net of Depreciation base**:
     $$\text{If } \text{Value at Risk (VAR)} > \text{Sum Insured (SI)} \implies \text{Underinsurance Deduction} = \text{Net of Depreciation} \times \left(1 - \frac{\text{SI}}{\text{VAR}}\right)$$
     (otherwise the deduction is `0`).
  7. `After Underinsurance (₹)` = `Net of Depreciation − Underinsurance Deduction`.
  8. `Salvage Value Realization (₹)` — deducted next (linked from Stage 12).
  9. `Policy Excess / Deductible (₹)` — deducted last (per policy terms: percentage of claim or fixed minimum).
  10. `Net Recommended Loss (₹)` = `After Underinsurance − Salvage − Policy Excess`.
- **FR-11.3**: Mandatory justification notes required for every rate reduction, depreciation rate, betterment, salvage figure, or disallowed claim item. Report finalization is blocked if any deduction line item has an empty justification remark.

### Stage 12: Salvage Verification & Disposal Management
- **FR-12.1**: The system shall track salvageable inventory (Description, estimated weight/quantity, condition, storage location).
- **FR-12.2**: The system shall support three disposal modes:
  - **Mode A (Retained by Insured)**: Agreed salvage value (percentage of assessed value or lump sum) deducted directly from the loss assessment; record the insured's consent.
  - **Mode B (Sold to Scrap Buyer)**: Record buyer details, quote amount, delivery confirmation, GST sale invoice, payment receipt, and realized cash value.
  - **Mode C (Tender floated by Insurer)**: Record the tender bids, highest bidder, sale proceeds invoice, and payment proof.
- **FR-12.3**: Salvage values feed directly into the Head-wise quantification sheet.

### Stage 13: Coverage and Liability Consideration (Decision Support)
- **FR-13.1 (Decision Support Architecture)**: The system shall provide structured decision-support analysis for surveyor review. The AI assistant and platform shall strictly assist the surveyor and shall NEVER make autonomous, binding liability decisions (e.g., the platform shall never autonomously declare "Claim Approved" or "Claim Rejected"):
  - Operative Peril evaluation (e.g., Short circuit vs. Overheating; Accidental Fire vs. Arson) connecting physical evidence to policy definitions.
  - Policy terms, exclusions, and warranty compliance review (e.g., Maintenance warranty, Fire fighting appliances warranty).
  - Identification of any breach or material fact requiring insurer special consideration.
- **FR-13.2 (Surveyor Recommendation & Disclaimer)**:
  - Surveyor recommendation status options: *Admissible as Assessed / Subject to Insurer Liability Determination / Non-Admissible / Repudiation Recommended*.
  - Every coverage remark and recommendation generated by or stored in the system shall explicitly bear the notice: *"Decision-support analysis for surveyor review. Final liability determination remains with the insurer."*

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
  - All AI narrative drafts require explicit human surveyor review, editing, and inline confirmation before report compilation.
- **FR-14.3**: **Editable Document Engine (`.docx`)**:
  - Compiles the complete FSR into a beautifully styled `.docx` file complete with header/footer, surveyor sign-off blocks, formatted calculation tables, high-resolution photo plates with captions, and standard Without Prejudice disclaimers.
- **FR-14.4**: **Mandatory AI Disclaimer & Human Approval Gate (Pre-Export)**:
  - Prior to enabling the `.docx` document generation or download for any PSR/FSR, the platform enforces a mandatory 4-point Human Approval Gate:
    1. `[x]` Surveyor has thoroughly reviewed all AI-generated narrative content and text.
    2. `[x]` Surveyor confirms factual accuracy of site observations, timelines, and damage items.
    3. `[x]` Surveyor confirms calculations, depreciation scales, and policy terms interpretation.
    4. `[x]` Final professional and legal responsibility for the survey report remains with the licensed surveyor.

### Stage 15: Internal Review, Pre-Submission Audit & Submission
- **FR-15.1**: **Automated Consistency Auditor — 7 Compliance Gates** (all must pass before submission is enabled):
  1. **Arithmetic Check** — Section F table totals match line-item sums exactly to the rupee.
  2. **Metadata Consistency** — Policy Number, Claim Number, Insured Name, and Date of Loss are identical across all 9 sections and every photo caption.
  3. **Deduction Remarks** — every rate cut, depreciation, betterment, and salvage deduction has a non-empty justification remark.
  4. **Photo Annexure Compliance** — every attached photo has a timestamp, GPS tag, and descriptive caption.
  5. **Document Completeness** — all mandatory documents for the reported peril are accounted for.
  6. **Contradiction Scanner** — no contradictory statements between Section C (Cause), Section D (Findings), and Section I (Opinion); no item marked "Repairable" in Stage 6 quantified as "Total Loss" in Stage 11.
  7. **Human Approval & AI Gate** — all 4 checkboxes of the Mandatory AI Review & Human Approval Gate are accepted, timestamped, and recorded in the immutable audit log.
- **FR-15.2**: Final sign-off record, report archiving, immutable **SHA-256** hash snapshot, and dispatch tracking log.

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

> **MVP release scope note (ADR-0009, Accepted):** "CORE" describes AI-4's role in the product vision, not its position in the MVP release gate. **AI-4 is a post-launch fast-follow, not an MVP blocker** — it is scheduled in `sprint_0014`, after every other stage. Stage 14 (`15_final_survey_report_generator`) must work completely with Sections C/D/H/I entered by the surveyor with no AI assist, as a tested MVP requirement in its own right.

### 4.2 Local / On-Device AI Architecture Strategy
The system encapsulates all AI operations behind unified Go (Backend) and TypeScript (Mobile Client) interfaces:

```go
// Go Backend AI Service Interface
type AssistantService interface {
    TranscribeAudio(ctx context.Context, audioReader io.Reader) (*TranscriptionResult, error)
    ExtractDocumentLineItems(ctx context.Context, docReader io.Reader) (*ExtractedTable, error)
    AuditClaimDiscrepancies(ctx context.Context, claim *ClaimAuditDataset) (*DiscrepancyReport, error)
    GenerateReportNarrative(ctx context.Context, section ReportSectionKey, ctxData *GroundedContext) (*NarrativeDraft, error)
}
```

```typescript
// Mobile Client AI Service Interface
interface IAssistantService {
  transcribeAudio(audioBlob: Blob): Promise<TranscriptionResult>;
  extractDocumentLineItems(documentFile: FileBlob): Promise<ExtractedDocumentTable>;
  auditClaimDiscrepancies(claimData: ClaimDataset): Promise<DiscrepancyReport>;
  generateReportNarrative(section: ReportSectionKey, context: GroundedContext): Promise<NarrativeDraft>;
}
```
- When network status is `ONLINE`, requests route to `CloudAssistantService` (invoking cloud LLM/OCR APIs with goroutines).
- When network status is `OFFLINE`, requests route to `LocalAssistantService` (integrating local on-device small models e.g., local Whisper STT).

**Provider-agnostic integration policy**: All third-party services are accessed through interfaces with config-driven adapters — not only `AssistantService` but also, at minimum, `NotificationService` (SMS OTP, transactional email, WhatsApp dispatch) and `GeocodingService` (reverse geocoding, distance variance for Stage 4). **Concrete vendors are not fixed in this SRS.** Each integration (cloud LLM, cloud OCR, SMS gateway, email service, WhatsApp, maps/geocoding) is selected in its own Architecture Decision Record under `documentation/decisions/`, with SMS OTP and transactional email prioritised because Stage 0 is the first build target.

### 4.3 Human-in-the-Loop Governance & AI Safeguards
- **Non-Autonomous Principle**: AI modules never autonomously dispatch reports, never approve/repudiate claims, and never make binding coverage determinations.
- **Mandatory Review & Gatekeeping**: Every narrative sentence, OCR-extracted invoice item, or depreciation calculation suggested by the system requires affirmative human interaction (edit, accept, or reject) by the licensed surveyor.
- **Deterministic Number Processing**: AI narrative components are forbidden from generating or altering numerical values independently. All monetary assessments are computed by the deterministic math engine.
- **Mandatory Export Disclaimers**: All generated `.docx` and exported summaries automatically embed the standard regulatory disclaimer stating that the report was compiled under the direct supervision and assessment of the licensed surveyor.

---

## 5. Data Model & RBAC-Ready Schema

### 5.1 RBAC Schema & Insurer Viewer Governance
All operational database entities include standard multi-tenant and role management columns:
- `store_id`: UUID (Surveyor firm / parent company — the tenancy boundary)
- `client_id`: UUID (The employee / user the record belongs to)
- `assigned_surveyor_id`: UUID (Field surveyor)
- `reviewer_id`: UUID (Senior surveyor / partner)
- `access_role_scope`: Enum (`['SURVEYOR', 'REVIEWER', 'ADMIN', 'INSURER_VIEWER']`)

> **Naming amended by ADR-0005 (D38).** The tenancy root is a **store** (`stores` table, `store_id` column), replacing the earlier `tenants` / `tenant_id`; the record's owning employee is the **client** (`client_id`), replacing `created_by_user_id`. There is one name for each — `tenant_id` and `created_by_user_id` are not retained as aliases.
>
> **Where the five columns apply.** "All entities" is qualified by ADR-0005: operational tables (claim-workflow entities and surveyor work product) carry all five; identity tables carry `store_id` and `client_id` where an owner exists; global catalogue tables such as `permissions` carry none; `stores` is the tenancy root and carries none. See `architecture/physical-schema.md` §1.

**Role-based access control** is implemented as a database-driven model — `roles`, `permissions`, `role_permissions`, `user_roles` — supporting multiple roles per user, four immutable seeded system roles, and store-defined custom roles composed from a code-defined permission catalogue. `access_role_scope` is retained as the denormalised primary role for display and compatibility; `user_roles` is authoritative for authorization. See ADR-0005 (D39) and `architecture/identity-and-rbac.md`.

#### Insurer Viewer Access & Data Governance Controls
To ensure regulatory compliance and maintain professional independence prior to enabling `INSURER_VIEWER` access:
1. **Explicit Surveyor / Firm Authorization**: Insurer access to any claim file requires affirmative grant by the assigned surveyor or survey firm admin.
2. **Claim-Level Granular Permissions**: Insurers are granted read-only access strictly scoped to individual assigned claims, never broad firm-wide access.
3. **Immutable Access & Audit Trails**: Every document view, download, or status inspection by an insurer user is recorded in an immutable audit log (Timestamp, User ID, Claim ID, Action).
4. **Data Ownership & Boundary Rules**: Claim survey files, draft notes, and unverified photos remain the exclusive work product of the surveyor until formally submitted.
5. **Contractual Data-Sharing Compliance**: Insurer portal access operates under bilateral data-sharing terms respecting confidentiality and applicable data protection regulations.

### 5.2 Core Entities Schema Definition
1. **`claims`**: `id`, `store_id`, `client_id`, `claim_ref_no`, `policy_no`, `insurer_name`, `insured_name`, `loss_date`, `peril`, `status`, `current_stage`, `created_at`, `updated_at`.
2. **`policy_details`**: `id`, `claim_id`, `policy_type`, `inception_date`, `expiry_date`, `sum_insured_total`, `excess_clause`, `warranties_json`.
3. **`site_visits`**: `id`, `claim_id`, `visit_no`, `visit_date`, `gps_lat`, `gps_lng`, `actual_location_address`, `location_discrepancy_flag`.
4. **`cause_investigations`**: `id`, `claim_id`, `incident_datetime`, `discovery_datetime`, `reported_cause`, `sequence_of_events`, `fir_details`, `fire_report_details`.
5. **`damage_items`**: `id`, `claim_id`, `head_category`, `description`, `make_model_serial`, `qty`, `uom`, `damage_extent`, `repair_or_replace`, `pre_existing_damage`.
6. **`media_attachments`**: `id`, `claim_id`, `damage_item_id`, `file_uri`, `thumbnail_uri`, `media_type`, `category_tag`, `gps_lat`, `gps_lng`, `timestamp`, `caption`.
7. **`documents`**: `id`, `claim_id`, `doc_type`, `file_name`, `file_uri`, `ocr_status`, `ocr_data_json`, `verified_flag`.
8. **`assessment_line_items`**: `id`, `claim_id`, `head_category`, `description`, `claimed_amount`, `assessed_gross`, `depreciation_pct`, `depreciation_amount`, `betterment_amount`, `salvage_amount`, `underinsurance_deduction`, `excess_deduction`, `net_recommended`, `justification_remarks`.
9. **`salvage_records`**: `id`, `claim_id`, `description`, `qty_weight`, `disposal_mode`, `buyer_info`, `realized_amount`.
10. **`final_survey_reports`**: `id`, `claim_id`, `section_a_json` ... `section_i_json`, `docx_file_uri`, `generated_at`, `status`.

#### Additional Entities (Decision Baseline 2026-08-30 — draft, pending detailed schema review)

The 15-stage workflow requires the following entities beyond the 10 above. Field lists are indicative; the finalised physical schema (types, PK/FK, indexes, enum value lists, JSON shapes) is produced in `documentation/architecture/`.

11. **`users`** (the client / employee — **finalised, ADR-0005**): `id` *(this is the `client_id` referenced elsewhere)*, `store_id`, `full_name`, `email`, `mobile`, `username` (nullable), `password_hash` (nullable — OTP-only accounts), `password_algo`, `password_updated_at`, `sla_license_no` (nullable), `sla_category` (nullable enum `Fellow|Associate|Licentiate|Trainee`), `base_location` (nullable), `signature_uri`, `access_role_scope` (enum), `permissions_version`, `status` (enum `PENDING_VERIFICATION|ACTIVE|SUSPENDED|DEACTIVATED`), `email_verified_at`, `mobile_verified_at`, `terms_accepted_at`, `terms_version`, **signup provenance** (`signup_source`, `invited_by_user_id`, `invite_id`, `signup_ip`, `signup_user_agent`, `signup_device_id`, `signup_platform`, `signup_app_version`, `signup_country_code`, `signup_region`, `signup_city`, `signup_asn`, `signup_isp`, `signup_timezone`), **login state** (`last_login_at`, `last_login_ip`, `last_login_user_agent`, `last_login_device_id`, `previous_login_at`, `previous_login_ip`, `last_seen_at`, `login_count`), **logout & lockout** (`last_logout_at`, `last_logout_reason`, `failed_login_count`, `last_failed_login_at`, `locked_until`), `created_at`, `updated_at`, `deleted_at`. Identifier uniqueness (`email`, `mobile`, `username`) is **global**, not per-store — required by universal-identifier login (ADR-0005 D43).
12. **`stores`** (the surveyor firm / parent company — **renames `tenants`, ADR-0005 D38**): `id`, `firm_name` (deliberately not unique), `legal_name`, `firm_type` (enum `SOLE_PROPRIETORSHIP|PARTNERSHIP|LLP|PRIVATE_LIMITED|OTHER`), `owner_user_id`, `status`, `letterhead_config_json`, `default_claim_ref_prefix` (default `SS`), `primary_contact_email`, `primary_contact_phone`, `registered_address`, `created_at`, `updated_at`, `deleted_at`.
13. **`sessions`** (**finalised, ADR-0005 D41**): `id`, `user_id`, `store_id`, `device_id`, `device_name`, `device_platform`, `app_version`, `os_version`, **`refresh_token_hash`** *(Argon2id — renamed from `encrypted_token_ref`; ADR-0003 §1 requires hashing, not reversible encryption)*, `refresh_token_family_id`, `rotated_from_session_id`, `issued_at`, `expires_at`, `last_used_at`, `last_refreshed_at`, `offline_grace_until`, `remember_device`, `created_ip`, `created_user_agent`, `created_country_code`, `created_region`, `created_city`, `last_ip`, `status` (enum `ACTIVE|LOGGED_OUT|EXPIRED|REVOKED|SUPERSEDED`), `logout_at`, `revoked_at`, `revoked_by_user_id`, `revoke_reason`, `created_at`, `updated_at`. Multi-device is supported: one `ACTIVE` session per `(user_id, device_id)`.
14. **`audit_log`** (immutable, append-only): `id`, `store_id`, `claim_id` (nullable), `actor_user_id`, `entity`, `entity_id`, `field`, `old_value`, `new_value`, `action`, `occurred_at`. Records every change to loss-assessment figures and every insurer file view/download.
15. **`sync_queue`**: `id`, `device_id`, `entity`, `entity_local_id`, `operation` (create/update/delete), `payload_json`, `media_refs`, `attempt_count`, `next_retry_at`, `conflict_flag`, `status`.
16. **`contact_logs`** (Stage 3): `id`, `claim_id`, `contacted_at`, `contact_person`, `phone`, `channel`, `outcome` (enum `Connected|Busy|Site Confirmed|...`), `notes`.
17. **`follow_up_visits`** (Stage 9): `id`, `claim_id`, `visit_number` (≥ 2), `visit_date`, `purpose` (enum), `persons_attended`, `detailed_findings`, `stock_reconciliation_json`. (May be modelled as an extension of `site_visits` — resolved during schema drafting.)
18. **`coverage_opinions`** (Stage 13): `id`, `claim_id`, `operative_peril_status` (enum), `peril_justification`, `warranty_compliance_json`, `exclusions_json`, `surveyor_recommendation` (enum `Admissible as Assessed|Subject to Insurer Liability Determination|Non-Admissible|Repudiation Recommended`), `surveyor_opinion_text`.
19. **`requisition_notices`** (Stage 8): `id`, `claim_id`, `peril_preset`, `required_docs_json`, `custom_requirements`, `due_date`, `dispatch_channel`, `dispatched_at`.
20. **`preservation_notices`** (Stage 3): `id`, `claim_id`, `template_version`, `custom_instructions`, `dispatch_channel`, `dispatched_at`. *(Candidate — confirm during schema drafting; may be folded into `contact_logs` or `documents`.)*

#### Identity, RBAC & Auth Telemetry Entities (finalised 2026-08-30 — ADR-0005)

Unlike entities 11–20 above, the following are **not draft**. Their complete DDL — types, PK/FK, indexes, partial unique indexes, `CHECK` constraints and enum value lists — is specified in [`architecture/physical-schema.md`](architecture/physical-schema.md), together with the finalised forms of entities 11, 12 and 13.

21. **`permissions`** (seeded catalogue, never written at runtime): `id`, `code` (`resource:action`, e.g. `claim:read`), `resource`, `action`, `description`, `is_assignable`, `created_at`. ~35 codes across store, user, role, claim, evidence, document, assessment, salvage, coverage-opinion, report, audit, AI and insurer groups.
22. **`roles`**: `id`, `store_id` (NULL ⇒ immutable global system role), `code`, `name`, `description`, `is_system`, `created_at`, `updated_at`, `deleted_at`. Four seeded system roles (`SURVEYOR`, `REVIEWER`, `ADMIN`, `INSURER_VIEWER`); stores may define custom roles composed only from the seeded permission catalogue.
23. **`role_permissions`**: `role_id`, `permission_id`, `created_at` (composite PK).
24. **`user_roles`**: `user_id`, `role_id` (composite PK), `store_id`, `granted_by_user_id`, `granted_at`, `expires_at`, `revoked_at`, `revoke_reason`. A user may hold multiple roles.
25. **`claim_access_grants`** (implements §5.1 insurer governance rule 2): `id`, `store_id`, `claim_id`, `grantee_user_id`, `granted_by_user_id`, `scope`, `granted_at`, `expires_at`, `revoked_at`, `revoked_by_user_id`, `revoke_reason`. Holding `insurer:claim:read` is necessary but **not sufficient** — a live grant for that specific claim is also required, and every read under a grant writes an `audit_log` row.
26. **`user_devices`**: `id`, `user_id`, `store_id`, `device_id`, `device_name`, `platform`, `model`, `os_version`, `app_version`, `push_token`, `is_trusted`, `first_seen_at`, `last_seen_at`, `revoked_at`, `revoke_reason`. Stable device identity across sessions; the anchor for remote revoke.
27. **`auth_events`** (immutable, append-only — enforced by trigger *and* `REVOKE UPDATE, DELETE`): `id` (BIGSERIAL), `store_id` (nullable), `user_id` (nullable), `session_id` (nullable), `event_type` (22 values covering signup, login success/failure, OTP, token refresh and reuse, logout, revocation, password changes, lockout, role grants, invites, offline unlock/expiry), `outcome`, `auth_method`, `failure_reason`, `identifier_attempted_hash` (SHA-256 — a failed login may name a non-existent account, so the raw identifier is never stored), `ip_address`, `user_agent`, `device_id`, `device_platform`, `app_version`, `country_code`, `region`, `city`, `asn`, `isp`, `timezone`, `occurred_at`. Deliberately **separate from `audit_log`**: different shape, cardinality, retention and audience.
28. **`store_invites`** (the only path into an existing store — ADR-0005 D40): `id`, `store_id`, `email`, `mobile`, `role_id`, `invited_by_user_id`, `token_hash` (SHA-256), `status` (enum `PENDING|ACCEPTED|EXPIRED|REVOKED`), `expires_at`, `accepted_at`, `accepted_user_id`, `revoked_at`, `revoked_by_user_id`, `created_ip`, `created_user_agent`, `created_at`, `updated_at`.
29. **`otp_challenges`** *(defined now, wired in the OTP sprint)*: `id`, `user_id` (nullable), `channel` (`SMS|EMAIL`), `purpose` (`LOGIN|SIGNUP_VERIFY|PASSWORD_RESET`), `destination_hash`, `code_hash` (Argon2id — never the plain code), `attempt_count`, `max_attempts`, `resend_available_at` (SMS 30 s / email 45 s per D33), `expires_at`, `consumed_at`, `request_ip`, `request_user_agent`, `created_at`.
30. **`password_reset_tokens`** *(defined now, wired when the email vendor is live)*: `id`, `user_id`, `token_hash` (SHA-256), `expires_at`, `consumed_at`, `request_ip`, `request_user_agent`, `created_at`.

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
