# Screen Specification: 13_salvage_disposal_manager

## 1. Screen Objective & Context
- **Screen Name**: Salvage Verification & Disposal Management
- **Stage Mapping**: Stage 12 of 15 (Salvage Verification and Disposal)
- **Purpose**: Facilitates the identification, quantification, segregation, valuation, and disposal of salvageable remnants and scrap. Records tender bids, buyer details, sale invoices, and payment receipts, or computes agreed salvage value if retained by the insured. Directly links realized salvage deductions to the loss assessment.

---

## 2. Layout & UI Architecture

### 2.1 Desktop Web Layout
- **Two-Column Salvage Hub**:
  - **Left Pane (50% width)**: Salvage Inventory & Segregation Register (Item description, scrap weight/quantity, condition, storage location, estimated scrap value).
  - **Right Pane (50% width)**: Salvage Disposal Mode & Buyer Tender Manager (Tender quotations, highest bidder details, sale proceeds invoice, GST payment proof).
- **Bottom Summary**: Total Salvage Realization Banner with one-click "Sync to Assessment Matrix" button.

### 2.2 Mobile App Layout (iOS & Android)
- **Mobile Salvage Tracker**:
  - Top: Salvage Disposal Mode Toggle (*Retained by Insured* vs. *Sold via Tender*).
  - Salvage Item Cards with photo capture for scrap piles, weight slips, and buyer receipts.
  - Quick Salvage Value calculator (Weight $\times$ Scrap Rate/Kg).

---

## 3. Detailed UI Component Hierarchy
1. **Salvage Inventory Grid**:
   - `AddSalvageItemButton`
   - `SalvageItemTable`:
     - `ItemDescriptionInput` (e.g., "Burnt copper wire scrap from 5 motors")
     - `EstimatedQuantityWeightInput` (e.g., "450 Kgs")
     - `ScrapConditionSelect` (*Burnt Scrap, Water-Damaged Usable Material, Seconds Quality, Obsolete Remnants*)
     - `StorageLocationInput` (e.g., "Segregated in Yard Bay 4")
     - `PhotoProofButton` (Attach photo of scrap/weighment slip)
2. **Disposal Mode & Buyer Manager**:
   - `DisposalModeSelect` (*Mode A: Retained by Insured / Mode B: Sold to Scrap Buyer / Mode C: Tender floated by Insurer*)
   - **If Retained by Insured**:
     - `AgreedSalvagePercentage` (% of assessed value) or `AgreedLumpSumSalvage` (₹)
     - `InsuredConsentLetterUpload`
   - **If Sold to Buyer / Tender**:
     - `BuyerNameInput` & `BuyerContactInput`
     - `TenderQuotationsGrid` (List of bidders and quote amounts)
     - `SaleInvoiceNumberInput` & `InvoiceAmountInput` (₹)
     - `GSTInvoiceUpload` & `PaymentReceiptUpload`
3. **Salvage Assessment Linkage**:
   - `NetSalvageRealizationDisplay` (₹ Auto-summed)
   - `AutoDeductCheckbox` ("Apply salvage deduction to Loss Assessment Section F").

---

## 4. Data Fields, Types & Validations

| Field | Type | Mandatory | Validation Rules | Description |
| :--- | :--- | :--- | :--- | :--- |
| `salvage_description` | String | Yes | Min 5 chars | Description of salvageable items |
| `quantity_weight` | Float | Yes | $> 0$ | Weight or piece count |
| `disposal_mode` | Enum | Yes | Retained / Buyer / Tender | Disposal mechanism |
| `salvage_value` | Currency (₹) | Yes | Numeric $\ge 0$ | Value realized or agreed |
| `buyer_name` | String | Conditional | Mandatory for Buyer sale | Name of salvage purchaser |
| `payment_proof` | File Attachment | Conditional | Mandatory for Buyer sale | Cheque / RTGS / Cash receipt |

---

## 5. AI Assistant Integration & Triggers
- **Market Scrap Rate Estimator**: AI references standard market scrap benchmark ranges (e.g., current copper scrap rate, mild steel melting scrap rate) to help the surveyor benchmark reasonableness of salvage bids.
- **Salvage Disposal Narration Drafter (AI-4)**: Drafts a factual salvage management summary for FSR Section D/F.

---

## 6. Offline State & Sync Indicators
- Salvage weights, photos of weighbridge slips, and buyer notes can be recorded offline.
- Realized salvage totals update local calculation models instantly.

---

## 7. Action Triggers & Navigation
- **Click "Save & Proceed to Coverage & Liability"**: Syncs salvage deduction to Stage 11 and advances to Stage 13 (`14_coverage_liability_opinion`).
- **Click "Export Salvage Tender Notice"**: Generates a standard salvage quotation invitation document.
