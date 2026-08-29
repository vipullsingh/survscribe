# SurvScribe: AI-Assisting Insurance Claim Surveyor Platform (MVP)

> **Regulatory & Professional Positioning**:  
> **SurvScribe is a technology platform designed to assist licensed Insurance Surveyors and Loss Assessors in their professional workflow.** SurvScribe does not independently act as an Insurance Surveyor and Loss Assessor, insurer, insurance intermediary, or claims decision-maker. All survey findings, loss assessments, coverage observations, recommendations, and reports generated or assisted by the platform are subject to review, validation, and professional approval by an appropriately licensed surveyor. Final claim liability and settlement decisions remain the responsibility of the relevant insurer.

**SurvScribe** is a specialized, zero-hallucination, offline-first mobile platform engineered for licensed General Insurance Claim Surveyors and Loss Assessors (SLA).

> **Naming note**: The product name is **SurvScribe** (code, packages, UI). The git repository directory (`SurveyAssist`) and the internal claim-reference prefix `SA-` (e.g. `SA-2026-00101`) are retained as fixed internal codes and are *not* renamed.
>
> **MVP client**: A single **React Native (TypeScript)** mobile application (iOS & Android). A companion desktop web app is **post-MVP** — the "Responsive Desktop Web View" sections in the screen specs are forward-looking design, not MVP build targets.

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
│   ├── decisions/                                    # Architecture Decision Records (one file per decision)
│   ├── architecture/                                 # Physical schema, API contract, system diagrams
│   └── Screens/                                      # 17 Dedicated Screen Specification Folders
│       ├── 00_auth/                                  # 00_auth_login.md, 00_auth_signup.md, 00_auth_terms.md + designs/ (8 vector artboards)
│       ├── 01_dashboard/01_dashboard.md
│       ├── 02_appointment_claim_intake/02_appointment_claim_intake.md
│       ├── 03_policy_coverage_review/03_policy_coverage_review.md
│       ├── 04_insured_contact_schedule/04_insured_contact_schedule.md
│       ├── 05_risk_location_verification/05_risk_location_verification.md
│       ├── 06_cause_investigation/06_cause_investigation.md
│       ├── 07_damage_inspection_studio/07_damage_inspection_studio.md
│       ├── 08_ownership_document_locker/08_ownership_document_locker.md
│       ├── 09_preliminary_survey_report_psr/09_preliminary_survey_report_psr.md
│       ├── 10_followup_investigation/10_followup_investigation.md
│       ├── 11_document_verification_audit/11_document_verification_audit.md
│       ├── 12_loss_assessment_quantification/12_loss_assessment_quantification.md
│       ├── 13_salvage_disposal_manager/13_salvage_disposal_manager.md
│       ├── 14_coverage_liability_opinion/14_coverage_liability_opinion.md
│       ├── 15_final_survey_report_generator/15_final_survey_report_generator.md
│       └── 16_internal_review_submission/16_internal_review_submission.md
│
├── apps/                                             # Monorepo apps (scaffold — no code yet)
│   ├── backend/                                      # Go + Gin REST API, state machine, server .docx engine
│   └── mobile/                                       # React Native (TypeScript) field app
├── packages/                                         # Shared workspace packages (scaffold): api-contracts, config, types, ui
└── README.md
```

> **Repo status**: `apps/` and `packages/` are empty directory scaffolds. Tooling target: **pnpm workspaces + Turborepo** for the TypeScript packages; the Go backend keeps its own `go.mod` and is built separately.

---

## 🚀 Key Architectural Features

- **Mobile-First Architecture**: Delivered as a **dedicated React Native (TypeScript) mobile application (iOS & Android)** with touch-first ergonomics, bottom action bars, single-hand usability, and native mobile views everywhere across all 15 stages.
- **High-Performance Golang Backend**: Fast, lightweight **REST/JSON** backend in **Go (Golang) + Gin** with goroutine-powered concurrent media sync, chunked photo uploads, claim state machine, and PostgreSQL (`pgx`). (gRPC is out of scope for the MVP.)
- **Visual Design System**: Complete forensic-precision design system with Deep Cobalt primary (`#1E3A8A`, hover `#1E40AF`), Electric Azure accent (`#3B82F6`), high-contrast sunlight readability, monospace number formatting, and solid opaque surfaces (no heavy glassmorphism — see the Design System anti-pattern rules).
- **Offline-First Resilience**: Full field data, photo capture, voice notes, and damage calculations with local SQLite caching and automatic bi-directional synchronization.
- **On-Device / Local AI Slot**: Modular `AIProviderInterface` designed for cloud LLMs online and quantized on-device SLM/Whisper models when offline.
- **5 Core AI Touchpoints**:
  1. *Voice-to-Text Field Assistant* (Transcribes field speech on mobile into structured damage items)
  2. *Document & Invoice OCR* (Extracts line items from camera scans & PDFs)
  3. *Cross-Checking & Fraud / Discrepancy Audit* (Flags duplicate claims, rate inflation, and unlisted items)
  4. *Report Draft Generator (PRIMARY FOCUS)* (Generates formal PSR and FSR narrative drafts)
  5. *Loss Assessment & Depreciation Calculator* (Deterministic mobile financial calculator)
- **Standardized Editable Output**: Direct export of **Preliminary Survey Reports (PSR)** and **Final Survey Reports (FSR)** into editable Microsoft Word (`.docx`) files with calculation tables and photo annexure plates. Two engines share one template contract: a **client-side (TypeScript) engine** for offline drafts, and an **authoritative server-side Go engine** for the final compiled report (the `< 5 s` / 50-plate benchmark applies to the server engine).
- **Future-Ready RBAC Schema**: Built-in multi-tenant and role metadata without blocking MVP UI complexity.

---

## 📖 Documentation Quick Links
- [Software Requirements Specification (Requirement.MD)](documentation/Requirement.MD)
- [User Stories & Acceptance Criteria](documentation/User%20Stories.md)
- [Visual Theme & Design System](documentation/Visual%20Theme%20&%20Design%20System.md)
- [Screen Specifications](documentation/Screens/)
- [Architecture Decision Records](documentation/decisions/)
