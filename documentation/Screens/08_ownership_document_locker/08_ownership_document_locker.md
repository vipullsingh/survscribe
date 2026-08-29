# Screen Specification: 08_ownership_document_locker

## 1. Screen Objective & Context
- **Screen Name**: Ownership & Insurable Interest Document Locker
- **Stage Mapping**: Stage 7 of 15 (Verification of Ownership and Insurable Interest)
- **Purpose**: Verifies and establishes that the damaged property belonged to the insured, was in active possession at the insured risk location, existed prior to the incident, and falls under the scope of the policy. Manages purchase invoices, asset registers, stock statements, GST records, and bank hypothecation documents.

---

## 2. Layout & UI Architecture

### 2.1 Primary Mobile App View (iOS & Android) - Core Mobile Experience
- **Mobile Document Checklist & Scanner**:
  - Checklist cards for each ownership verification requirement (*Purchase Invoices*, *Asset Register*, *Stock Books*, *Bank Statements*).
  - Multi-page document scanner using device camera to quickly snap physical invoice copies.
  - Quick-link sheet connecting captured invoices directly to Stage 6 damage items.
  - Ownership Verification Status Toggle (*Established / Under Verification / Incomplete Documentation / Disputed*).
  - Bottom CTA: "Confirm Ownership & Next: PSR".

### 2.2 Responsive Desktop Web View
- **Two-Column Master-Audit Layout**:
  - **Left Pane (40% width)**: Structured Ownership Document Repository organized by folders (Purchase Invoices, FAR, Stock Registers, Bank Statements, AMC Records).
  - **Right Pane (60% width)**: Document Viewer & Ownership Checklist Verification Matrix linking documents directly to damage items cataloged in Stage 6.

---

## 3. Detailed UI Component Hierarchy
1. **Document Category Tabs & Upload Manager**:
   - `DocCategoryTabs` (Invoices, Asset Register, Stock Records, Bank Statements, GST Returns)
   - `DocumentDropzone` (Supports multi-file PDF, JPEG, PNG, TIFF)
   - `DocumentThumbnailGrid` (With file size, upload timestamp, and OCR status badge)
2. **Document Viewer & Data Linker**:
   - `InteractivePDFViewer` (With zoom, rotate, text selection)
   - `AssetLinkageSelector` (Links active document to one or more Damage Items from Stage 6)
3. **Insurable Interest Verification Checklist**:
   - `PossessionAtLossTimeCheckbox` ("Property was in physical possession at insured premises")
   - `PriorExistenceCheckbox` ("Property existed prior to loss, verified via purchase/maintenance records")
   - `PolicyScheduleCoverageCheckbox` ("Property falls under designated policy heads")
   - `HypothecationStatusSelect` (*No Hypothecation / Hypothecated to Bank / Leased Equipment*)
   - `BankNameInput` & `BankBranchInput`
4. **Ownership Verification Summary**:
   - `InsurableInterestStatusSelect` (*Established / Under Verification / Incomplete Documentation / Disputed*)
   - `OwnershipRemarksTextarea` (Detailed notes for FSR Section D/E)

---

## 4. Data Fields, Types & Validations

| Field | Type | Mandatory | Validation Rules | Description |
| :--- | :--- | :--- | :--- | :--- |
| `document_type` | Enum | Yes | Standard document classifications | Type of ownership proof |
| `invoice_number` | String | Conditional | Mandatory for Purchase Invoices | Original vendor bill number |
| `invoice_date` | Date | Conditional | Cannot be later than date of loss | Original asset purchase date |
| `vendor_name` | String | Conditional | Min 3 chars | Supplier / manufacturer name |
| `linked_damage_item_ids`| Array<UUID> | Yes | At least one item linked | Relates proof to physical damage |
| `insurable_interest_status`| Enum | Yes | `Established` / `Under Verification` / `Incomplete Documentation` / `Disputed` | Surveyor’s formal finding |
| `hypothecation_details`| Text | No | Max 200 chars | Bank charge or lease details |

---

## 5. AI Assistant Integration & Triggers
- **Invoice Metadata OCR (AI-2)**: Automatically extracts Vendor Name, GSTIN, Invoice Number, Invoice Date, Line Item Descriptions, and Total Amount from scanned bills.
- **Pre-Loss Purchase Date Verification**: AI validates that the invoice date precedes the reported Date of Loss and calculates the exact asset age (years/months) for accurate depreciation computation in Stage 11.
- **Insurable Interest Summary Drafter (AI-4)**: Drafts a factual ownership statement for FSR Section E (*Documents Considered & Ownership Findings*).

---

## 6. Offline State & Sync Indicators
- Documents photographed or stored on device are cached locally in encrypted storage.
- Document metadata and checklist entries persist offline in SQLite.

---

## 7. Action Triggers & Navigation
- **Click "Save & Proceed to PSR Generator"**: Validates checklist completion, advancing to Stage 8 (`09_preliminary_survey_report_psr`).
- **Click "Mark Ownership Established"**: Updates claim metadata status to `OWNERSHIP_VERIFIED`.
