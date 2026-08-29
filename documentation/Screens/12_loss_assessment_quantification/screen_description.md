# Screen Specification: 12_loss_assessment_quantification

## 1. Screen Objective & Context
- **Screen Name**: Detailed Loss Assessment & Quantification Matrix
- **Stage Mapping**: Stage 11 of 15 (Detailed Loss Assessment / Quantification)
- **Purpose**: Core financial calculation engine of the survey report. Provides an enterprise-grade, head-wise loss assessment spreadsheet with automated calculations for Claimed vs. Assessed amounts, standard and custom Depreciation scales, Betterment (New for Old) deductions, Underinsurance / Average Clause factors, Salvage deductions, and Policy Excess / Deductibles. Directly answers *"How much is the actual loss?"* and *"What amount is reasonably recommended?"*.

---

## 2. Layout & UI Architecture

### 2.1 Desktop Web Layout
- **Full-Width Financial Spreadsheet Workspace**:
  - **Top Summary Banner**: Real-time KPI cards:
    - *Total Claimed Amount (₹)*
    - *Total Gross Assessed (₹)*
    - *Total Deductions (Depreciation + Betterment + Underinsurance + Salvage + Excess) (₹)*
    - *Net Recommended Amount (₹)*
  - **Head-Wise Calculation Tabs**: *Building / Civil*, *Plant & Machinery*, *Furniture/Fixtures*, *Stocks*, *Consolidated Grand Summary*.
  - **Multi-Column Financial Grid**: High-precision grid with formula auto-computation and inline remarks cells.

### 2.2 Mobile App Layout (iOS & Android)
- **Mobile Financial Summary & Line Editor**:
  - Sticky bottom bar showing live `Net Recommended Amount (₹)`.
  - Head Selector pills (*Building*, *Machinery*, *Stock*, *Summary*).
  - Expandable Item Cards with calculation sliders for Depreciation %, Betterment, and Salvage.
  - Quick "Remarks" input for every deduction.

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

$$\text{Gross Assessed} = \text{Assessed Quantity} \times \text{Verified Unit Rate}$$

$$\text{Depreciation Amount} = \text{Gross Assessed} \times \left(\frac{\text{Depreciation \%}}{100}\right)$$

$$\text{Net of Depreciation} = \text{Gross Assessed} - \text{Depreciation Amount} - \text{Betterment Deduction}$$

$$\text{If } \text{Value at Risk} > \text{Sum Insured} \implies \text{Underinsurance Deduction} = \text{Net of Depreciation} \times \left(1 - \frac{\text{Sum Insured}}{\text{Value at Risk}}\right)$$

$$\text{Net Recommended} = \text{Adjusted Loss} - \text{Salvage Realization} - \text{Policy Excess}$$

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
