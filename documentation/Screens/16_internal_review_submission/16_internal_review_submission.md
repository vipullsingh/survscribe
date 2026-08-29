# Screen Specification: 16_internal_review_submission

## 1. Screen Objective & Context
- **Screen Name**: Internal Review, Pre-Submission Audit & Submission
- **Stage Mapping**: Stage 15 of 15 (Internal Review and Submission of FSR)
- **Purpose**: Final quality assurance and dispatch terminal. Performs automated arithmetic audits, metadata consistency checks across all 15 stages, validates that all deductions have mandatory justification remarks, confirms that all photo annexure plates are captioned, logs surveyor digital sign-off, and records the formal report submission to the appointing insurer.

---

## 2. Layout & UI Architecture

### 2.1 Primary Mobile App View (iOS & Android) - Core Mobile Experience
- **Mobile Submission Dashboard**:
  - Audit Result Card with live compliance badges (*Green Checkmark: 100% Audit Passed / Yellow: Warnings requiring attention*).
  - One-tap "Resolve Warnings" action chips (direct deep links to fix discrepancies).
  - In-app Digital Signature Pad (draw signature on touchscreen or upload stored image).
  - "Submit & Dispatch Report to Insurer" action button with confirmation modal.
  - Final submitted status screen with instant download link for `.docx` and sharing options.

### 2.2 Responsive Desktop Web View
- **Two-Column QA & Submission Hub**:
  - **Left Pane (50% width)**: Automated Pre-Submission Audit Checklist (Live validation engine checking **7** compliance gates) and Discrepancy/Warning Resolver.
  - **Right Pane (50% width)**: Final Surveyor Sign-Off & SLA Certification Block, Insurer Submission & Dispatch Log, and Archive Snapshot & Version Lock Button.

---

## 3. Detailed UI Component Hierarchy
1. **Automated Pre-Submission Audit Engine (7 Compliance Gates)**:
   - `Gate1_ArithmeticCheck`: Verifies that Section F table totals match line item sums exactly to the rupee.
   - `Gate2_MetadataConsistency`: Confirms Policy No, Claim No, Insured Name, and Date of Loss are 100% consistent across all 9 sections.
   - `Gate3_DeductionRemarks`: Flags any rate cut, depreciation deduction, or salvage deduction lacking a justification remark.
   - `Gate4_PhotoAnnexureCompliance`: Ensures all attached photos have timestamps, GPS tags, and descriptive captions.
   - `Gate5_DocumentCompleteness`: Verifies that all mandatory documents for the reported peril have been accounted for.
   - `Gate6_ContradictionScanner`: AI checks for contradictory statements between Section C (Cause), Section D (Findings), and Section I (Opinion).
   - `Gate7_HumanApprovalAndAIGate`: Verifies that all 4 mandatory points of the Human Approval Gate have been reviewed, accepted, and timestamped by the licensed surveyor.
2. **Surveyor Sign-Off & Regulatory Declaration**:
   - `SurveyorNameAndLicenseDisplay` (SLA No., Category, Validity).
   - `HumanApprovalConfirmationNotice` (4-point AI review & professional responsibility verification summary).
   - `WithoutPrejudiceDeclarationCheckbox` (Mandatory confirmation: *"This assessment is issued without prejudice, subject to policy terms and final acceptance by the insurer."*).
   - `DigitalSignatureUpload` or `DrawSignaturePad`.
   - `SignOffDateInput`.
3. **Insurer Submission & Dispatch Dispatcher**:
   - `RecipientInsurerEmailInput` (Pre-filled from Stage 1 appointment data).
   - `CCRecipientsInput` (Insured, Broker, Branch Manager).
   - `EmailSubjectTemplate` (e.g., `Final Survey Report - Claim No: [CLAIM_NO] - Insured: [INSURED_NAME]`).
   - `DispatchMethodSelect` (*Direct Email with .docx Attachment, Insurer Portal Upload, Hard Copy Courier Log*).
   - `CourierTrackingNumberInput` (Optional for physical delivery).
   - `FinalSubmitButton` (Locks survey file as `STATUS_SUBMITTED`).

---

## 4. Data Fields, Types & Validations

| Field | Type | Mandatory | Validation Rules | Description |
| :--- | :--- | :--- | :--- | :--- |
| `audit_pass_status` | Boolean | Yes | Must be `true` to submit | Confirmation of zero audit errors |
| `surveyor_signature` | Image/Blob | Yes | Valid signature data | Formal SLA sign-off |
| `declaration_accepted`| Boolean | Yes | Must be `true` | Legal declaration acceptance |
| `submission_date` | Date | Yes | Defaults to today | Formal dispatch date |
| `submission_channel` | Enum | Yes | Email / Portal / Courier | Delivery medium |
| `recipient_email` | Email | Conditional | Mandatory for Email dispatch | Insurer claims email |

---

## 5. AI Assistant Integration & Triggers
- **Automated Consistency Auditor (AI-3 & Engine)**:
  - Cross-verifies the entire 9-section report in milliseconds.
  - Detects if an item marked "Repairable" in Stage 6 is quantified as "Total Loss" in Stage 11.
  - Confirms that deductible amounts in Section F match the policy excess clause from Stage 2.
- **Dispatch Email Drafter (AI-4)**: Drafts a concise, professional cover email to the insurer claims department summarizing key findings, assessed loss, and net recommended amount.

---

## 6. Offline State & Sync Indicators
- Pre-submission audit can run completely offline using local validation logic.
- If submitted while offline, the submission is queued as `STATUS_PENDING_DISPATCH` and sent automatically when internet connection is re-established.

---

## 7. Action Triggers & Navigation
- **Click "Finalize & Submit Report"**: Validates all 7 gates, locks report snapshot as read-only, dispatches `.docx` package, and transitions claim status to `COMPLETED_SUBMITTED`.
- **Navigation after Submission**: Returns to `01_dashboard` with a success toast and links to download the final submitted `.docx` document.
