# SurvScribe — MVP Development Roadmap & Sprint Plan

> **Document type:** Planning artifact (roadmap + sprint breakdown) for the SurvScribe MVP.
> **Created:** 2026-08-30 · **Status:** Draft — awaiting project-owner approval before implementation begins.
> **Basis:** Derived exclusively from [`Requirement.MD`](../Requirement.MD) (SRS v1.0.0-MVP), [`User Stories.md`](../User%20Stories.md), [`Visual Theme & Design System.md`](../Visual%20Theme%20&%20Design%20System.md), the 19 screen specs under [`Screens/`](../Screens/), the accepted ADRs under [`decisions/`](../decisions/), and a direct file audit of the repository working tree on 2026-08-30.
>
> **Nothing in this document is a new requirement.** Where a decision could not be confirmed from the existing project it is marked **Needs Clarification** and listed in §11. Where a suggestion is the author's own, it is labelled **Recommendation**.
>
> **Sprint counts express sequencing, not calendar commitments.** Durations are deliberately omitted.

---

## Sprint Folder Index

Each sprint has its own folder containing a `README.md` with its objective, task table, acceptance criteria, dependencies, risks, and Definition of Done delta.

| # | Folder | Ref | Stage | Sprint name |
| :-- | :-- | :-- | :-- | :-- |
| 1 | [`sprint_0001_contract_and_toolchain_freeze/`](sprint_0001_contract_and_toolchain_freeze/) | S0.1 | 0 | Contract & Toolchain Freeze |
| 2 | [`sprint_0002_sync_spike_and_design_kernel/`](sprint_0002_sync_spike_and_design_kernel/) | S0.2 | 0 | Sync Spike + Design System Kernel |
| 3 | [`sprint_0003_auth_online/`](sprint_0003_auth_online/) | S1.1 | 1 | Auth: Online |
| 4 | [`sprint_0004_offline_vault_and_session/`](sprint_0004_offline_vault_and_session/) | S1.2 | 1 | Offline Vault + Session |
| 5 | [`sprint_0005_sync_engine_and_dashboard/`](sprint_0005_sync_engine_and_dashboard/) | S1.3 | 1 | Sync Engine v1 + Dashboard |
| 6 | [`sprint_0006_intake_and_policy/`](sprint_0006_intake_and_policy/) | S2.1 | 2 | Intake + Policy (Stages 1–2) |
| 7 | [`sprint_0007_location_and_cause/`](sprint_0007_location_and_cause/) | S2.2 | 2 | Location + Cause (Stages 4–5) |
| 8 | [`sprint_0008_damage_studio_and_photos/`](sprint_0008_damage_studio_and_photos/) | S2.3 | 2 | Damage Studio + Photos (Stage 6) |
| 9 | [`sprint_0009_ownership_requisition_and_psr/`](sprint_0009_ownership_requisition_and_psr/) | S2.4 | 2 | Ownership + Requisition + PSR (Stages 7–8) → **M1** |
| 10 | [`sprint_0010_followup_and_document_audit/`](sprint_0010_followup_and_document_audit/) | S3.1 | 3 | Follow-up + Document Audit (Stages 9–10) |
| 11 | [`sprint_0011_loss_quantification/`](sprint_0011_loss_quantification/) | S3.2 | 3 | Loss Quantification (Stage 11) |
| 12 | [`sprint_0012_salvage_and_coverage_opinion/`](sprint_0012_salvage_and_coverage_opinion/) | S3.3 | 3 | Salvage + Coverage Opinion (Stages 12–13) |
| 13 | [`sprint_0013_fsr_assembly_and_submission_gates/`](sprint_0013_fsr_assembly_and_submission_gates/) | S3.4 | 3 | FSR Assembly + Gates + Server Engine (Stages 14–15) → **M2** |
| 14 | [`sprint_0014_ai_narrative_drafter/`](sprint_0014_ai_narrative_drafter/) | SAI.1 | 3.5 | AI-4 Grounded Narrative Drafter |
| 15 | [`sprint_0015_hardening_and_security_review/`](sprint_0015_hardening_and_security_review/) | S4.1 | 4 | Hardening & Security Review |
| 16 | [`sprint_0016_performance_accessibility_and_uat/`](sprint_0016_performance_accessibility_and_uat/) | S4.2 | 4 | Performance, Accessibility, UAT Prep |
| 17 | [`sprint_0017_production_readiness_and_launch/`](sprint_0017_production_readiness_and_launch/) | S5.1 | 5 | Production Readiness & Launch |

---

## 1. Project Understanding Summary

### A. Product

| Question | Answer | Evidence |
| :-- | :-- | :-- |
| Problem solved | Eliminates administrative bottlenecks, prevents discrepancies, and accelerates preparation of **Preliminary Survey Reports (PSR)** and **Final Survey Reports (FSR)** for insurance loss assessment. | SRS §1.1; `README.md` |
| Intended users | Licensed General Insurance Claim Surveyors and Loss Assessors (SLA) in India; surveyor firms. | SRS §1.1; CR-A5–A10 |
| Primary user roles | `SURVEYOR` (the only role exercised in MVP), plus `REVIEWER`, `ADMIN`, `INSURER_VIEWER` as **schema-only metadata**; enforcement deferred. | SRS §5.1; AC 16.2.2; `CLAUDE.md` §5 |
| Core user journey | Sign in → dashboard → create claim (Stage 1) → work the 15-stage pipeline offline in the field → assemble the 9-section FSR with AI-drafted narrative → 4-point Human Approval Gate → 7-gate pre-submission audit → SHA-256 snapshot + dispatch. | SRS §3; Epics 0–16; `CLAUDE.md` §6.3 |
| Value proposition | **Deterministic** loss math + **zero-hallucination, human-gated** AI narrative + **fully offline-first** field operation + **editable `.docx`** output, positioned strictly as assistive (never an insurer / adjudicator / IRDAI body). | SRS §1.2–1.3; `CLAUDE.md` §14 |

### B. Non-negotiable constraints carried into every sprint (`CLAUDE.md` §14)

Regulatory positioning; AI never autonomous on numbers, decisions, or dispatch; zero-hallucination grounding with `[SURVEYOR TO VERIFY]`; the 4-point Human Approval Gate blocks `.docx`; deterministic financial engine reconciling to the rupee; mandatory deduction justifications; offline-first across all 15 stages; field-level timestamp conflict resolution (not last-write-wins); indelible photo watermark + category tag; SQLCipher AES-256 + TLS 1.3 + immutable audit log; RBAC schema columns from day one; the fixed 9-section FSR structure; the fixed 15-stage / screen-number mapping; embedded disclaimers in every export; design-system anti-patterns as acceptance gates; dual `.docx` engine parity.

---

## 2. Current Implementation Audit

**Repository state (verified by file listing, not only by documentation):** documentation + design assets + a **partial monorepo skeleton**. There is **zero application source code, zero migrations, zero tests, zero CI**.

### Present in the working tree

| Artifact | State | Note |
| :-- | :-- | :-- |
| `package.json`, `pnpm-workspace.yaml`, `turbo.json`, `.gitignore` | Present | Root only. `turbo.json` uses the `pipeline` key (Turbo 1.x, consistent with `turbo ^1.13`). |
| `apps/backend/go.mod` | Present | `module github.com/vipullsingh/survscribe/backend`, `go 1.22`. **No `cmd/`, no `internal/`, no `.go` files.** |
| `apps/backend/README.md`, `apps/mobile/README.md` | Present | Describe intended architecture; reference `cmd/server/main.go` and `pnpm --filter mobile`, neither of which exists yet. |
| `packages/docx-engine/README.md`, `packages/types/README.md` | Present | README only. **No `package.json`, no source.** |
| `decisions/ADR-0001..0004` | Present, **Accepted** | Post-date `CLAUDE.md` §16 and resolve several items it still lists as open. |
| `architecture/README.md` | Present | Lists `physical-schema.md`, `api-contract/`, `sync-protocol.md`, `docx-template-contract.md`, `system-diagrams/` — **all "Not started".** |
| 19 screen specs | Present | `00_auth` (×3), `01_dashboard`, `02`–`16`. Detailed and consistent. |
| 8 auth design SVGs + 4 logo SVGs | Present | Auth flow only. |

### Absent (MVP-relevant)

`pnpm-lock.yaml`; any per-package `package.json`; the React Native project (no `apps/mobile/package.json`, `ios/`, `android/`, `src/`); any `.go` / `.ts` / `.tsx` file; DB migrations or DDL; the OpenAPI spec; `packages/types` / `packages/ui` / `packages/config` source; ESLint / Prettier / `tsconfig`; a test framework and tests; CI config; Dockerfiles / compose; `.env.example`, config schema, secrets strategy; visual designs for screens `01`–`16`.

### Contradictions and stale items found during the audit

| Item | Detail | Action |
| :-- | :-- | :-- |
| ~~Biometric unlock~~ | ADR-0001 D32 and SRS §2.3 defer biometrics; ADR-0003 §3.1 said the 15-min idle lock uses "device biometrics". | **Resolved 2026-08-30** — ADR-0005 (D41) amended ADR-0003 §3.1 to device passcode only. |
| ~~`tenant_id` naming~~ | SRS §5.1 and ADR-0004 §4 specified `tenant_id` / `tenants` / `created_by_user_id`. | **Renamed 2026-08-30** by ADR-0005 (D38) to `store_id` / `stores` / `client_id`, before any migration existed. All documents reconciled. |
| ~~`encrypted_token_ref`~~ | SRS §5.2 entity 13 implied a reversible token reference; ADR-0003 §1 requires an Argon2id **hash**. | **Resolved 2026-08-30** — renamed to `sessions.refresh_token_hash` (ADR-0005 D41). |
| Insurable-interest enum | Screen spec `08` and ADR-0001 D34 define 4 states; **AC 7.1.2 still lists only 3**. | Needs Clarification (Q4) — treat D34 (4-state) as authoritative per `CLAUDE.md` §3 CR-W10. |
| Stage 15 gate count | SRS and ADR say **7 gates**; earlier screen prose said "6". Reported reconciled in `CLAUDE.md` §19. | Use 7. |
| Physical repo directory | Still named `SurveyAssist`; the product is `SurvScribe`. | Manual owner task (cannot be done from inside the working directory). |
| Root `README.md` structure section | Stale counts ("18 folders", "4 login artboards"). | Low-priority documentation fix. |

---

## 3. Feature Inventory

**Status legend:** **Not Started** = no code · **Partial** = some scaffold exists. *(Nothing qualifies as Complete or Tested.)*
**Priority legend:** **Critical** = the MVP cannot deliver its core value without it · **High** = strongly needed, a short deferral is tolerable · **Medium** = supporting · **Low** = enhancement.

> A feature is never marked complete merely because a screen spec or SVG exists. Every row below reflects the absence of workflow logic, validation, persistence, and error handling in code.

### 3.1 Foundation & platform

| Feature / Module | Status | Evidence | MVP Priority | Notes |
| :-- | :-- | :-- | :-- | :-- |
| Monorepo tooling & workspace | Partial | root `package.json`, `pnpm-workspace.yaml`, `turbo.json`, `.gitignore` | Critical | No lockfile, per-package manifests, shared `tsconfig`/lint config, or CI. |
| Backend service skeleton (Go + Gin) | Partial | `apps/backend/go.mod` + README | Critical | Module declaration only. Needs `cmd/server`, `internal/*`, config, router, envelope middleware. |
| Mobile app skeleton (React Native + TS) | Not Started | `apps/mobile/README.md`; ADR-0001 D19 | Critical | No RN project at all. |
| Shared domain types package | Not Started | `packages/types/README.md`; ADR-0004 | Critical | Should be generated from the OpenAPI contract. |
| `.docx` template contract package | Not Started | `packages/docx-engine/README.md`; ADR-0001 D22 | High | The shared spec both engines must satisfy. |
| `packages/ui` component library | Not Started | `Visual Theme & Design System.md` | High | Tokens, inputs, buttons, financial-figure formatting, camera HUD. |
| Physical DB schema + migrations | Not Started | `architecture/README.md`; SRS §5.2 (10 core + 10 draft entities) | Critical | Blocks backend, sync, and types. |
| OpenAPI v1 API contract | Not Started | `architecture/README.md`; ADR-0004 | Critical | Blocks parallel backend/mobile work. |
| CI/CD pipeline | Not Started | — | High | Lint + typecheck + test gates; store builds later. |
| Env/config + secrets strategy | Not Started | `.gitignore` covers `.env`; no `.env.example` | High | Required before any vendor key is used. |
| Vendor adapter interfaces (`NotificationService`, `GeocodingService`, `AssistantService`, `DocumentIntelligenceService`) | Not Started | ADR-0002; SRS §4.2 | High | Interfaces are Critical; live vendor implementations vary by feature priority. |

### 3.2 Stage 0 — Authentication

| Feature | Status | Evidence | MVP Priority | Notes |
| :-- | :-- | :-- | :-- | :-- |
| Password login (universal identifier) | Not Started | CR-A1; `00_auth_login.md` | Critical | |
| Registration (2-step) | Not Started | CR-A5–A10; `00_auth_signup.md` | Critical | License #, category, base location **optional at signup** (D35). |
| Terms & Privacy screen | Not Started | CR-A11; `00_auth_terms.md` | High | Mandatory consent checkbox. |
| Session backend (RS256 JWT 15 min + opaque 30-day refresh, Argon2id-hashed) | Not Started | ADR-0003 | Critical | |
| Secure on-device token storage (Keychain / Keystore) | Not Started | ADR-0003 §2; FR-0.3 | Critical | |
| Offline auth + 15-min idle lock + 30-day max offline | Not Started | ADR-0003 §3; CR-A12 | Critical | |
| Phone OTP (30 s resend) + Email OTP (45 s resend) | Not Started | CR-A2; ADR-0002; FR-0.1 | High | Gated on vendor provisioning; **Indian SMS DLT registration lead time is a real risk** → password login ships first. |
| Password recovery / reset link | Not Started | CR-A3 | High | Needs the email vendor. |

### 3.3 Offline core

| Feature | Status | Evidence | MVP Priority | Notes |
| :-- | :-- | :-- | :-- | :-- |
| Local encrypted DB (WatermelonDB + SQLCipher AES-256) | Not Started | ADR-0001 D20; SRS §6.2 | Critical | |
| Bi-directional sync engine (queue + field-level timestamp merge + surveyor conflict confirmation) | Not Started | SRS §2.2; AC 16.1.3; §14.8 | Critical | **Highest engineering risk** (see §11 R1). |
| Local media store + background upload with exponential backoff | Not Started | SRS §6.1 | Critical | |
| Offline indicator + pending-sync count | Not Started | AC 16.1.1; `01_dashboard.md` §6 | Critical | |
| Immutable audit log | Not Started | SRS §5.2 entity 14, §6.2; §14.10 | Critical | |
| RBAC schema columns on all entities | Not Started | SRS §5.1 | Critical | Cheap; must exist from the first migration. |
| 15-stage state machine | Not Started | CR-W1; every screen spec §7 | Critical | Backend authority + client mirror. |

### 3.4 Workflow screens (Stages 1–15)

| Stage / Screen | Feature | Status | MVP Priority | Evidence |
| :-- | :-- | :-- | :-- | :-- |
| 1 — `02_appointment_claim_intake` | Manual intake + `SS-YYYY-XXXXX` / `TEMP-SS-XXXX` + special-instructions banner | Not Started | Critical | FR-1.1–1.3; AC 1.1.1/1.1.3/1.1.4 |
| 1 | Appointment-letter OCR pre-fill (AI-2) | Not Started | Low | AC 1.1.2; needs Textract. Manual entry is the MVP path. |
| 2 — `03_policy_coverage_review` | Section-wise SI, perils, warranties, excess; loss-date-in-period validation | Not Started | Critical | FR-2.1; AC 2.1.1/2.1.2; §11.5 |
| 2 | AI policy-clause highlighter | Not Started | Low | AC 2.1.3 |
| 3 — `04_insured_contact_schedule` | Contact log + visit scheduling + native calendar deep link | Not Started | High | FR-3.1/3.2; AC 3.1.1/3.1.4 |
| 3 | Preservation Notice dispatch (WhatsApp/Email/SMS) | Not Started | Medium | FR-3.3; needs a live `NotificationService`. Fallback: generate text + native share/copy. |
| 4 — `05_risk_location_verification` | GPS capture + 10 m warn / 50 m hard block | Not Started | Critical | FR-4.1; AC 4.1.1; D28 |
| 4 | Reverse-geocode + address compare + `LOCATION_DISCREPANCY_DETECTED` + justification | Not Started | High | FR-4.2/4.3; manual address entry is the degraded-mode fallback. |
| 5 — `06_cause_investigation` | Chronology builder + statutory evidence vault | Not Started | Critical | FR-5.1/5.2 |
| 5 | AI chronology consistency check (>2 h) | Not Started | Low | FR-5.3; AC 5.1.3 |
| 6 — `07_damage_inspection_studio` | Itemized damage register | Not Started | Critical | FR-6.1 |
| 6 | Photo Studio: watermark + JPEG 1600×1200 @85% + 6-category tag + ≥1 photo/item | Not Started | Critical | FR-6.2; §6.1; §14.9 |
| 6 | Voice-to-text field notes (AI-1) | Not Started | Low | AC 6.1.2 |
| 7 — `08_ownership_document_locker` | Ownership docs + 4-state insurable-interest enum + doc→item linkage | Not Started | High | FR-7.1/7.2; D34 |
| 8 — `09_preliminary_survey_report_psr` | Peril-based requisition notice generator | Not Started | High | FR-8.1; AC 8.1.1 |
| 8 | PSR builder + `.docx` export + surveyor-entered reserve | Not Started | Critical | FR-8.2; AC 8.1.2/8.1.3 |
| 9 — `10_followup_investigation` | Multi-visit log, findings, photos, stock reconciliation | Not Started | Medium | FR-9.1/9.2 |
| 10 — `11_document_verification_audit` | Document locker + line-item entry | Not Started | High | FR-10.1 |
| 10 | OCR extraction + side-by-side verification | Not Started | Low | AC 10.1.1/10.1.2; manual entry is the MVP path. |
| 10 | Deterministic forensic audit (`DUPLICATE_CLAIM_ITEM`, `RATE_INFLATION_DETECTED` >20%) | Not Started | High | FR-10.2; §11.2 — **rules engine, not an LLM** (SRS §4.1 AI-3). |
| 11 — `12_loss_assessment_quantification` | **Deterministic loss engine** | Not Started | **Critical (highest risk)** | FR-11.2; §11.1; worked example in `12_*.md` §4 |
| 11 | Head-wise matrix UI + VAR/underinsurance bar + mandatory remarks + finalization block | Not Started | Critical | FR-11.1/11.3; AC 11.1.1–11.1.5 |
| 11 | AI-5 depreciation-scale suggestions | Not Started | Low | Blocked by the unresolved scale data source (Q6). Manual `%` entry suffices. |
| 12 — `13_salvage_disposal_manager` | Salvage inventory + Modes A/B/C + feed to Section F | Not Started | Critical | FR-12.1–12.3; D29 |
| 13 — `14_coverage_liability_opinion` | Peril/warranty/exclusion review + recommendation enum + disclaimers | Not Started | Critical | FR-13.1/13.2; AC 13.1.1–13.1.5 |
| 14 — `15_final_survey_report_generator` | 9-section FSR assembly + Section F + photo annexure + sign-off | Not Started | Critical | FR-14.1; AC 14.2.1–14.2.4 |
| 14 | AI-4 narrative drafter (C/D/H/I) | Not Started | **High** | FR-14.2; AC 14.1.1–14.1.5 |
| 14 | 4-point Human Approval Gate | Not Started | Critical | FR-14.4; §14.4 |
| 14 | Client-side (TS) `.docx` draft engine | Not Started | Critical | ADR-0001 D22 |
| 14/backend | **Authoritative server Go `.docx` engine** + parity + `<5 s`/50-plate | Not Started | Critical | ADR-0001 D22; SRS §6.3 |
| 15 — `16_internal_review_submission` | 7 audit gates + SHA-256 + dispatch log + status lock | Not Started | Critical | FR-15.1/15.2; D36 |
| — `01_dashboard` | Pipeline overview, filters, cards, FAB, offline banner, 5-tab nav | Not Started | Critical | `01_dashboard.md` |
| — `01_dashboard` | Smart priority recommender + NL search | Not Started | Low | `01_dashboard.md` §5 |

### 3.5 Explicitly out of MVP (per existing documentation)

Desktop / companion web app (ADR-0001 D24); RBAC enforcement (SRS §1.2); `INSURER_VIEWER` portal and access-governance UI (SRS §5.1); `REVIEWER`/`ADMIN` capability model; on-device / local LLM and Whisper implementations (interface slots only — SRS §1.2, §4.2).

---

## 4. MVP Scope Definition

The MVP is the **smallest product that lets one licensed surveyor take a claim from appointment to a submitted, audited, hash-locked FSR `.docx`, entirely offline in the field, with the deterministic math and human-gated governance intact.**

### Must Have — MVP Critical

| Group | Items | Why it is Critical |
| :-- | :-- | :-- |
| Foundation | Monorepo completion, physical schema + migrations, OpenAPI v1, shared types, CI, config/secrets strategy, adapter interfaces | Nothing can be built in parallel or safely without a frozen data contract and toolchain. |
| Auth | Password login, 2-step registration, Terms screen, JWT/refresh backend, secure token storage, offline session + idle lock + 30-day cap | Without it there is no access; offline-first requires cached auth. |
| Offline core | Encrypted local DB, sync engine, local media store, offline indicator, audit log, RBAC columns, 15-stage state machine | Offline-first is a hard constraint on **every** stage; audit log and RBAC columns are hard constraints. |
| Workflow capture | Dashboard; Stages 1, 2, 4, 5, 6, 7, 11, 12, 13 | The load-bearing steps that produce the numbers and facts the FSR is built from. |
| Reports & governance | Requisition + PSR + PSR `.docx`; FSR assembly; 4-point Gate; client `.docx` engine; **authoritative server Go engine** + parity; Stage 15 gates + SHA-256 + dispatch log | The report **is** the product. The gates and disclaimers are non-negotiable (§14). |
| Deterministic forensic audit | Stage 10 duplicate + rate-inflation rules + mandatory remark | Specified as deterministic; feeds Section H and the Stage 15 contradiction gate. |

### Should Have — important, a one-sprint deferral is tolerable

| Item | Why it is not Critical |
| :-- | :-- |
| **AI-4 narrative drafter** | The headline differentiator, but the FSR is completable end-to-end with manual narrative entry. Ship as the first fast-follow (sprint 14), ideally inside the MVP window. |
| Phone/Email OTP login + password reset | Password login covers access; OTP is gated on Twilio India SMS-DLT provisioning. |
| Stage 3 notice dispatch via WhatsApp/Email/SMS | Generating the notice text plus native share/copy does not block the workflow. |
| Stage 4 reverse-geocode + automated address compare | Manual address entry plus a manual discrepancy flag is a functional degraded mode; GPS capture itself is Critical. |
| Stage 3 calendar sync; Stage 9 follow-up module | Supporting workflows; a single-visit claim reaches FSR without them. |
| `packages/ui` full component library | Screens can be built to spec with local components and consolidated as they stabilise. |

### Could Have — Post-MVP

AI-1 voice-to-text; AI-2 OCR (appointment letter and Stage 10 invoices); AI-5 depreciation-scale suggestions; AI chronology and policy-clause assistants; dashboard smart-priority recommender and natural-language search; push notifications / statutory-deadline reminders; standalone `.docx`/Excel assessment-table export.

### Out of Scope for MVP

Desktop web app; RBAC enforcement; `INSURER_VIEWER` portal and governance UI; `REVIEWER`/`ADMIN` capability model; on-device LLM/Whisper implementations; direct insurer-portal upload integration.

---

## 5. Development Stages

| Stage | Name | Outcome |
| :-- | :-- | :-- |
| **0** | Foundation & Technical Readiness | Frozen schema + API contract + toolchain; both apps build and run against a local Postgres; conventions set and vendor provisioning under way. |
| **1** | Core Data & Application Foundation | Auth works online and offline; encrypted local DB + sync engine v1 proven on one entity; dashboard renders local claims; navigation shell + design tokens; the deterministic loss-engine package starts under TDD in parallel. |
| **2** | Primary MVP Workflow (Stages 1–8 + PSR) | A surveyor completes Stage 1→8 **offline** and exports a PSR `.docx`. **(Milestone M1)** |
| **3** | Supporting MVP Workflow (Stages 9–15 + FSR) | Full Stage 1→15: quantification, salvage, coverage opinion, 9-section FSR, 4-point gate, authoritative server `.docx`, 7 audit gates, SHA-256 snapshot, dispatch log. **(Milestone M2)** |
| **3.5** | AI Narrative Drafter (fast-follow) | AI-4 drafts Sections C/D/H/I from grounded Stage 1–13 data with `[SURVEYOR TO VERIFY]` and full in-place editing. |
| **4** | Quality, Security & MVP Readiness | Error and edge-case hardening, sync-conflict UX, security review, `.docx` performance benchmark, accessibility pass, device matrix, UAT with authentic data. |
| **5** | MVP Release | Production infrastructure, monitoring, store builds, release checklist against §14, rollback and support plan. |

---

## 6. Detailed Sprint Plan

The per-sprint detail — objective, task table, acceptance criteria, dependencies, risks, and Definition of Done delta — lives in each sprint folder listed in the index above.

### Team shape assumed (**Recommendation**, not a requirement)

Roughly 2-week sprints; a small team of about 2 backend (Go), 2–3 mobile (React Native), 1 shared/QA; a designer producing screen visuals one sprint ahead of the build.

### Global Definition of Done

Applies to every feature sprint. Individual sprints add deltas in their own README.

- Implemented to the cited FR / AC / screen-spec section; any deviation is documented.
- Input validation from the screen spec §4 table enforced on the client and re-checked server-side wherever a server path exists.
- Data persists to the local encrypted DB **and** survives an app restart offline; it syncs and round-trips when back online.
- The offline path works with zero network (airplane-mode test) for every field action.
- Error, empty, and loading states handled; no unhandled promise rejections or panics.
- Store scoping (`store_id` from the verified token) and audit-log entries written wherever the feature touches claim data or loss figures.
- No design-system anti-pattern (`Visual Theme & Design System.md` §2 / §8 checklist).
- Unit tests for logic; at least one offline→online integration test for stateful features. Lint, typecheck, and tests green in CI.
- The completion report distinguishes **Implemented vs Reviewed vs Tested vs Verified**, and states what was not verified and why.
- No new Critical defect linked to the feature.

---

## 7. Dependencies & Critical Path

### Critical path (determines the MVP date)

```
sprint_0001 schema + OpenAPI + skeletons + types
   └─> sprint_0002 sync protocol + .docx contract + sync spike
        └─> sprint_0003 auth online ─> sprint_0004 offline vault ─> sprint_0005 sync engine v1 + dashboard + state machine
             └─> sprint_0006 Stages 1–2 ─> sprint_0007 Stages 4–5 ─> sprint_0008 Stage 6 (photos)
                  └─> sprint_0009 Stages 7–8 + client .docx ───────────────────────────── M1
                       └─> sprint_0010 Stages 9–10 ─> sprint_0011 Stage 11 (loss engine) ─> sprint_0012 Stages 12–13
                            └─> sprint_0013 Stage 14 assembly + gates + SERVER .docx + Stage 15 ── M2
                                 └─> sprint_0015 hardening ─> sprint_0016 perf/a11y/UAT ─> sprint_0017 release
```

`packages/loss-engine` (pure, spec-complete) starts in sprint_0005 and must be green before sprint_0011 — it joins the critical path at that point.

### Parallel workstreams (safe alongside the critical path)

| Workstream | Runs during | Depends only on |
| :-- | :-- | :-- |
| Deterministic loss-engine package (TDD) | sprint_0005 → sprint_0011 | SRS §11.1 + the worked example |
| Screen visual design (Dashboard, Stages 1–15) | sprint_0002 → sprint_0012, one sprint ahead of each screen | screen specs |
| `packages/ui` consolidation | sprint_0002 onward | Design System doc |
| Deterministic forensic-audit rules (Stage 10) | after the schema (sprint_0001), lands in sprint_0010 | schema + invoice/damage entities |
| Server Go `.docx` engine | after the template contract (sprint_0002); **must** converge in sprint_0013 | contract + FSR data shape |
| Vendor provisioning + adapter implementations | sprint_0001 onward | ADR-0002; procurement |
| AI-4 narrative (sprint_0014) | after M2, or overlapping sprint_0013 once assembly exists | grounded context from Stages 1–13 |

### Blockers

| Blocker | Blocks | Resolved in |
| :-- | :-- | :-- |
| Physical schema not finalised or domain-reviewed (10 draft entities) | migrations, OpenAPI, types, all backend + sync | sprint_0001 |
| OpenAPI v1 not frozen | parallel backend/mobile development | sprint_0001 |
| Sync approach unproven (WatermelonDB field-level merge feasibility) | sprint_0005 and every stage screen's offline path | sprint_0002 |
| `.docx` template contract not written | both `.docx` engines and their parity | sprint_0002 |
| Config/secrets strategy absent | any vendor key usage, RS256 keys | sprint_0001 |
| Twilio India SMS-DLT registration | OTP login and SMS dispatch | started in sprint_0001; OTP is Should-Have because of this |
| Depreciation-scale data source (Q6) | AI-5 suggestions only (**not** MVP math) | Post-MVP unless a source is supplied |
| Missing screen designs for `01`–`16` | polished UI (functional build to spec is possible, with rework risk) | design workstream, ahead of each sprint |
| AI-4 cloud-LLM data-residency / privacy sign-off | enabling AI-4 outside a sandbox | before sprint_0014 ships |

---

## 8. MVP Roadmap Summary

| Stage | Sprint | Main deliverable | MVP impact | Dependencies |
| :-- | :-- | :-- | :-- | :-- |
| 0 | sprint_0001 | Frozen physical schema + OpenAPI v1 + shared types + monorepo bootstrap + skeletons + CI + conventions ADR | Unblocks all parallel work | none |
| 0 | sprint_0002 | Sync-protocol doc + spike decision + `.docx` template contract + design-token kernel | De-risks the hardest problem; enables both `.docx` engines | sprint_0001 |
| 1 | sprint_0003 | Password registration + login, JWT/refresh backend, auth + terms screens | Product access | sprint_0001 |
| 1 | sprint_0004 | Encrypted local DB + secure token storage + offline session + idle lock + client audit log | Offline-first foundation | sprint_0003 |
| 1 | sprint_0005 | Sync engine v1 + 15-stage state machine + dashboard + loss-engine kickoff | First offline→online round-trip; entry screen | sprint_0002, sprint_0004 |
| 2 | sprint_0006 | Stage 1 intake (`SS-YYYY-XXXXX`) + Stage 2 policy review | Start of the core workflow | sprint_0005 |
| 2 | sprint_0007 | Stage 4 GPS + accuracy gates; Stage 5 chronology + evidence vault | Location and cause facts | sprint_0006 |
| 2 | sprint_0008 | Stage 6 damage register + watermarked Photo Studio + media store | Evidence capture (hard constraint) | sprint_0007 |
| 2 | sprint_0009 | Stage 7 ownership + Stage 8 requisition + PSR + client `.docx` → **M1** | First exportable report | sprint_0008, sprint_0002 |
| 3 | sprint_0010 | Stage 9 follow-up + Stage 10 locker + deterministic forensic audit | Supporting audit feeds Section H and the gates | M1 |
| 3 | sprint_0011 | Stage 11 loss engine + matrix UI + mandatory-remark block + domain sign-off | The financial core (highest risk) | sprint_0005, Stage 2 |
| 3 | sprint_0012 | Stage 12 salvage (A/B/C) + Stage 13 coverage opinion + disclaimers | Completes the loss picture and governance | sprint_0011 |
| 3 | sprint_0013 | Stage 14 FSR + 4-point gate + client & **server Go `.docx`** + Stage 15 gates + SHA-256 → **M2** | End-to-end product complete | sprint_0012, sprint_0009, sprint_0002 |
| 3.5 | sprint_0014 | AI-4 grounded narrative drafter (C/D/H/I) | Headline differentiator (Should-Have) | M2 |
| 4 | sprint_0015 | Error/edge hardening + security review + RBAC verification + device-matrix regression | Trustworthy and safe | M2 |
| 4 | sprint_0016 | `.docx` performance benchmark + accessibility + design QA + UAT with a real surveyor | Acceptance readiness | sprint_0015 |
| 5 | sprint_0017 | Production infrastructure + observability + store builds + release gate + support plan | Launch | sprint_0016 |

---

## 9. MVP Release Criteria

The MVP is releasable when **all** of the following are true:

1. **End-to-end workflow:** a licensed surveyor completes Stage 1 → Stage 15 for at least one real-shaped claim, with Stage 1–13 capture performed **fully offline** and syncing cleanly on reconnect.
2. **Auth:** password registration and login work online; offline re-entry via cached token + device passcode works; the 15-minute idle lock and 30-day max-offline cap are enforced.
3. **Deterministic math:** the loss engine reproduces the documented worked example exactly; Section F totals reconcile to the rupee; finalization is blocked when any deduction line lacks a justification remark; domain-expert sign-off on the worked example is recorded.
4. **Photo integrity:** every field photo carries an indelible watermark (timestamp, GPS, claim ref, surveyor ID) and a mandatory category tag; no damaged item advances without at least one photo; compression is JPEG 1600×1200 @85% with EXIF preserved.
5. **Governance gates:** the 4-point Human Approval Gate blocks every PSR/FSR `.docx` export until all four boxes are checked, timestamped, and written to the immutable audit log; Stage 15's 7 compliance gates all enforce and block submission on failure with a specific reason.
6. **Report output:** the authoritative **server-side Go `.docx`** engine produces the 9-section FSR with the Section F table, photo annexure, sign-off block, and mandatory disclaimers; it matches the client draft within the parity spec; 9 sections with 50 plates generate in `< 5 s` on production infrastructure.
7. **Submission lock:** on Stage 15 pass, a SHA-256 snapshot is stored, the dispatch log is recorded, and the report record is immutable thereafter.
8. **Security:** SQLCipher AES-256 at rest (verified), Keychain/Keystore for tokens, TLS 1.3 enforced, the audit log and `auth_events` proven append-only, store scoping on every endpoint, no secrets in the repository, and a signed-off security review.
9. **RBAC schema:** all entities carry the five RBAC columns, populated (enforcement deferred, and that deferral documented).
10. **Positioning:** no screen, export, or store listing implies SurvScribe is an insurer, intermediary, IRDAI-approved body, or autonomous decision-maker; the required disclaimers appear on every export.
11. **Quality:** zero open Critical or High defects; device-matrix regression passed; accessibility report clean or Low-only; UAT executed and signed by a licensed surveyor.
12. **Operations:** production deployment, backups, monitoring, crash reporting, rollback plan, and support rota in place; TestFlight / Play internal builds distributed.

---

## 10. Deferred / Post-MVP Features (scope-creep guard)

**Should-Have, first fast-follow after launch:** AI-4 narrative drafter if it does not land in-window; Phone/Email OTP login and password reset; Stage 3 WhatsApp/Email/SMS dispatch of Preservation and Requisition notices; Stage 4 automated reverse-geocode and address compare; Stage 3 native calendar sync; full `packages/ui` consolidation.

**Could-Have, later:** AI-1 voice-to-text; AI-2 OCR with side-by-side verification; AI-5 depreciation-scale suggestions (needs a scale data source first); AI chronology and policy-clause assistants; dashboard smart-priority recommender and natural-language search; push notifications and statutory-deadline reminders; standalone `.docx`/Excel assessment-table export.

**Explicitly out (per ADR-0001 / SRS):** desktop / companion web app (D24); RBAC enforcement; `INSURER_VIEWER` portal and access-governance UI; `REVIEWER` / `ADMIN` capability model; on-device LLM / local Whisper implementations (interface slots only); direct insurer-portal upload integration.

---

## 11. Risks, Blockers & Open Questions

### Top risks

| # | Risk | Impact | Mitigation |
| :-- | :-- | :-- | :-- |
| ~~R1~~ | ~~Offline bi-directional, field-level-merge sync~~ — **RESOLVED 2026-08-30.** Confirmed by source inspection: WatermelonDB's built-in sync has no field-level timestamp and resolves any locally-dirty column unconditionally in favour of local. `ADR-0010`: custom `field_updated_at` queue, WatermelonDB kept as local storage only. `sync-protocol.md` specifies the full protocol. | — | `ADR-0010`, `architecture/sync-protocol.md` |
| R2 | **Dual `.docx` engine (client TS + server Go) parity** doubles report work and is permanent maintenance debt. | Rework, drift, benchmark misses. | Freeze `docx-template-contract.md` early; mandatory parity test suite. **Recommendation:** consider narrowing the MVP to "client draft = preview only, server = authoritative" under timeline pressure. |
| R3 | **Deterministic loss engine** correctness (rounding, deduction order, underinsurance base) — legally consequential figures. | Wrong recommended amounts. | Pure package, TDD, worked-example fixture, **mandatory domain-expert sign-off** (Q8-equivalent) in sprint_0011. |
| R4 | **Twilio India SMS DLT** template/entity registration lead time (often weeks). | OTP login slips. | Password login is Critical, OTP is Should-Have; registration starts in sprint_0001. |
| R5 | **Cloud LLM data residency / privacy** for Indian insurance claim data (AI-4, Anthropic). | Compliance block on enabling AI-4. | Privacy review before sprint_0014 ships; keep AI-4 sandbox-only until cleared; strict prompt boundaries. |
| R6 | **16 of 19 screens have no visual design.** | Build-to-spec is possible, but rework risk. | Designer runs one sprint ahead on the critical path; specs are detailed enough for functional builds. |
| R7 | **On-device image processing** (watermark + compress, 50+ photos) on low-end Android. | Field performance and storage pressure. | Benchmark in sprint_0008; native module for image operations; storage-pressure UX. |
| R8 | **Schema for the remaining entities is drafted (2026-08-30, `physical-schema.md` Part B) but not domain-reviewed**; churn is now bounded to the 9 `[ADDITION]` tables and specific open items (§38) rather than the whole schema. | Foundation rework, narrowed in scope. | Frozen with change control in sprint_0001; owner review before sprint_0003 (still outstanding). |

### Open questions requiring decisions (could not be confirmed from the existing project)

| # | Question | Needed by | Source |
| :-- | :-- | :-- | :-- |
| Q1 | **Rounding policy** for the loss engine — round per line item, or only at section/grand totals? Section F must reconcile to the rupee. | sprint_0005 / sprint_0011 | SRS FR-11.2; `12_*.md` §4 (not specified) |
| ~~Q2~~ | ~~`follow_up_visits` vs `site_visits`~~ — **CLOSED 2026-08-30.** `follow_up_visits` extends `site_visits` via a `visit_type` enum; `preservation_notices` stays its own table. | — | `physical-schema.md` §17 |
| ~~Q3~~ | ~~ADR-0003 biometric contradiction~~ — **CLOSED 2026-08-30.** ADR-0005 (D41) amended ADR-0003 §3.1 to **device passcode only**; biometrics stay deferred per D32. | — | ADR-0005 |
| Q4 | **Insurable-interest enum** — 4-state (D34 / screen `08`) vs 3-state (AC 7.1.2). Confirm 4-state. | sprint_0009 | conflicting documents |
| Q5 | **Stage 15 gate 6 (Contradiction Scanner)** — the exact deterministic rule list, or AI-assisted? Determines whether it is MVP-deterministic or depends on AI-4. | sprint_0013 | FR-15.1 (rules not enumerated) |
| Q6 | **Depreciation / IRDAI / engineering scale data source** — no authoritative table provided. Blocks AI-5 suggestions (not MVP math). | Post-MVP | `CLAUDE.md` §4 item 3, §16 Q6 |
| Q7 | **Session-key loss recovery** — if the Keychain/Keystore entry is wiped, force online re-auth and full re-sync? Any local-data-loss risk to warn about? | sprint_0004 | not documented |
| ~~Q8~~ | ~~firm-admin model~~ — **CLOSED 2026-08-30.** ADR-0005 (D40): registration always creates a **new store**; joining an existing store is **invite-only**; stores are multi-user at schema level from day one. Full DB-driven RBAC per D39 also closes the `REVIEWER`/`ADMIN` capability question. | — | ADR-0005 |
| ~~Q9~~ | ~~Is AI-4 required inside the MVP release window~~ — **CLOSED 2026-08-30 by ADR-0009.** Post-launch fast-follow; sprint_0014 is not a release gate. | — | ADR-0009 |
| Q10 | **Preliminary loss reserve (PSR) and VAR (Stage 11)** — any validation bounds, or free surveyor entry? | sprint_0009 / sprint_0011 | specs say surveyor-entered; no bounds given |
| Q11 | **Media storage backend** in production (S3 / GCS / self-hosted) and the retention policy for large photo sets. | sprint_0017 | not documented |
| ~~Q12~~ | ~~Multi-device per surveyor~~ — **CLOSED 2026-08-30.** ADR-0005 (D41): **in scope.** One `ACTIVE` session per `(user_id, device_id)`; the merge model must handle two devices of the same surveyor. | — | ADR-0005 |
| ~~Q13~~ | ~~RS256 signing-key custody and rotation~~ — **CLOSED 2026-08-30 by ADR-0008.** Custody by environment, 90-day rotation via a dual-`kid` overlap window. Proposed, awaiting owner sign-off. | — | ADR-0008 |
| Q14 | **`users.username` capture** — the login screen accepts a username but no signup step captures one. NULL at signup and set from Profile, or add an optional Step 2 input? | sprint_0003 | ADR-0005 open item 1 |
| Q15 | **`auth_events` retention period** — no retention policy exists; the table grows unbounded without one. | sprint_0017 | ADR-0005 open item 4 |

---

## 12. Recommended Next Development Action

**Obtain owner sign-off on the `sprint_0001` deliverables.** As of 2026-08-30, `sprint_0001` is functionally complete: `physical-schema.md` covers all 38 tables (identity slice finalized under ADR-0005; the workflow slice drafted in Part B, §16–§39, resolving Q2); `api-contract/openapi.yaml` is generated and lints clean; the first 12 migrations are structurally verified and CI-applies cleanly; the monorepo, Go backend, and React Native skeleton all build/vet/typecheck/test clean; ADR-0007, ADR-0008 and ADR-0009 are written (the first two Proposed, the third Accepted); the vendor tracker exists.

**Nothing in that list is self-approved.** The single artifact-independent action that unblocks the most downstream work now is **review, not drafting**: the physical schema, the API contract, and the two Proposed ADRs all need the project owner's explicit sign-off before `sprint_0003` can begin (`sprint_0001` §6 DoD, `CLAUDE.md` §16 Q12). Alongside review, two genuinely owner-only actions remain outstanding: opening the vendor accounts in `vendor-tracker.md` (starting with India SMS DLT registration, given its multi-week lead time) and applying the migrations to a real, persistent database for the first time.
