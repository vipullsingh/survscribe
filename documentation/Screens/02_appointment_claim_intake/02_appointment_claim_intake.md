# Screen Specification: 02_appointment_claim_intake

## 1. Screen Objective & Context
- **Screen Name**: Survey Appointment & Claim Intake
- **Stage Mapping**: Stage 1 of 15 (Receipt of Survey Appointment)
- **Purpose**: Facilitates recording and parsing new surveyor appointments from insurance companies. Captures insurer instructions, policy basics, insured contact details, loss date, and preliminary loss estimates to establish the survey record.

---

## 2. Layout & UI Architecture

### 2.1 Primary Mobile App View (iOS & Android) - Core Mobile Experience
- **Mobile Intake Flow**:
  - Top: "Scan Appointment Letter" prominent camera card (opens camera to scan physical paper letter or pick PDF from mobile files).
  - OCR Processing progress bottom sheet with live extraction chips.
  - Stepped touch-friendly accordion cards:
    1. *Insurer Particulars*
    2. *Policy & Insured Basics* (with one-tap phone/WhatsApp link icons)
    3. *Loss Particulars* (with native Date/Time pickers)
    4. *Insurer Specific Instructions*
  - Sticky bottom action bar: "Save & Next: Policy Review" with offline badge indicator.

### 2.2 Responsive Desktop Web View
- **Two-Column Master-Detail Layout**:
  - **Left Pane (40% width)**: Document Intake Dropzone (Drag-and-drop insurer appointment letter PDF/Email/Image) with live OCR extraction status and preview.
  - **Right Pane (60% width)**: Structured Multi-Section Form pre-filled by OCR parser with edit/confirmation controls.
- **Top Actions**: "Save Draft", "AI Auto-Extract", "Save & Proceed to Policy Review".

---

## 3. Detailed UI Component Hierarchy
1. **Intake Document Uploader**:
   - `FileDropzone` (Accepts PDF, JPG, PNG, DOCX)
   - `OCRProgressIndicator` (Extracting text $\rightarrow$ Mapping fields $\rightarrow$ Ready for review)
   - `DocumentViewer` (Zoomable pane with highlighted bounding boxes)
2. **Form Sections**:
   - **Section 1: Appointment & Insurer Details**
     - `InsurerSelect` (Dropdown of standard insurers e.g., New India, ICICI Lombard, Bajaj Allianz, Tata AIG, HDFC ERGO)
     - `OperatingOfficeInput` (Division / Branch Code)
     - `InsurerClaimNoInput`
     - `AppointmentDateInput`
   - **Section 2: Policy & Insured Identification**
     - `PolicyNoInput`
     - `InsuredNameInput` (Legal entity or individual)
     - `ContactPersonInput` & `DesignationInput`
     - `PhoneInput` (With direct call/WhatsApp icon) & `EmailInput`
   - **Section 3: Risk & Loss Fundamentals**
     - `PolicyRiskAddressInput` (Full address as stated in policy)
     - `DateOfLossPicker` & `TimeOfLossPicker`
     - `ReportedPerilSelect` (Fire, Flood, Inundation, Storm, Burglary, Machinery Breakdown, Earth Movement, etc.)
     - `PreliminaryEstimatedLossInput` (Numeric ₹)
   - **Section 4: Mandate & Special Instructions**
     - `SpecialInstructionsTextarea` (e.g., "Joint inspection with forensic expert required", "Verify stock hypothecation with SBI bank")
     - `UrgencyTag` (Normal, Urgent, Catastrophic/CAT Event)

---

## 4. Data Fields, Types & Validations

| Field | Type | Mandatory | Validation Rules | Description |
| :--- | :--- | :--- | :--- | :--- |
| `insurer_name` | String / Enum | Yes | Must match insurer list or custom | Appointing insurance company |
| `insurer_claim_ref` | String | Yes | Alphanumeric, max 50 chars | Insurer's internal claim number |
| `appointment_date` | Date | Yes | Cannot be in the future | Date surveyor received appointment |
| `policy_number` | String | Yes | Alphanumeric, min 6 chars | Insurance policy number |
| `insured_name` | String | Yes | Min 3 chars | Full legal name of insured |
| `insured_phone` | String | Yes | 10 digits (India format +91) | Primary contact number |
| `date_of_loss` | Date | Yes | Cannot be later than appointment date | Occurrence date |
| `reported_peril` | Enum | Yes | Selected from standard peril master | Initial reported cause/peril |
| `estimated_loss` | Currency (₹) | No | Non-negative numeric | Initial estimate given by insured |

---

## 5. AI Assistant Integration & Triggers
- **Smart Appointment Letter Parser (AI-2)**:
  - When an appointment PDF is dropped, the AI extracts Insurer, Claim No, Policy No, Insured Name, Date of Loss, and Risk Address.
  - Extracted fields are highlighted in green with a confidence chip (e.g., "98% Confidence"). Clicking the field highlights the source text in the PDF.
- **Duplicate Claim Warning**: AI automatically checks database for matching Policy No and Loss Date to prevent duplicate survey file creation.

---

## 6. Offline State & Sync Indicators
- Full offline form creation supported. Form saves locally to SQLite with status `STATUS_DRAFT_OFFLINE`.
- Uploaded appointment documents are stored in local encrypted cache until connection is restored.

---

## 7. Action Triggers & Navigation
- **Click "Save & Proceed to Policy Review"**: Validates all mandatory fields, generates Survey ID (`SS-YYYY-XXXXX`), and routes to `03_policy_coverage_review`.
- **Click "Save Draft"**: Saves current state and returns to `01_dashboard`.
