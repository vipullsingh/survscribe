# SurvScribe: AI-Assisting Insurance Claim Surveyor Platform (MVP)

**SurvScribe** is a specialized, zero-hallucination, offline-first mobile platform designed for licensed General Insurance Claim Surveyors and Loss Assessors (SLA).

The platform manages the complete **15-Stage General Claim Survey Process** (from Appointment Intake to Final Survey Report Submission) answering the 5 foundational loss assessment questions:
1. **What happened?** *(Cause & circumstances)*
2. **What was damaged?** *(Physical inspection & damaged property register)*
3. **Is the damage connected to the reported incident?** *(Causation & peril verification)*
4. **How much is the actual loss?** *(Detailed quantification, depreciation & betterment)*
5. **What amount is reasonably recommended subject to policy terms?** *(Underinsurance, Salvage & Excess)*

---

## 📁 Repository Structure

```
├── documentation/
│   ├── Requirement.MD                                # Comprehensive Software Requirements Specification (SRS)
│   ├── User Stories.md                               # 16 Epics & Acceptance Criteria mapped to the 15 stages
│   ├── Visual Theme & Design System.md               # Complete Visual Design System, Tokens, Typography & Components
│   └── Screens/                                      # 18 Dedicated Screen Specification Folders
│       ├── 00_auth_login/screen_description.md
│       ├── 00_auth_signup/screen_description.md
│       ├── 01_dashboard/screen_description.md
│       ├── 02_appointment_claim_intake/screen_description.md
│       ├── 03_policy_coverage_review/screen_description.md
│       ├── 04_insured_contact_schedule/screen_description.md
│       ├── 05_risk_location_verification/screen_description.md
│       ├── 06_cause_investigation/screen_description.md
│       ├── 07_damage_inspection_studio/screen_description.md
│       ├── 08_ownership_document_locker/screen_description.md
│       ├── 09_preliminary_survey_report_psr/screen_description.md
│       ├── 10_followup_investigation/screen_description.md
│       ├── 11_document_verification_audit/screen_description.md
│       ├── 12_loss_assessment_quantification/screen_description.md
│       ├── 13_salvage_disposal_manager/screen_description.md
│       ├── 14_coverage_liability_opinion/screen_description.md
│       ├── 15_final_survey_report_generator/screen_description.md
│       └── 16_internal_review_submission/screen_description.md
└── README.md
```

---

## 🚀 Key Architectural Features

- **Mobile-First Architecture**: Designed as a **dedicated Mobile Application (iOS & Android)** with touch-first ergonomics, bottom action bars, single-hand usability, and native mobile views everywhere across all 15 stages.
- **Visual Design System**: Complete forensic precision design system with Deep Cobalt (`#1E40AF`), Electric Azure (`#3B82F6`), high-contrast sunlight readability, monospace number formatting, and glassmorphic micro-surfaces.
- **Offline-First Resilience**: Full field data, photo capture, voice notes, and damage calculations with local SQLite caching and automatic bi-directional synchronization.
- **On-Device / Local AI Slot**: Modular `AIProviderInterface` designed for cloud LLMs online and quantized on-device SLM/Whisper models when offline.
- **5 Core AI Touchpoints**:
  1. *Voice-to-Text Field Assistant* (Transcribes field speech on mobile into structured damage items)
  2. *Document & Invoice OCR* (Extracts line items from camera scans & PDFs)
  3. *Cross-Checking & Fraud / Discrepancy Audit* (Flags duplicate claims, rate inflation, and unlisted items)
  4. *Report Draft Generator (PRIMARY FOCUS)* (Generates formal PSR and FSR narrative drafts)
  5. *Loss Assessment & Depreciation Calculator* (Deterministic mobile financial calculator)
- **Standardized Editable Output**: Direct export of **Preliminary Survey Reports (PSR)** and **Final Survey Reports (FSR)** into editable Microsoft Word (`.docx`) files with calculation tables and photo annexure plates.
- **Future-Ready RBAC Schema**: Built-in multi-tenant and role metadata without blocking MVP UI complexity.

---

## 📖 Documentation Quick Links
- [Software Requirements Specification (Requirement.MD)](documentation/Requirement.MD)
- [User Stories & Acceptance Criteria](documentation/User%20Stories.md)
- [Visual Theme & Design System](documentation/Visual%20Theme%20&%20Design%20System.md)
- [Screen Specifications](documentation/Screens/)
