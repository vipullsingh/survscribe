# Screen Specification: 14_coverage_liability_opinion

## 1. Screen Objective & Context
- **Screen Name**: Policy Coverage, Warranties & Liability Consideration
- **Stage Mapping**: Stage 13 of 15 (Coverage and Liability Consideration)
- **Purpose**: Structures the surveyor’s independent, professional opinion on policy liability and claim admissibility. Evaluates whether the reported proximate cause falls within the policy’s insured perils, assesses compliance with all policy warranties and conditions, flags material breaches, and articulates surveyor recommendations without prejudice.

---

## 2. Layout & UI Architecture

### 2.1 Primary Mobile App View (iOS & Android) - Core Mobile Experience
- **Mobile Liability Assessment**:
  - Top: Admissibility Status Segmented Control (*Admissible*, *Repudiation Recommended*, *Insurer Discretion*).
  - Collapsible Accordions:
    1. *Operative Peril Evaluation* (with voice notes)
    2. *Warranty Compliance Checklist*
    3. *Exclusions Check*
    4. *Surveyor Conclusion & Remarks*
  - AI "Draft Opinion" button for instant Section I synthesis.
  - Bottom CTA: "Save Opinion & Proceed to FSR Builder".

### 2.2 Responsive Desktop Web View
- **Two-Column Professional Review Layout**:
  - **Left Pane (50% width)**: Policy Perils & Scope of Coverage Verification Checklist, Warranties & Endorsements Compliance Review Grid, Exclusions Review Matrix.
  - **Right Pane (50% width)**: Surveyor Professional Liability Opinion Editor (Rich text editor with AI legal clause suggestions), Claim Admissibility Recommendation Selector, and Standard Without Prejudice Disclaimer Block.

---

## 3. Detailed UI Component Hierarchy
1. **Peril Scope & Coverage Evaluator**:
   - `OperativePerilStatusSelect` (*Loss strictly falls within Insured Peril / Peril Not Covered / Cause Ambiguous*)
   - `PerilAnalysisTextarea` (Detailed analysis connecting physical evidence from Stage 6 to policy peril definitions).
2. **Warranty & Policy Conditions Grid**:
   - `WarrantyComplianceTable`:
     - Rows populated from Stage 2: *Fire Extinguishing Appliances Warranty, Silent Warranty, Good Housekeeping, 24/7 Security Watchman, Maintenance Log Warranty*.
     - Columns: `Warranty Clause`, `Status (Complied / Breached / Not Applicable)`, `Observations & Evidence`.
3. **Policy Exclusions Verification**:
   - `ExclusionsChecklist`: Standard exclusions (e.g., *Wear and tear, Spontaneous combustion, Electrical short circuit to own machine, Wilful act, War and nuclear*).
   - `ExclusionApplicabilityToggle` (*Applicable / Not Applicable*).
4. **Surveyor Formal Opinion & Recommendation**:
   - `SurveyorRecommendationRadio` (*Claim is Admissible as Assessed / Claim is Recommended for Repudiation / Sub Judice / Subject to Specific Insurer Waiver*).
   - `FormalOpinionRichEditor` (Surveyor’s closing professional reasoning for FSR Section I).
   - `WithoutPrejudiceClauseNotice` (Standard regulatory disclaimer).

---

## 4. Data Fields, Types & Validations

| Field | Type | Mandatory | Validation Rules | Description |
| :--- | :--- | :--- | :--- | :--- |
| `peril_admissibility` | Enum | Yes | Admissible / Inadmissible / Disputed | Peril coverage determination |
| `peril_justification` | Text | Yes | Min 30 chars | Factual analysis of cause vs peril |
| `warranty_compliance_status`| Enum | Yes | All Complied / Material Breach | Overall warranty standing |
| `breach_details` | Text | Conditional | Mandatory if warranty breached | Description of policy breach |
| `surveyor_recommendation`| Enum | Yes | Admissible / Repudiate / Refer | Surveyor’s formal stance |
| `surveyor_opinion_text` | Text | Yes | Min 50 chars | Formal professional opinion |

---

## 5. AI Assistant Integration & Triggers
- **Surveyor Opinion Drafter (AI-4)**: Synthesizes cause findings (Stage 5), physical damage proof (Stage 6), ownership validation (Stage 7), and loss quantification (Stage 11) into a formal, objective, legally sound narrative for FSR Section I (*Surveyor’s Opinion and Recommendation*).
- **Warranty Breach Analyzer**: Identifies potential conflicts between surveyor field notes and warranty clauses (e.g., flags: "Surveyor noted FEA fire extinguishers were expired in field notes, but FEA warranty was marked complied").
- **Zero-Hallucination Guardrail**: AI opinion drafter is strictly factual and never introduces speculative legal precedents or unverified assumptions.

---

## 6. Offline State & Sync Indicators
- All liability observations, checklist choices, and opinion notes persist offline in SQLite.
- Status badge indicates local cache state.

---

## 7. Action Triggers & Navigation
- **Click "Save & Proceed to Final Survey Report Generator"**: Validates all liability remarks, advancing to Stage 14 (`15_final_survey_report_generator`).
- **Click "Generate AI Opinion Draft"**: Generates professional drafting suggestions for Section I.
