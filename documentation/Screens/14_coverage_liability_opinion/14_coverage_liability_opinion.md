# Screen Specification: 14_coverage_liability_opinion

## 1. Screen Objective & Context
- **Screen Name**: Policy Coverage, Warranties & Liability Consideration (Decision Support)
- **Stage Mapping**: Stage 13 of 15 (Coverage and Liability Consideration)
- **Purpose**: Structures the surveyor’s independent, professional opinion on policy liability and claim admissibility as a **decision-support workstation**. Evaluates whether the reported proximate cause falls within the policy’s insured perils, assesses compliance with policy warranties and conditions, flags material breaches, and articulates surveyor observations without prejudice for final insurer determination.
- **Regulatory Guardrail**: The platform and AI assistant strictly provide decision-support analysis for surveyor review. The AI shall never autonomously determine claim admissibility, approval, or repudiation. Final claim liability determination remains with the insurer.

---

## 2. Layout & UI Architecture

### 2.1 Primary Mobile App View (iOS & Android) - Core Mobile Experience
- **Mobile Liability Assessment**:
  - **Decision-Support Banner**: *"Decision-support analysis for surveyor review. Final liability determination remains with the insurer."*
  - Top: Admissibility Recommendation Segmented Control (*Admissible as Assessed*, *Subject to Insurer Liability Determination*, *Non-Admissible / Repudiation Recommended*).
  - Collapsible Accordions:
    1. *Operative Peril Evaluation* (with voice notes & physical evidence links)
    2. *Warranty Compliance Checklist*
    3. *Exclusions Check*
    4. *Surveyor Conclusion & Observations*
  - AI "Draft Opinion" button for instant Section I synthesis (editable by surveyor).
  - Bottom CTA: "Save Opinion & Proceed to FSR Builder".

### 2.2 Responsive Desktop Web View
- **Two-Column Professional Review Layout**:
  - **Left Pane (50% width)**: Policy Perils & Scope of Coverage Verification Checklist, Warranties & Endorsements Compliance Review Grid, Exclusions Review Matrix.
  - **Right Pane (50% width)**: Surveyor Professional Liability Opinion Editor (Rich text editor with AI drafting assistance), Claim Admissibility Recommendation Selector, Decision-Support Disclaimer Banner, and Standard Without Prejudice Declaration Block.

---

## 3. Detailed UI Component Hierarchy
1. **Peril Scope & Coverage Evaluator**:
   - `DecisionSupportNoticeBanner` ("Decision-support analysis for surveyor review. Final liability determination remains with the insurer.")
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
   - `SurveyorRecommendationRadio` (*Admissible as Assessed / Subject to Insurer Liability Determination / Non-Admissible / Repudiation Recommended*).
   - `FormalOpinionRichEditor` (Surveyor’s closing professional reasoning for FSR Section I).
   - `WithoutPrejudiceClauseNotice` (Standard regulatory disclaimer).

---

## 4. Data Fields, Types & Validations

| Field | Type | Mandatory | Validation Rules | Description |
| :--- | :--- | :--- | :--- | :--- |
| `peril_admissibility` | Enum | Yes | Admissible / Inadmissible / Disputed | Peril coverage observation |
| `peril_justification` | Text | Yes | Min 30 chars | Factual analysis of cause vs peril |
| `warranty_compliance_status`| Enum | Yes | All Complied / Material Breach | Overall warranty standing |
| `breach_details` | Text | Conditional | Mandatory if warranty breached | Description of policy breach |
| `surveyor_recommendation`| Enum | Yes | Admissible / Repudiate / Refer | Surveyor’s recommendation |
| `surveyor_opinion_text` | Text | Yes | Min 50 chars | Formal professional opinion |

---

## 5. AI Assistant Integration & Triggers
- **Surveyor Opinion Drafter (AI-4)**: Synthesizes cause findings (Stage 5), physical damage proof (Stage 6), ownership validation (Stage 7), and loss quantification (Stage 11) into a formal, objective narrative for FSR Section I (*Surveyor’s Opinion and Recommendation*).
- **Warranty Breach Analyzer**: Identifies potential conflicts between surveyor field notes and warranty clauses (e.g., flags: "Surveyor noted FEA fire extinguishers were expired in field notes, but FEA warranty was marked complied").
- **Zero-Hallucination & Decision-Support Guardrails**: AI opinion drafter is strictly factual and provides decision support. The AI is strictly prohibited from generating autonomous coverage decisions or binding legal pronouncements.

---

## 6. Offline State & Sync Indicators
- All liability observations, checklist choices, and opinion notes persist offline in SQLite.
- Status badge indicates local cache state.

---

## 7. Action Triggers & Navigation
- **Click "Save & Proceed to Final Survey Report Generator"**: Validates all liability remarks, advancing to Stage 14 (`15_final_survey_report_generator`).
- **Click "Generate AI Opinion Draft"**: Generates professional drafting suggestions for Section I.
