# Screen Specification: 03_policy_coverage_review

## 1. Screen Objective & Context
- **Screen Name**: Policy Coverage & Terms Review
- **Stage Mapping**: Stage 2 of 15 (Preliminary Review of Policy and Claim Intimation)
- **Purpose**: Enables recording, verification, and AI-assisted analysis of the insurance policy schedule, section-wise sums insured, operative perils, policy deductibles/excess, warranties, and special endorsements before proceeding to site inspection.

---

## 2. Layout & UI Architecture

### 2.1 Desktop Web Layout
- **Split Screen**:
  - **Left Pane (45% width)**: Policy Document Viewer (Multi-page PDF viewer with search, zoom, and clause highlighter).
  - **Right Pane (55% width)**: Tabbed Policy Schedule & Terms Breakdown:
    - *Tab 1: Basic Coverage & Validity*
    - *Tab 2: Section-Wise Sums Insured (Priced Breakdown)*
    - *Tab 3: Deductibles, Warranties & Endorsements*
    - *Tab 4: Claim Intimation & Estimate*

### 2.2 Mobile App Layout (iOS & Android)
- **Stacked Tabbed Form**:
  - Policy summary card at top (Policy Type, Validity status: *Active / Expired*).
  - Collapsible cards for *Sums Insured by Section*, *Policy Excess Rules*, *Key Warranties*, and *Claim Intimation*.
  - Floating "View Original Policy PDF" viewer button.

---

## 3. Detailed UI Component Hierarchy
1. **Header & Context Bar**:
   - `ClaimBanner` (Claim Ref ID, Insured Name, Reported Peril)
   - `PolicyValidityStatusTag` (Green: Valid, Red: Expired/Disputed)
2. **Policy Structure Form**:
   - **Tab 1: Coverage Basics**
     - `PolicyTypeSelect` (SFSP, IAR, Burglary, Machinery Breakdown, Electronic Equipment, Marine Cargo)
     - `InceptionDateInput` & `ExpiryDateInput`
     - `HypothecationBankInput` (Bank / Financial Institution name)
   - **Tab 2: Sums Insured Grid**
     - `DynamicSumInsuredTable`: Rows for *Building*, *Plant & Machinery*, *Furniture/Fixtures/Fittings*, *Raw Materials*, *Stock in Process*, *Finished Goods*, *Stock in Open*.
     - Columns: `Head Category`, `Description`, `Sum Insured (₹)`, `Basis (RIV / Market Value)`.
     - `TotalSumInsuredFooter` (Auto-summed ₹).
   - **Tab 3: Deductibles & Warranties**
     - `ExcessClauseInput` (e.g., "5% of claim amount subject to minimum ₹25,000")
     - `WarrantyChecklist` (Dynamic tags: *Silent Risk Warranty, Fire Extinguishing Appliances Warranty, Good Housekeeping, 24-Hr Watchman*).
     - `SpecialClausesInput` (e.g., Escalation clause 10%, Designation of property, 72-hour clause).
   - **Tab 4: Claim Intimation Particulars**
     - `IntimationDateInput`
     - `InsuredClaimBillAmountInput` (₹)
     - `IntimationNotesTextarea`

---

## 4. Data Fields, Types & Validations

| Field | Type | Mandatory | Validation Rules | Description |
| :--- | :--- | :--- | :--- | :--- |
| `policy_type` | Enum | Yes | Standard policy classifications | Class of general insurance policy |
| `inception_date` | Date | Yes | Valid date | Start date of policy coverage |
| `expiry_date` | Date | Yes | Must be $\ge$ `inception_date` | Expiry date of policy coverage |
| `date_of_loss_check` | Computed | Yes | Must fall within Inception & Expiry | Flags error if loss is outside policy period |
| `sum_insured_heads` | Array<Object>| Yes | At least one head with Sum Insured $> 0$ | Section-wise insured amounts |
| `excess_deductible` | String | Yes | Min 5 chars | Policy excess clause text |

---

## 5. AI Assistant Integration & Triggers
- **Policy Schedule Extraction (AI-2)**: Extracts Section-wise Sums Insured table directly from uploaded policy schedule PDF and maps to table rows.
- **AI Peril & Warranty Matcher (AI-3)**: Compares reported peril from Stage 1 against policy inclusions and highlights:
  - *Applicable Perils* (e.g., "Flood, Inundation, Storm is covered under SFSP Item VI").
  - *Applicable Warranties* (e.g., "Warning: Plinth level warranty applies to stock in ground floor storage").
  - *Excess Applicable* (e.g., "Standard AOG excess of 5% applies").

---

## 6. Offline State & Sync Indicators
- All policy figures, sums insured, and deductible clauses are cached in SQLite for offline field access.
- Changes made offline are marked with a local timestamp.

---

## 7. Action Triggers & Navigation
- **Click "Save & Proceed to Insured Contact"**: Validates dates and sums insured, advances state machine to Stage 3 (`04_insured_contact_schedule`).
- **Click "Export Policy Brief"**: Exports a 1-page summary PDF/Docx of policy terms for field surveyor reference.
