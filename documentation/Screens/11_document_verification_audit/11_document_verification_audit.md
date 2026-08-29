# Screen Specification: 11_document_verification_audit

## 1. Screen Objective & Context
- **Screen Name**: Document Verification & Forensic Claim Audit
- **Stage Mapping**: Stage 10 of 15 (Verification of Claim Documents)
- **Purpose**: Centralized desk audit workspace. Cross-checks received claim bills, repair estimates, purchase invoices, and stock records against physical survey findings and policy coverage. Employs OCR line-item extraction and AI forensic cross-checking to detect duplicate claims, unlisted items, inflated labor/material rates, obsolete inventory, and betterment elements.

---

## 2. Layout & UI Architecture

### 2.1 Primary Mobile App View (iOS & Android) - Core Mobile Experience
- **Mobile Forensic Audit Reviewer**:
  - Top Document Selector Pills (Claim Bill, Repair Estimate, Original Invoices).
  - Floating Discrepancy Alert Banner (e.g., "⚠️ 3 Potential Rate/Duplicate Discrepancies Detected").
  - Card-by-Card line item review with swipe gestures: *Accept Rate*, *Flag Rate Inflation*, *Disallow Item*.
  - Inline voice memo button to record disallowance remarks on mobile.
  - Bottom Action Sheet: "Proceed to Loss Quantification Matrix".

### 2.2 Responsive Desktop Web View
- **Three-Pane Forensic Audit Workspace**:
  - **Left Pane (30% width)**: Claim Bill & Invoice Document List with OCR status chips (Processed / Discrepancy Flagged / Verified).
  - **Middle Pane (45% width)**: Side-by-Side Line Item Cross-Check Grid (Claimed Line Item vs. Supporting Purchase Invoice vs. Physical Damage Register).
  - **Right Pane (25% width)**: AI Discrepancy Inspector & Betterment / Rate Variance Flag Panel.

---

## 3. Detailed UI Component Hierarchy
1. **Document Selector & OCR Intake**:
   - `UploadedDocumentsList`: Displays Claim Bills, Contractor Quotations, Purchase Invoices, Stock Sheets.
   - `OCRReprocessButton` (Re-triggers line-item OCR if needed).
2. **Line-Item Forensic Reconciliation Grid**:
   - `ClaimLineItemTable`:
     - Columns: `Item Description`, `Claimed Qty`, `Claimed Rate (₹)`, `Claimed Total (₹)`, `Matching Purchase Invoice #`, `Original Purchase Rate (₹)`, `Rate Variance (%)`, `Physical Item Match`, `Audit Status`.
     - `AuditStatusDropdown` (*Fully Verified, Inflated Rate, Duplicate Item, Un-Insured Item, Pre-Damaged, Betterment*).
     - `SurveyorAuditRemarks` (Mandatory note for any flagged item).
3. **AI Forensic Audit & Anomaly Panel**:
   - `DuplicateClaimAlertCard`: Highlights identical part numbers or serial numbers claimed across multiple invoices.
   - `RateInflationCard`: Highlights items where claimed repair/replacement rate exceeds original purchase price by $> 20\%$.
   - `BettermentDetectorCard`: Highlights items where newer/higher capacity specification is claimed (e.g., replacing 10HP motor with 25HP motor).
   - `UnverifiedPhysicalItemCard`: Highlights claim bill items with no matching entry in Stage 6 physical damage register.

---

## 4. Data Fields, Types & Validations

| Field | Type | Mandatory | Validation Rules | Description |
| :--- | :--- | :--- | :--- | :--- |
| `claim_item_description`| String | Yes | Min 3 chars | Description from insured's claim bill |
| `claimed_quantity` | Float | Yes | $> 0$ | Quantity claimed by insured |
| `claimed_unit_rate` | Currency (₹) | Yes | Numeric $\ge 0$ | Rate claimed per unit |
| `audit_status` | Enum | Yes | Standard audit status codes | Surveyor's forensic classification |
| `rate_variance_pct` | Float | Computed | Auto-calculated | % difference vs original invoice rate |
| `betterment_flag` | Boolean | Yes | Boolean | Indicates upgraded replacement |
| `audit_deduction_reason`| Text | Conditional | Mandatory if `audit_status != Verified` | Rationale for disallowance |

---

## 5. AI Assistant Integration & Triggers
- **OCR Line-Item Extractor (AI-2)**: Automatically parses multi-page PDF repair estimates and claim bills into tabular line items with quantities, rates, and totals.
- **Cross-Checking & Discrepancy Detector (AI-3)**:
  - Compares Claim Bill item descriptions against Stage 6 Damage Item Register using fuzzy text matching.
  - Compares Claim Bill rates against Stage 8 Purchase Invoices.
  - Highlights duplicate bill items, unlisted consumables, and obsolete items.
- **Discrepancy Synthesis Drafter (AI-4)**: Drafts a comprehensive forensic findings narrative for FSR Section H (*Discrepancies, Irregularities & Material Observations*).

---

## 6. Offline State & Sync Indicators
- All OCR extracted tables and surveyor audit marks are cached locally for offline review.
- Audit notes save instantly to local SQLite database.

---

## 7. Action Triggers & Navigation
- **Click "Save & Proceed to Loss Assessment Matrix"**: Pushes verified claim items and disallowed deductions into Stage 11 (`12_loss_assessment_quantification`).
- **Click "Export Audit Discrepancy Sheet"**: Generates a detailed audit variance Excel/Docx sheet for discussion with the insured.
