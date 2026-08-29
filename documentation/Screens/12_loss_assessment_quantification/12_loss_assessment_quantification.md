# Screen Specification: 12_loss_assessment_quantification

## 1. Screen Objective & Context
- **Screen Name**: Detailed Loss Assessment & Quantification Matrix
- **Stage Mapping**: Stage 11 of 15 (Detailed Loss Assessment / Quantification)
- **Purpose**: Core financial calculation engine of the survey report. Provides an enterprise-grade, head-wise loss assessment spreadsheet with automated calculations for Claimed vs. Assessed amounts, standard and custom Depreciation scales, Betterment (New for Old) deductions, Underinsurance / Average Clause factors, Salvage deductions, and Policy Excess / Deductibles. Directly answers *"How much is the actual loss?"* and *"What amount is reasonably recommended?"*.

---

## 2. Layout & UI Architecture

### 2.1 Primary Mobile App View (iOS & Android) - Core Mobile Experience
- **Mobile Financial Calculator & Line Editor**:
  - Sticky bottom bar showing live updated `Net Recommended Amount (₹)` and total deductions.
  - Head Selector pills (*Building*, *Machinery*, *Stock*, *Summary*).
  - Expandable Touch-Friendly Item Cards with precision sliders/steppers for Depreciation %, Betterment deduction, and Salvage.
  - Value at Risk (VAR) quick-input card with live Underinsurance / Average Clause badge.
  - Quick-voice button to speak mandatory deduction remarks.
  - Bottom CTA: "Save Assessment & Next: Salvage Manager".

### 2.2 Responsive Desktop Web View
- **Full-Width Financial Spreadsheet Workspace**:
  - **Top Summary Banner**: Real-time KPI cards (Total Claimed, Gross Assessed, Total Deductions, Net Recommended).
  - **Head-Wise Calculation Tabs**: Building / Civil, Plant & Machinery, Furniture/Fixtures, Stocks, Consolidated Grand Summary.
  - **Multi-Column Financial Grid**: High-precision grid with formula auto-computation and inline remarks cells.

---

## 3. Detailed UI Component Hierarchy
1. **Financial KPIs & Underinsurance Monitor**:
   - `KPIHeader`: Claimed vs. Assessed vs. Deductions vs. Net Recommended.
   - `UnderinsuranceCalculatorBar`:
     - `ValueAtRiskInput` (₹ Total sound value at risk at time of loss)
     - `SumInsuredDisplay` (₹ From Stage 2 policy schedule)
     - `UnderinsuranceFactorBadge` (e.g., "Adequate (100%)" or "Underinsured: 72.4% - Average Clause Triggered").
2. **Head-Wise Assessment Spreadsheet**:
   - `AssessmentGrid`:
     - Columns:
       1. `Sr. No.`
       2. `Description of Damaged Item / Work`
       3. `Claimed Amount (₹)`
       4. `Gross Assessed Amount (₹)`
       5. `Depreciation % & Amount (₹)`
       6. `Betterment Deduction (₹)`
       7. `Sub-Total (₹)`
       8. `Underinsurance Deduction (₹)`
       9. `Salvage Deduction (₹)`
       10. `Net Assessed Item Amount (₹)`
       11. `Surveyor Basis & Justification Remarks` (Mandatory for any deduction/disallowance)
3. **Policy Excess & Net Recommendation Calculator**:
   - `SectionWiseTotalRow` (Subtotal per head)
   - `GrossLossPayable` (Sum of all heads)
   - `SalvageDeductionRow` (Linked to Stage 12)
   - `PolicyExcessDeductionInput` (Auto-calculated based on policy excess % or minimum excess rule)
   - `NetRecommendedPayableBox` (Prominently styled final recommended figure).

---

## 4. Mathematical Formulas & Rules

Deductions are applied in this **strict order**: Gross Assessed → less Depreciation → less Betterment → less Underinsurance → less Salvage → less Policy Excess.

$$\text{Gross Assessed} = \text{Assessed Quantity} \times \text{Verified Unit Rate}$$

$$\text{Depreciation Amount} = \text{Gross Assessed} \times \left(\frac{\text{Depreciation \%}}{100}\right)$$

$$\text{Net of Depreciation} = \text{Gross Assessed} - \text{Depreciation Amount} - \text{Betterment Deduction}$$

$$\text{If } \text{VAR} > \text{SI} \implies \text{Underinsurance Deduction} = \text{Net of Depreciation} \times \left(1 - \frac{\text{SI}}{\text{VAR}}\right)\text{, else } 0$$

$$\text{After Underinsurance} = \text{Net of Depreciation} - \text{Underinsurance Deduction}$$

$$\text{Net Recommended} = \text{After Underinsurance} - \text{Salvage Realization} - \text{Policy Excess}$$

**Worked example (single line item):** Gross Assessed ₹10,00,000; Depreciation 20% = ₹2,00,000; Betterment ₹50,000 → Net of Depreciation ₹7,50,000. SI ₹60,00,000, VAR ₹80,00,000 → Underinsurance = 7,50,000 × (1 − 60/80) = ₹1,87,500 → After Underinsurance ₹5,62,500. Salvage ₹40,000 → ₹5,22,500. Policy Excess ₹25,000 → **Net Recommended ₹4,97,500**.

---

## 5. Data Fields, Types & Validations

| Field | Type | Mandatory | Validation Rules | Description |
| :--- | :--- | :--- | :--- | :--- |
| `head_category` | Enum | Yes | Building, Machinery, FFF, Stocks | Asset category head |
| `claimed_amount` | Currency (₹) | Yes | Numeric $\ge 0$ | Amount claimed by insured |
| `gross_assessed` | Currency (₹) | Yes | Numeric $\ge 0$, must be $\le$ claimed | Assessed replacement cost |
| `depreciation_pct` | Float | Yes | $0.0\%$ to $90.0\%$ | Depreciation percentage applied |
| `betterment_deduction` | Currency (₹) | No | Numeric $\ge 0$ | New for old betterment deduction |
| `salvage_deduction` | Currency (₹) | No | Numeric $\ge 0$ | Realized/estimated salvage |
| `policy_excess` | Currency (₹) | Yes | Numeric $\ge 0$ | Policy deductible deducted |
| `justification_remarks`| Text | Conditional | Mandatory if `gross_assessed < claimed` | Legal/technical justification for cuts |

---

## 6. AI Assistant Integration & Triggers
- **Loss Assessment Assistant (AI-5)**:
  - Suggests standard IRDAI / engineering depreciation scales based on asset type and invoice age from Stage 8.
  - Automatically calculates Average Clause / Underinsurance factor when Value at Risk is entered.
  - Validates all horizontal and vertical math totals with zero probabilistic rounding errors.
- **Zero-Hallucination Guardrail**: The calculation engine is 100% deterministic arithmetic. AI assists in suggesting scales and formatting, but never estimates or alters numbers without surveyor action.

---

## 7. Offline State & Sync Indicators
- Entire calculation spreadsheet executes locally using client-side JavaScript math engine.
- Instant recalculation without server roundtrips. All line items persist locally in SQLite.

---

## 8. Action Triggers & Navigation
- **Click "Save & Proceed to Salvage Manager"**: Locks assessment figures, advancing to Stage 12 (`13_salvage_disposal_manager`).
- **Click "Export Assessment Table (.docx / Excel)"**: Generates standalone financial schedule for report annexure.
