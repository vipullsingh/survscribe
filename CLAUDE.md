# Project Overview

> **Document type:** Persistent, evidence-based project context for **SurvScribe** (git repo directory still `SurveyAssist` — physical rename pending, see §16 Q1).
> **Created:** 2026-08-30 · **Last updated:** 2026-08-30 (Q&A resolutions folded in **and propagated into `documentation/`**; see §19).
> **Maintained by:** Future developers and AI agents working in this repository.
>
> Every statement below is tagged with one of:
> - **[Confirmed Requirement]** — explicitly stated in `documentation/` (SRS, User Stories, Screen Specs, Design System).
> - **[Confirmed — Q&A 2026-08-30]** — decided by the project owner during a clarification session on 2026-08-30, and **propagated into the `documentation/` source files the same day** (see §19 for the file-by-file record). Recorded in `documentation/decisions/ADR-0001`.
> - **[Implemented]** — demonstrably present as working code in the repository.
> - **[Planned / Referenced]** — named as intended/future work but not implemented.
> - **[Unconfirmed — clarification required]** — cannot be verified; still open.
>
> **The single most important fact:** As of 2026-08-30 this repository contains **documentation and design assets only**. There is **no application source code, no build configuration, no dependency manifests, no database, and no tests**. See §2.

---

## 1. Project Mission and Purpose

**[Confirmed Requirement]** The project is a specialized software platform to **assist licensed General Insurance Claim Surveyors and Loss Assessors (SLA)** in preparing insurance survey reports — primarily **Preliminary Survey Reports (PSR)** and **Final Survey Reports (FSR)**.
- Source: `README.md` lines 1–13; `documentation/Requirement.MD` §1.1.

**[Confirmed Requirement]** The platform manages a **15-stage general claim survey process** (Appointment Intake → Final Survey Report Submission) and is organized around five "core questions of loss assessment": what happened; what was damaged; is the damage connected to the incident; how much is the actual loss; what amount is reasonably recommended under policy terms.
- Source: `README.md` lines 6–14; `documentation/Requirement.MD` §1.1; `documentation/User Stories.md`.

**[Confirmed Requirement]** Stated core architectural principles:
- **Zero-hallucination AI**: AI narrative generation is bound strictly to verified surveyor inputs / OCR extractions / physical evidence; probabilistic generation of numbers, policy terms, dates, or causes is prohibited. Missing data must produce a `[SURVEYOR TO VERIFY]` placeholder.
- **Offline-first**: 100% of field actions (evidence capture, GPS tagging, voice notes, damage itemization, calculations) function without connectivity, with bi-directional sync.
- **Local / on-device LLM readiness**: a modular AI provider interface with cloud execution online and on-device model slots offline.
- **Future-proof RBAC schema**: DB schema embeds tenancy + role scopes without adding MVP UI complexity.
- **Editable `.docx` export** of PSR/FSR.
- Source: `documentation/Requirement.MD` §1.2; `README.md` §"Key Architectural Features".

**[Confirmed Requirement]** Regulatory positioning: the platform is *"a technology platform designed to assist licensed Insurance Surveyors and Loss Assessors in their professional workflow."* It must never claim to be an insurer, intermediary, IRDAI-approved entity, or autonomous claims decision-maker. AI must never approve/repudiate claims or dispatch reports autonomously. Final liability rests with the insurer; professional responsibility rests with the licensed surveyor.
- Source: `README.md` lines 3–4; `documentation/Requirement.MD` §1.3; `documentation/User Stories.md` §"Regulatory & Professional Responsibility Framework".

**[Confirmed — Q&A 2026-08-30, amended]** Canonical product name is **SurvScribe** **everywhere** — code, package names, UI, documentation, and the internal claim-reference prefix, which becomes **`SS-YYYY-XXXXX`** (offline temp: `TEMP-SS-XXXX`). *Still pending:* renaming the physical git repo directory `SurveyAssist` → `SurvScribe` and updating the git remote (manual — cannot be done from inside the working directory).

---

## 2. Current Development Status

### 2.1 What actually exists in the repository (verified 2026-08-30)

**[Implemented]** (as documents/assets only — no executable code):
- `README.md` — project summary.
- `documentation/Requirement.MD` — Software Requirements Specification, "Version 1.0.0-MVP", "Document Status: Approved Baseline".
- `documentation/User Stories.md` — 16 Epics (Epic 0 + Epics 1–16) with acceptance criteria.
- `documentation/Visual Theme & Design System.md` — "Version 2.0.0-Enterprise" design system (tokens, typography, components, layouts).
- `documentation/Screens/` — **17 screen specification folders** containing 19 spec markdown files:
  - `00_auth/` (`00_auth_login.md`, `00_auth_signup.md`, `00_auth_terms.md`, plus 8 SVGs in `designs/`)
  - `01_dashboard/` (spec only — **no SVG present** despite git commit `ea73c91`)
  - `02_...` through `16_...` (spec markdown only, no `designs/` folders)
- `documentation/assets/logo/` — 4 brand SVGs + `README.md`.
- Total SVG assets: 12 (4 logo, 8 screen designs).

**[Implemented]** Empty directory scaffolding (directory trees containing **zero files**; git reports the working tree "clean" only because git does not track empty directories):
- `apps/backend/` → `api/`, `cmd/{api,worker}/`, `internal/{config,handler,model,pkg,repository,server,service}/`, `migrations/`, `deployments/`, `pkg/{logger,response}/`, `scripts/`
- `apps/mobile/` → `assets/`, `src/{app,core}/`, `src/features/{ai-assistant,auth/{api,components,hooks,screens,store,types},evidence,inspection,surveys/{api,components,hooks,screens,store,types}}/`, `src/infrastructure/{media,network,storage}/`, `src/shared/{components,hooks,utils}/`, `src/types/`
- `packages/` → `api-contracts/`, `config/`, `types/`, `ui/`

(The former empty `docs/` scaffold was **deleted** on 2026-08-30; `documentation/decisions/` and `documentation/architecture/` were created with real content.)

**[Implemented] Partial monorepo skeleton** (verified 2026-08-30 — this corrects an earlier claim in this file that none of it existed):
- Root `package.json`, `pnpm-workspace.yaml`, `turbo.json`, `.gitignore`
- `apps/backend/go.mod` — `module github.com/vipullsingh/survscribe/backend`, `go 1.22`

**Still not present anywhere in the repo:** `go.sum`, any lockfile, per-package `package.json` for `packages/*`, `tsconfig`, `.env` / `.env.example`, CI config, Dockerfiles, database migrations, seed scripts, tests, linter/formatter configs, or any `.go` / `.ts` / `.tsx` / `.js` source file. `sprint_0001` task 5 completes the toolchain.

### 2.2 Implemented and working functionality

**None.** There is no runnable application, service, or test suite.

### 2.3 Partially implemented functionality

**None** in code. The only "partial" artifacts are design-side: only screens `00_auth_login`, `00_auth_signup`, `00_auth_terms` have visual SVG mockups; screens 01–16 have written specs but no visuals.

### 2.4 Planned / referenced functionality

Everything is planned. High-level scope (see §6 for detail):
- Auth (Stage 0): password + universal identifier login, Phone OTP, Email OTP, forgot password, offline session, registration, Terms screen.
- 15 workflow stages (Stage 1 Appointment Intake … Stage 15 Internal Review & Submission).
- 5 AI touchpoints: Voice-to-Text (AI-1), Document/Invoice OCR (AI-2), Cross-Check/Fraud Audit (AI-3), Report Draft Generator (AI-4, primary), Loss Assessment Calculator (AI-5, deterministic).
- Offline sync engine, RBAC-ready schema, `.docx` report engine.

### 2.5 Known incomplete / undecided areas (after 2026-08-30 Q&A)

Resolved on 2026-08-30 (see §18 decision log; still to be written into `documentation/` per §19):
product name, mobile framework, backend framework, `.docx` engine location, monorepo tooling, desktop-web MVP scope, mobile local DB, external-provider strategy, loss-math deduction order & underinsurance base, data-model expansion, GPS accuracy thresholds, salvage mode count, primary-blue token, docs-root consolidation, biometric scope, OTP timers, claim-ref prefix, insurable-interest enum, SLA-license mandatory/optional, Stage-15 gate count.

Still genuinely open — see §16:
- No project bootstrapping yet (no toolchain files, no first migrations, no API contract).
- Concrete external vendors (LLM, OCR, SMS, email, WhatsApp, maps) — deferred to ADRs.
- Session/token format & lifetime specifics.
- Depreciation scale data source.
- API contract conventions (versioning, error envelope, pagination, auth header).

---

## 3. Confirmed Requirements

Only requirements supported by evidence in `documentation/` **or** decided in the 2026-08-30 Q&A. Traceability in brackets.

### 3.1 Authentication & Registration (Stage 0)
- **CR-A1** Login supports a **Universal Identifier** (email OR custom username OR mobile phone) + password, with "Remember Me" (default `true`). [`Requirement.MD` FR-0.1; `User Stories.md` AC 0.1.1; `00_auth_login.md` §4]
- **CR-A2** Login also supports **Phone OTP** (6-digit SMS, **30-second** resend timer) and **Email OTP** (6-digit, **45-second** resend timer), each a mobile bottom-sheet modal. [`00_auth_login.md` §2.2; `User Stories.md` AC 0.1.2–0.1.3; **Q&A 2026-08-30** confirmed 30 s / 45 s — SRS FR-0.1 to be updated]
- **CR-A3** Password recovery / reset-link dispatch is provided. [`Requirement.MD` FR-0.1; `00_auth_login.md` §6]
- **CR-A4** Successful auth routes to `01_dashboard`. [`00_auth_login.md` §6; `User Stories.md` AC 0.1.1]
- **CR-A5** Registration captures: Full Legal Name, Surveyor Firm Name, Mobile Number, Email. [`Requirement.MD` FR-0.2; `00_auth_signup.md` §4]
- **CR-A6** Registration is a **2-step flow** (Step 1 personal/firm → Step 2 SLA credentials & security). [`00_auth_signup.md` §2.1]
- **CR-A7** SLA/IRDAI license number, SLA category, and base location are **OPTIONAL at signup**. License number is validated for **syntax/format only** (regex `SLA-[0-9]{4,8}`), explicitly **not** regulatory verification. Disclaimer required: *"License details are provided by the user and are subject to independent verification. Platform registration does not constitute regulatory approval or endorsement."* **However, final FSR generation is blocked until the surveyor's license number + category are present** (required for the report sign-off block). [`00_auth_signup.md` §4; **Q&A 2026-08-30** — SRS FR-0.2 / User Stories AC 0.2.1 to be reconciled to "optional at signup, required before FSR"]
- **CR-A8** SLA Category enum: **Fellow / Associate / Licentiate / Trainee**. [`Requirement.MD` FR-0.2; `00_auth_signup.md` §3]
- **CR-A9** Password creation requires a complexity meter; documented rule (signup screen): min 8 chars, ≥1 uppercase, ≥1 number, ≥1 special char. Terms-of-Service consent checkbox is mandatory. [`00_auth_signup.md` §4]
- **CR-A10** Registration **always creates a new store** (`store_id`) and makes the registrant its owner, assigning role scope `SURVEYOR` **and** granting the `ADMIN` role. A matching firm name never joins an existing store — joining is **invite-only** via `store_invites`. [`00_auth_signup.md` §5; **ADR-0005 D40**]
- **CR-A13** Every user carries `store_id` (their firm) and is itself the `client_id` referenced by other records. Signup provenance (IP, user agent, device, geo), login state (`last_login_at`/`_ip`, `previous_login_*`, `last_seen_at`, `login_count`), and logout state (`last_logout_at`, `last_logout_reason`, lockout counters) are persisted on `users`, with a full append-only `auth_events` log alongside. [**ADR-0005 D42**; `architecture/physical-schema.md` §6, §10]
- **CR-A14** RBAC is **database-driven**: `roles` / `permissions` / `role_permissions` / `user_roles`, multi-role per user, four immutable seeded system roles plus store-defined custom roles composed from a code-defined ~35-code permission catalogue. `claim_access_grants` scopes `INSURER_VIEWER` to individual claims. **Store isolation is enforced from the first endpoint; only per-permission UI gating is deferred.** [**ADR-0005 D39**; AC 16.2.2]
- **CR-A15** Identifier uniqueness (`email`, `mobile`, `username`) is **global**, not per-store — forced by universal-identifier login, which resolves a bare identifier with no store context. One human, one account. [**ADR-0005 D43**]
- **CR-A11** A dedicated Terms & Privacy screen (`00_auth_terms`) exists, reachable from signup, with Accept & Continue / Decline actions. [`00_auth_terms.md`]
- **CR-A12** Offline auth: encrypted session token cached in hardware keystore/keychain; offline access via cached token / **device passcode**; automatic session lock after **15 minutes** of background inactivity; **30-day maximum offline grace**, after which mutations block pending online re-authentication. **Biometric unlock (Face ID / fingerprint) is DEFERRED to post-MVP** — ADR-0003 §3.1 was amended to passcode-only on 2026-08-30, closing Q3. [`Requirement.MD` FR-0.3; `00_auth_login.md` §5; ADR-0003 §3; **ADR-0005 D41**]

### 3.2 Workflow / stage requirements
- **CR-W1** A **survey state machine** with 15 stages; each claim has a `current_stage`. Stage advance happens on each screen's primary "Save & Proceed…" action. [`Requirement.MD` §2.2, FR-1.3; every `Screens/*/*.md` §7]
- **CR-W2** Internal tracking reference format: **`SS-YYYY-XXXXX`** (example `SS-2026-00101`); offline-created claims get a temporary ID `TEMP-SS-XXXX` until synced. [`Requirement.MD` FR-1.3; `User Stories.md` AC 1.1.1; `01_dashboard.md` §6; `02_appointment_claim_intake.md` §7; **Q&A 2026-08-30** — renamed from `SA-` to `SS-` under the full-rename decision]
- **CR-W3** Stage 1 mandatory appointment attributes: `Requirement.MD` FR-1.2 and `02_appointment_claim_intake.md` §4.
- **CR-W4** Stage 2 records section-wise sums insured, policy validity, perils, warranties, excess/deductible. Loss date must fall within inception–expiry. [`Requirement.MD` FR-2.1; `03_policy_coverage_review.md`]
- **CR-W5** Stage 3 logs insured contact attempts, schedules the site visit (device-calendar sync), dispatches a standard **Evidence & Loss Preservation Notice** (WhatsApp/Email/SMS). [`Requirement.MD` FR-3.x; `04_insured_contact_schedule.md`]
- **CR-W6** Stage 4 captures device GPS (lat, lng, accuracy, altitude, timestamp) on arrival, compares physical loss location against policy risk address, raises `LOCATION_DISCREPANCY_DETECTED` with mandatory justification if they differ. **GPS accuracy: ≤ 10 m is the target (warn / prompt re-capture above 10 m); ≤ 50 m is the hard limit (block save above 50 m).** [`Requirement.MD` FR-4.x; `05_risk_location_verification.md`; **Q&A 2026-08-30**]
- **CR-W7** Stage 5 incident chronology builder + statutory evidence vault (FIR, Fire Brigade report, IMD weather, shift logs, CCTV notes, witness statements) + AI chronology consistency check (warn when time gaps exceed **2 hours**). [`Requirement.MD` FR-5.x; `User Stories.md` AC 5.1.3; `06_cause_investigation.md`]
- **CR-W8** Stage 6 damage register fields per `07_damage_inspection_studio.md` §4 / `Requirement.MD` FR-6.1. ≥ 1 photo per damaged item.
- **CR-W9** Stage 6 Smart Photo Studio: camera capture with **indelible watermark overlay** (timestamp, GPS coordinates, claim ref ID, surveyor ID) + mandatory 6-category tagging. Photos compressed on-device to **JPEG 1600×1200, 85% quality**, EXIF preserved. [`Requirement.MD` FR-6.2, §6.1; `07_damage_inspection_studio.md` §3]
- **CR-W10** Stage 7 ownership verification: link purchase invoices, Bill of Entry, FAR extracts, stock ledgers, GST returns, hypothecation/lease/mortgage. **Insurable-interest status enum: `Established` / `Under Verification` / `Incomplete Documentation` / `Disputed`** (4-state superset — reconcile all docs to this). [`Requirement.MD` FR-7.x; `08_ownership_document_locker.md`; **Q&A 2026-08-30**]
- **CR-W11** Stage 8 generates a peril-based Document Requisition Notice + assembles the **PSR**; exportable to `.docx`. Preliminary loss reserve is entered by the surveyor only — AI never generates it. [`Requirement.MD` FR-8.x; `09_preliminary_survey_report_psr.md`]
- **CR-W12** Stage 9 logs multiple follow-up visits (`visit_number` auto-increments from ≥ 2), findings, follow-up photos, stock reconciliation. [`Requirement.MD` FR-9.x; `10_followup_investigation.md`]
- **CR-W13** Stage 10 Document Locker + OCR pipeline: line-item extraction; AI cross-check flags `DUPLICATE_CLAIM_ITEM`, `RATE_INFLATION_DETECTED` (claimed rate > original invoice rate by **> 20%**), unlisted/obsolete items, betterment. Mandatory surveyor remark for any non-verified item. [`Requirement.MD` FR-10.x; `User Stories.md` AC 10.1.x; `11_document_verification_audit.md`]
- **CR-W14** Stage 11 head-wise loss quantification grid (Heads: Building/Civil, Plant & Machinery, Furniture/Fixtures/Fittings, Stocks, Other Insured Property) with the deterministic math engine (formulas in §11.1). Mandatory justification remark for every deduction; report finalization is **blocked** if any deduction remark is empty. [`Requirement.MD` FR-11.x; `User Stories.md` AC 11.1.x; `12_loss_assessment_quantification.md`]
- **CR-W15** Stage 12 salvage tracking. **Three disposal modes: Mode A — Retained by Insured; Mode B — Sold to Scrap Buyer; Mode C — Tender floated by Insurer.** Salvage value feeds the head-wise sheet / FSR Section F. [`13_salvage_disposal_manager.md`; **Q&A 2026-08-30** — SRS FR-12.2 to be updated to add Mode C]
- **CR-W16** Stage 13 decision-support coverage/liability workstation. Surveyor recommendation enum: **Admissible as Assessed / Subject to Insurer Liability Determination / Non-Admissible / Repudiation Recommended**. Every coverage remark must bear: *"Decision-support analysis for surveyor review. Final liability determination remains with the insurer."* Standard "Without Prejudice" declaration auto-included. AI must never make autonomous coverage decisions. [`Requirement.MD` FR-13.x; `User Stories.md` AC 13.1.x; `14_coverage_liability_opinion.md`]
- **CR-W17** Stage 14 compiles the standard **9-section FSR** (A Basic Info, B Risk Description, C Cause & Circumstances, D Survey Findings, E Documents Considered, F Loss Assessment Statement, G Policy Terms/Warranties/Deductibles, H Discrepancies/Observations, I Surveyor's Opinion & Final Recommendation "Without Prejudice"). AI Narrative Drafter (AI-4) drafts Sections **C, D, H, I** only. All AI text fully editable. [`Requirement.MD` FR-14.1–14.2; `15_final_survey_report_generator.md` §4]
- **CR-W18** **Mandatory 4-point Human Approval Gate** before any PSR/FSR `.docx` export/download:
  1. Surveyor has reviewed all AI-generated narrative content.
  2. Surveyor confirms factual accuracy of site observations, timelines, and damage items.
  3. Surveyor confirms calculations, depreciation scales, and policy-term interpretation.
  4. Final professional and legal responsibility remains with the licensed surveyor.
  [`Requirement.MD` FR-14.4; `User Stories.md` AC 14.2.5; `15_final_survey_report_generator.md` §3]
- **CR-W19** Stage 15 automated pre-submission audit has **7 compliance gates**: (1) Arithmetic Check (Section F totals to the rupee), (2) Metadata Consistency (Policy No / Claim No / Insured Name / Date of Loss across all sections + photo captions), (3) Deduction Remarks present, (4) Photo Annexure Compliance (caption + timestamp + GPS on every photo), (5) Document Completeness (mandatory docs for the peril), (6) Contradiction Scanner (Sections C/D/I), (7) Human Approval + AI Gate (all 4 CR-W18 checkboxes accepted, timestamped, in the immutable audit log). Final sign-off record + report archiving + **immutable SHA-256 hash snapshot** + dispatch tracking. [`Requirement.MD` FR-15.x; `User Stories.md` AC 15.1.x; `16_internal_review_submission.md`; **Q&A 2026-08-30** confirmed 7 — fix the "6" references in the screen spec]

### 3.3 AI system requirements
- **CR-AI1** Five AI modules with fixed roles and grounding datasets, per `Requirement.MD` §4.1. AI-4 (Report Draft Generator) is the "CORE"/primary feature.
- **CR-AI2** AI is encapsulated behind a provider interface — Go `AssistantService` (backend) and TypeScript `IAssistantService` (React Native mobile client). Online → cloud provider; offline → local on-device models (e.g., local Whisper STT, on-device SLM). [`Requirement.MD` §4.2]
- **CR-AI3** Human-in-the-loop governance: AI never dispatches reports, never approves/repudiates claims, never makes binding coverage determinations, never generates/alters numeric values. Every AI suggestion requires an affirmative human edit/accept/reject. [`Requirement.MD` §4.3]
- **CR-AI4** Missing input → `[SURVEYOR TO VERIFY]` placeholder, never an invented fact. [`Requirement.MD` §4.1 AI-4; `User Stories.md` AC 14.1.1]
- **CR-AI5** [Confirmed — Q&A 2026-08-30] External integrations are accessed through **provider-agnostic interfaces + a config-driven adapter pattern**. In addition to `AssistantService`, the docs will define interfaces such as `NotificationService` (SMS/email/WhatsApp) and `GeocodingService` (maps/reverse-geocode). **Concrete vendors are NOT chosen in the SRS** — each is selected later in an ADR under `documentation/decisions/`.

### 3.4 Non-functional requirements
- **CR-NF1** Media compression JPEG 1600×1200 @ 85%, EXIF + overlay preserved; upload retry with exponential backoff; background sync queue. [`Requirement.MD` §6.1]
- **CR-NF2** Local storage encryption: **WatermelonDB over SQLite with SQLCipher (AES-256)** on the React Native mobile app. [`Requirement.MD` §6.2; **Q&A 2026-08-30** — DB engine fixed to WatermelonDB]
- **CR-NF3** Transport: TLS 1.3 enforced for all API and media transport. [`Requirement.MD` §6.2]
- **CR-NF4** Immutable audit logs for every modification to loss-assessment figures (user, timestamp, field, old value, new value). [`Requirement.MD` §6.2]
- **CR-NF5** Performance benchmark: full 9-section `.docx` with up to 50 photo plates generates in **< 5 seconds** — this benchmark applies to the **server-side Go engine** (see §7.2 `.docx` decision). [`Requirement.MD` §6.3; **Q&A 2026-08-30**]
- **CR-NF6** Offline sync conflict resolution: field-level timestamp merging with surveyor confirmation on concurrent edits. [`Requirement.MD` §2.2; `User Stories.md` AC 16.1.3]
- **CR-NF7** Accessibility: WCAG 2.1 AA; ≥ 4.5:1 normal text contrast, 7:1 for financial figures; full keyboard navigation of data tables on desktop. [`Visual Theme & Design System.md` §7]

---

## 4. Requirements and Decisions Still Open

> Most items previously listed here were resolved in the 2026-08-30 Q&A and moved to §3 / §7 / §18. The remainder:

> **Closed since first writing:** vendors (ADR-0002), session token format and lifetime (ADR-0003), API contract conventions (ADR-0004), the `REVIEWER`/`ADMIN` capability matrix and the identity/RBAC schema (**ADR-0005** + `architecture/physical-schema.md` / `identity-and-rbac.md`), geo-IP provider (ADR-0006). The items below are what genuinely remain.

1. **[Unconfirmed — clarification required]** Source and content of the "standard surveyor / IRDAI / engineering depreciation scales" (Stage 11 AI-5). No scale tables or authoritative data source provided.
2. **[Unconfirmed — clarification required]** Full physical schema for the **10 core claim-workflow entities and §9.2 entities 15–20**. The identity slice (entities 11–13, 21–30) is finalized in `architecture/physical-schema.md`; the rest is `sprint_0001` task 1.
3. **[Unconfirmed — clarification required]** Exact worked example / numeric walk-through of the loss-assessment sequence for domain-expert sign-off (the order and base are decided in §11.1; a validated example is still worth producing).
4. **[Unconfirmed — clarification required]** RS256 signing-key custody and rotation — where the private key lives and how it is injected per environment. Flagged by ADR-0005; needs its own ADR (`sprint_0001` task 9 / sprints Q13).
5. **[Unconfirmed — clarification required]** `users.username` capture — the login screen accepts a username but no signup step captures one. Assumed NULL at signup and set from Profile; the alternative changes `00_auth_signup.md` §4 (sprints Q14).
6. **[Unconfirmed — clarification required]** `auth_events` retention period. No retention policy exists anywhere; the table grows unbounded without one (sprints Q15).
7. **[Unconfirmed — clarification required]** Keychain/Keystore wipe recovery (`sprint_0004` Q7) — forcing online re-auth is clear; the local-data-loss warning shown to the surveyor is not.
8. **[Unconfirmed — clarification required]** SLA licence format. `Requirement.MD` FR-0.2 / AC 0.2.2 specify `SLA-[0-9]{4,8}`; `00_auth_signup.md` §4 specifies *"`SLA-[0-9]{4,8}` or alphanumeric"* — materially looser. A **pre-existing contradiction**, surfaced rather than silently resolved. SRS treated as authoritative pending a decision; the DB holds only a loose sanity bound so the rule stays changeable without a migration. (`architecture/physical-schema.md` §6.5)

---

## 5. Users, Roles, and Permissions

**[Confirmed Requirement]** Role scope enum: `SURVEYOR`, `REVIEWER`, `ADMIN`, `INSURER_VIEWER`. [`Requirement.MD` §1.2, §5.1; `User Stories.md` AC 16.2.2]

**[Confirmed — ADR-0005 D39]** RBAC is **database-driven**, not a bare enum:
- `permissions` — a seeded, code-defined catalogue of ~35 `resource:action` codes. Never written at runtime; stores may compose roles but may not invent permissions.
- `roles` — four immutable **system roles** (the enum above, `store_id IS NULL`) plus **store-defined custom roles**. A `CHECK` makes the two states structurally exclusive.
- `role_permissions` / `user_roles` — many-to-many; **a user may hold multiple roles**.
- `users.access_role_scope` is retained as the denormalised primary role for display and SRS §5.1 compatibility. **`user_roles` is authoritative for authorization.**
- `users.permissions_version` (JWT `pv` claim) is incremented on any privilege change, so stale access tokens die within one 15-minute lifetime.
- Seeded matrices are in `architecture/physical-schema.md` §7.6–§7.7 — this closes the previously-undefined `REVIEWER`/`ADMIN` capability question.

**[Confirmed — ADR-0005 D39]** **The MVP enforcement boundary is narrower than "RBAC is future work" suggests.** Shipping in MVP: the tables, the middleware, `pv` revocation, and **store isolation on every endpoint**. Deferred post-MVP: per-permission gating of UI affordances, and the role-administration UI. Cross-store data separation is *never* deferred. [`User Stories.md` AC 16.2.2]

**[Confirmed — ADR-0005 D40]** Registration always creates a **new store**; the registrant becomes its owner with role scope `SURVEYOR` **and** the `ADMIN` role. Joining an existing store is **invite-only** (`store_invites`, SHA-256 token hash, expiring, single-use). Firm names are never auto-matched and `stores.firm_name` is deliberately not unique. [`00_auth_signup.md` §5]

**[Confirmed Requirement]** `INSURER_VIEWER` governance: explicit surveyor/firm authorization recorded as a **`claim_access_grants`** row; read-only; scoped to individual assigned claims; every view/download in an immutable audit log; surveyor retains data ownership of drafts/unverified photos until formal submission; bilateral data-sharing terms. Holding `insurer:claim:read` is necessary but **not sufficient** — a live grant for that claim is also required. [`Requirement.MD` §5.1; AC 16.2.3; ADR-0005 D39]

**[Confirmed — ADR-0005 D38]** Common columns on every operational entity: **`store_id`**, **`client_id`**, `assigned_surveyor_id`, `reviewer_id`, `access_role_scope`. (Renamed from `tenant_id` / `created_by_user_id`.) Identity tables carry `store_id` and `client_id` where an owner exists; global catalogue tables carry none. [`Requirement.MD` §5.1; `architecture/physical-schema.md` §1]

---

## 6. Core Workflows

All workflows below are **[Confirmed Requirement]** as specifications and **[Planned / Referenced]** as functionality (nothing is built). Screen folder number `NN` maps to workflow **Stage `NN − 1`** for screens `02`–`16`.

### 6.1 Authentication & onboarding (Stage 0)
`00_auth_login` (password OR Phone OTP modal OR Email OTP modal OR Forgot Password sheet) → `01_dashboard`.
`00_auth_login` → "Register as Surveyor" → `00_auth_signup` (Step 1 → Step 2, with `00_auth_terms` reachable) → creates account, assigns `SURVEYOR`, provisions offline session → `01_dashboard`.
Offline: authenticate via cached encrypted token / device passcode; 15-minute background auto-lock. (Biometric unlock post-MVP.)

### 6.2 Dashboard (Screen 01)
Pipeline overview of all claims across the 15 stages; stage filter pills; claim cards/table; FAB / "New Survey" → `02_appointment_claim_intake`. Offline banner shows pending-sync count; new offline claims get `TEMP-SS-XXXX` IDs.

### 6.3 The 15-stage survey pipeline
| Stage | Screen folder | Purpose (short) | Advance action |
| :-- | :-- | :-- | :-- |
| 1 | `02_appointment_claim_intake` | Record/parse insurer appointment; generate `SS-YYYY-XXXXX`; init state machine | → Stage 2 |
| 2 | `03_policy_coverage_review` | Policy schedule, section-wise SI, perils, warranties, excess; loss-date-in-period check | → Stage 3 |
| 3 | `04_insured_contact_schedule` | Contact log, schedule visit, dispatch Loss Preservation Notice | → Stage 4 |
| 4 | `05_risk_location_verification` | GPS capture, address compare, discrepancy flag + justification | → Stage 5 |
| 5 | `06_cause_investigation` | Incident chronology, statutory evidence vault, AI consistency check | → Stage 6 |
| 6 | `07_damage_inspection_studio` | Itemized damage register, watermarked photo studio, voice-to-text | → Stage 7 |
| 7 | `08_ownership_document_locker` | Ownership/insurable-interest docs, link to damage items | → Stage 8 |
| 8 | `09_preliminary_survey_report_psr` | Document requisition notice + PSR builder + `.docx` export | → Stage 9 |
| 9 | `10_followup_investigation` | Log follow-up visits, re-inspection, stock reconciliation | → Stage 10 |
| 10 | `11_document_verification_audit` | OCR line-items, forensic cross-check, discrepancy flags | → Stage 11 |
| 11 | `12_loss_assessment_quantification` | Head-wise deterministic loss calc grid; mandatory deduction remarks | → Stage 12 |
| 12 | `13_salvage_disposal_manager` | Salvage inventory, disposal mode (A/B/C), buyer/tender records; feed Section F | → Stage 13 |
| 13 | `14_coverage_liability_opinion` | Decision-support coverage/warranty/exclusion review; surveyor recommendation | → Stage 14 |
| 14 | `15_final_survey_report_generator` | Assemble 9-section FSR, AI drafts C/D/H/I, Section F table, photo annexure, Human Approval Gate, `.docx` export | → Stage 15 |
| 15 | `16_internal_review_submission` | 7 automated audit gates, digital sign-off, SHA-256 snapshot, dispatch to insurer | → `COMPLETED_SUBMITTED`, return to dashboard |

### 6.4 Cross-cutting workflows
- **Offline sync** (`User Stories.md` Epic 16): local persistence for every stage; auto-sync on reconnect with background media upload; field-level timestamp conflict resolution.
- **AI assist touchpoints** appear inline within the relevant stage screens (never a floating chatbot — see §12).

### 6.5 Incomplete workflow areas (marked)
- **No visual design** for stages 1–15 beyond written spec (only auth screens have SVGs).
- **Desktop web views** in every screen spec §2.2 are **post-MVP** (see §7.2) — treat them as forward-looking, not MVP build targets.
- **RBAC-gated flows** (reviewer approval, insurer portal) are future and have no screen specs.
- **Sync conflict UI** ("surveyor confirmation" dialog) is described in one line only — no detailed spec.

---

## 7. Technical Architecture

### 7.1 Status
**[Planned / Referenced]** — nothing is implemented. The `apps/` and `packages/` folders are empty scaffolds. The stack below is now **decided** (2026-08-30) but not yet bootstrapped.

### 7.2 Decided stack (2026-08-30 Q&A + `Requirement.MD` §2.2)

| Layer | Technology | Basis |
| :-- | :-- | :-- |
| **Product name** | **SurvScribe** across all aspects — code, packages, UI, docs, and the claim-ref prefix (`SS-YYYY-XXXXX`). Physical repo-dir rename `SurveyAssist`→`SurvScribe` + git-remote update still pending. | Q&A 2026-08-30 |
| **Mobile client** | **React Native + TypeScript**. Feature-first layout (`apps/mobile/src/features/<feature>/{api,components,hooks,screens,store,types}`) + `src/infrastructure/` + `src/shared/`. Primary and only MVP client. | Q&A 2026-08-30 |
| **Mobile local DB** | **WatermelonDB** (reactive ORM over **SQLite**), encrypted with **SQLCipher (AES-256)**. Backs the offline store + sync queue. | Q&A 2026-08-30 |
| **Desktop web** | **Deferred to post-MVP.** Screen-spec "Responsive Desktop Web View" sections are forward-looking design only. When built: React + shared `packages/` TS types. | Q&A 2026-08-30 |
| **Backend** | **Go (Golang)** + **Gin** framework, **REST/JSON** API. **gRPC dropped from MVP.** Standard `cmd/ + internal/ + pkg/` layout. `pgx` driver + connection pooling. | Q&A 2026-08-30; `Requirement.MD` §2.2 |
| **Backend concurrency** | Goroutine-powered concurrent media sync + chunked photo upload pipeline. | `Requirement.MD` §2.2 |
| **State machine** | Claim pipeline state machine + audit-trail engine (15 stages), in the Go backend. | `Requirement.MD` §2.2 |
| **`.docx` engine** | **Two engines with a shared template contract.** (1) **Client-side** (TS) generation on the mobile app for **offline PSR/FSR drafts**. (2) **Authoritative server-side Go engine** for the **final compiled report**; the `< 5 s` / 50-plate benchmark (CR-NF5) applies here. Formatting parity between the two is a shared spec. | Q&A 2026-08-30 |
| **Server database** | **PostgreSQL** (via `pgx`). | `Requirement.MD` §2.2 |
| **AI orchestration** | `AssistantService` (Go) / `IAssistantService` (TS) with **Cloud** (online) and **Local/on-device** (offline) provider modes. Local: Whisper STT, on-device SLM. Vendors via ADR. | `Requirement.MD` §4.2; Q&A 2026-08-30 |
| **External integrations** | Provider-agnostic interfaces (`NotificationService`, `GeocodingService`, …) + config-driven adapters. Concrete vendors chosen per-integration in `documentation/decisions/` ADRs. | Q&A 2026-08-30 |
| **Monorepo tooling** | **pnpm workspaces + Turborepo** for the JS/TS packages (`apps/mobile`, future `apps/web`, `packages/*`). The **Go backend keeps its own `go.mod`** and is built separately (optionally wired into Turbo tasks). | Q&A 2026-08-30 |
| **Transport security** | TLS 1.3. | `Requirement.MD` §6.2 |
| **Local security** | Hardware keystore/keychain for the session token; SQLCipher AES-256 at rest. | `Requirement.MD` §6.2 |
| **Docs root** | Single root: **`documentation/`**. Empty `docs/` tree **deleted 2026-08-30**; ADRs live in `documentation/decisions/`, architecture in `documentation/architecture/`. | Q&A 2026-08-30 |

### 7.3 Intended system layers (`Requirement.MD` §2.2 diagram)
UI layer (RN mobile app; web later) → offline-first client data layer (WatermelonDB/SQLCipher + media store + sync queue with field-level timestamp merge) → Go/Gin backend REST API (media sync pipeline, state machine + audit engine, server `.docx` engine, PostgreSQL via pgx) → modular AI orchestration layer (provider interface → cloud LLM / cloud OCR / local models).

### 7.4 Authentication architecture
**[Confirmed — ADR-0003 as amended by ADR-0005]** Dual token: **RS256 JWT access token, 15 min**, claims `sub`/`store_id`/`client_id`/`sid`/`roles[]`/`perms[]`/`pv`; **opaque 64-byte refresh token, 30 days**, Argon2id-hashed in `sessions.refresh_token_hash`, rotated on every use with `refresh_token_family_id` reuse detection. Tokens live in iOS Keychain / Android Keystore. Offline access via cached token or **device passcode**; 15-minute background auto-lock; 30-day offline grace. OTP via SMS (30 s resend) and email (45 s resend); universal-identifier resolution (email/username/phone, globally unique). Biometric unlock post-MVP. Middleware chain: `RequestID → RealIP → Authenticate → StoreScope → RequirePermission`. Full specification in [`documentation/architecture/identity-and-rbac.md`](documentation/architecture/identity-and-rbac.md). **Signing-key custody / rotation remains open (§4 item 4).**

---

## 8. Codebase Structure

```
SurveyAssist/  (git dir; product name = SurvScribe — physical rename pending)
├── README.md                         # Project summary & feature list (design intent)
├── CLAUDE.md                          # This file — living project context
│
├── documentation/                    # THE SINGLE DOCS ROOT
│   ├── Requirement.MD                # SRS v1.0.0-MVP ("Approved Baseline") + §2.3 stack baseline
│   ├── User Stories.md               # Epic 0 + Epics 1–16, acceptance criteria
│   ├── Visual Theme & Design System.md  # Design system v2.0.0-Enterprise
│   ├── decisions/                    # ADR log — README index + ADR-0001…0006
│   │                                 #   0001 stack/scope · 0002 vendors · 0003 auth tokens
│   │                                 #   0004 API+schema rules · 0005 identity model · 0006 geo-IP
│   ├── architecture/                 # physical-schema.md (identity slice FINAL, claim entities pending)
│   │                                 #   identity-and-rbac.md (FINAL)
│   │                                 #   api-contract/, sync-protocol.md, diagrams — not started
│   ├── sprints/                      # Master MVP roadmap + 17 individual sprint execution plans
│   ├── assets/logo/                  # 4 brand SVGs + README (brand colors, symbolism)
│   └── Screens/                      # 17 screen spec folders
│       ├── 00_auth/        (00_auth_login.md, 00_auth_signup.md, 00_auth_terms.md + designs/ 8 SVGs)
│       ├── 01_dashboard/   (01_dashboard.md — NO designs/)
│       └── 02_… through 16_…  (<folder_name>.md only, NO designs/)
│
├── package.json  pnpm-workspace.yaml  turbo.json  .gitignore   # partial monorepo skeleton
│
├── apps/                             # SCAFFOLD — only apps/backend/go.mod has content
│   ├── backend/                      # Go/Gin: go.mod, api/, cmd/{api,worker}/,
│   │                                #   internal/{config,handler,model,pkg,repository,server,service}/,
│   │                                #   migrations/, deployments/, pkg/{logger,response}/, scripts/
│   └── mobile/                       # React Native: assets/, src/{app,core}/,
│                                     #   src/features/{ai-assistant,auth,evidence,inspection,surveys}/,
│                                     #   src/infrastructure/{media,network,storage}/,
│                                     #   src/shared/{components,hooks,utils}/, src/types/
│
└── packages/                         # EMPTY SCAFFOLD (no files) — pnpm workspace pkgs
    ├── api-contracts/  config/  types/  ui/
```
(The former empty `docs/` tree was deleted on 2026-08-30.)

**Where to look for authority today:** `documentation/Requirement.MD` (SRS) is the top-level source; `documentation/User Stories.md` refines it into testable ACs; `documentation/Screens/<name>/<name>.md` is the most detailed layer. **When the SRS and a screen spec disagree, this `CLAUDE.md` §3 / §18 records the resolved answer — use that, and update the underlying doc per §19.**

**Screen ↔ Stage numbering:** screen folder `NN` = Stage `NN−1` (screens 02–16). Screen 00 = Stage 0 (auth, 3 sub-screens). Screen 01 = global dashboard (no stage).

---

## 9. Data Model

**[Confirmed Requirement — schema-level]** From `Requirement.MD` §5.2. **The identity slice is finalized DDL** in [`documentation/architecture/physical-schema.md`](documentation/architecture/physical-schema.md) (ADR-0005). The claim-workflow entities below remain indicative SRS field lists, not finalized DDL. **No migrations exist yet** — `sprint_0001` task 2 emits the first set, covering all entities at once, and never runs them automatically.

**Common columns on every operational entity** (`Requirement.MD` §5.1 as amended by **ADR-0005 D38**): **`store_id`** (UUID), **`client_id`** (UUID), `assigned_surveyor_id` (UUID), `reviewer_id` (UUID), `access_role_scope` (enum `SURVEYOR|REVIEWER|ADMIN|INSURER_VIEWER`). Identity tables carry `store_id` + `client_id` where an owner exists; global catalogue tables (`permissions`) carry none; `stores` is the tenancy root and carries none.

### 9.1 SRS §5.2 core entities (existing)
| Entity | Key fields (from SRS §5.2) |
| :-- | :-- |
| `claims` | `id`, `store_id`, `client_id`, `claim_ref_no`, `policy_no`, `insurer_name`, `insured_name`, `loss_date`, `peril`, `status`, `current_stage`, `created_at`, `updated_at` |
| `policy_details` | `id`, `claim_id`, `policy_type`, `inception_date`, `expiry_date`, `sum_insured_total`, `excess_clause`, `warranties_json` |
| `site_visits` | `id`, `claim_id`, `visit_no`, `visit_date`, `gps_lat`, `gps_lng`, `actual_location_address`, `location_discrepancy_flag` |
| `cause_investigations` | `id`, `claim_id`, `incident_datetime`, `discovery_datetime`, `reported_cause`, `sequence_of_events`, `fir_details`, `fire_report_details` |
| `damage_items` | `id`, `claim_id`, `head_category`, `description`, `make_model_serial`, `qty`, `uom`, `damage_extent`, `repair_or_replace`, `pre_existing_damage` |
| `media_attachments` | `id`, `claim_id`, `damage_item_id`, `file_uri`, `thumbnail_uri`, `media_type`, `category_tag`, `gps_lat`, `gps_lng`, `timestamp`, `caption` |
| `documents` | `id`, `claim_id`, `doc_type`, `file_name`, `file_uri`, `ocr_status`, `ocr_data_json`, `verified_flag` |
| `assessment_line_items` | `id`, `claim_id`, `head_category`, `description`, `claimed_amount`, `assessed_gross`, `depreciation_pct`, `depreciation_amount`, `betterment_amount`, `salvage_amount`, `underinsurance_deduction`, `excess_deduction`, `net_recommended`, `justification_remarks` |
| `salvage_records` | `id`, `claim_id`, `description`, `qty_weight`, `disposal_mode`, `buyer_info`, `realized_amount` |
| `final_survey_reports` | `id`, `claim_id`, `section_a_json` … `section_i_json`, `docx_file_uri`, `generated_at`, `status` |

### 9.2 Identity, RBAC & auth telemetry — [Confirmed — ADR-0005, FINALIZED DDL]
Complete DDL in `architecture/physical-schema.md`. **Do not redesign these; extend them.**

| Entity | Role |
| :-- | :-- |
| `stores` | The surveyor firm / parent company — the tenancy root. Renames `tenants`. `firm_name` deliberately **not** unique. |
| `users` | The **client** / employee. `users.id` *is* the `client_id` on every other table. Carries credentials, SLA fields, lifecycle status, verification timestamps, ToS version, full signup provenance (IP + UA + device + geo), login state (`last_login_*`, `previous_login_*`, `last_seen_at`, `login_count`), and logout/lockout state. Identifier uniqueness is **global** (D43). |
| `sessions` | One per device per login. `refresh_token_hash` (Argon2id — renamed from `encrypted_token_ref`), `refresh_token_family_id` for reuse detection, origin IP + geo, status, logout/revoke reason. Multi-device supported (D41). |
| `user_devices` | Stable device identity across sessions; the anchor for remote revoke. |
| `permissions` · `roles` · `role_permissions` · `user_roles` | DB-driven RBAC (D39). Seeded catalogue + four system roles + store custom roles; multi-role per user. |
| `claim_access_grants` | Per-claim, time-boxed, revocable `INSURER_VIEWER` scoping — SRS §5.1 rule 2. |
| `auth_events` | Append-only security telemetry, 22 event types. Immutable via trigger **and** `REVOKE UPDATE, DELETE`. Deliberately separate from `audit_log`. |
| `store_invites` | The only path into an existing store (D40). SHA-256 token hash, expiring, single-use. |
| `otp_challenges` · `password_reset_tokens` | Defined now, wired later (OTP blocked on Twilio India DLT / R4; reset blocked on the email vendor). Only hashes stored, never plain codes. |

### 9.2b Claim-workflow entities still to be drafted — [Confirmed — D27, draft pending review]
`sync_queue`, `audit_log`, `contact_logs`, `follow_up_visits` (separate table or an extension of `site_visits` — Q2), `coverage_opinions`, `requisition_notices`, `preservation_notices` (candidate — may fold into `contact_logs`/`documents`). `sprint_0001` task 1 produces their DDL.

### 9.3 Data flow (intended)
Stage 0 → `stores` + `users` + `sessions` + `user_devices` + `user_roles` + `auth_events`; Stage 1 → `claims` + `claim_ref_no`; Stage 2 → `policy_details`; Stage 3 → `contact_logs` + `preservation_notices`; Stage 4 → `site_visits`; Stage 5 → `cause_investigations`; Stage 6 → `damage_items` + `media_attachments`; Stages 7 & 10 → `documents` (+ OCR JSON); Stage 8 → `requisition_notices` + PSR; Stage 9 → `follow_up_visits`; Stage 11 → `assessment_line_items`; Stage 12 → `salvage_records` (feeds `assessment_line_items.salvage_amount` / FSR Section F); Stage 13 → `coverage_opinions`; Stage 14 → `final_survey_reports`; Stage 15 → status lock + SHA-256 hash snapshot; all figure edits → `audit_log`; all authentication actions → `auth_events`.

**[Unconfirmed — clarification required]:** physical schema for the claim-workflow entities — §4 item 2. The identity slice is done.

---

## 10. APIs and External Integrations

### 10.1 Internal API
**[Planned / Referenced]** Go **Gin** REST/JSON API. **No endpoints, no OpenAPI file, no routes exist.** `packages/api-contracts/` (moving conceptually under `documentation/architecture/`) is reserved for the contract.

### 10.2 AI provider interface (contract defined, not implemented)
**[Confirmed Requirement]** `Requirement.MD` §4.2:
- Go: `AssistantService` — `TranscribeAudio`, `ExtractDocumentLineItems`, `AuditClaimDiscrepancies`, `GenerateReportNarrative`.
- TypeScript: `IAssistantService` — `transcribeAudio`, `extractDocumentLineItems`, `auditClaimDiscrepancies`, `generateReportNarrative`.
- Modes: `CloudAssistantService` (online) / `LocalAssistantService` (offline).

### 10.3 External integrations — interfaces now, vendors via ADR [Confirmed — Q&A 2026-08-30]
Provider-agnostic interfaces + config-driven adapters. Integration points:
- Cloud LLM API — AI narrative drafting & audit (AI-3, AI-4).
- Cloud OCR API — invoice/bill/appointment-letter extraction (AI-2).
- On-device models — local Whisper STT, on-device SLM (offline AI-1/AI-4).
- SMS gateway — Phone OTP (`NotificationService`).
- Email service — Email OTP, report dispatch, requisition/preservation notices (`NotificationService`).
- WhatsApp — Loss Preservation Notice & document requisition dispatch; `whatsapp:` deep links on mobile (`NotificationService`).
- Telephony — `tel:` deep links for insured contact.
- Device GPS hardware — geotagging (offline capable).
- Maps / reverse geocoding — address verification, distance variance, Stage 4 (`GeocodingService`).
- Native device calendar — site-visit scheduling (`.ics` / native event).
- Insurer portals — FSR upload dispatch option (Stage 15).

**[Unconfirmed — clarification required]:** every concrete vendor, key management, rate limits, data-residency constraints — one ADR per integration.

---

## 11. Business Rules and Validation

All **[Confirmed Requirement]** / **[Confirmed — Q&A 2026-08-30]** as written; none enforced in code yet.

### 11.1 Loss quantification math (Stage 11) — [Confirmed — Q&A 2026-08-30]
Per-line-item, in this **strict sequence**:
1. `Gross Assessed = Assessed Quantity × Verified Unit Rate`
2. `Depreciation Amount = Gross Assessed × (Depreciation % / 100)`
3. `Net of Depreciation = Gross Assessed − Depreciation Amount − Betterment Deduction`
4. **Underinsurance / Average Clause** — base is **Net of Depreciation**: if `Value at Risk (VAR) > Sum Insured (SI)` then `Underinsurance Deduction = Net of Depreciation × (1 − SI/VAR)`; else `0`.
5. `After Underinsurance = Net of Depreciation − Underinsurance Deduction`
6. `After Salvage = After Underinsurance − Salvage Realization`
7. `Net Recommended = After Salvage − Policy Excess`

Order (canonical): **Gross Assessed → less Depreciation → less Betterment → less Underinsurance → less Salvage → less Policy Excess = Net Recommended.**
- Field validations (`12_loss_assessment_quantification.md` §5): `gross_assessed ≤ claimed_amount`; `depreciation_pct` 0.0–90.0%; amounts ≥ 0.
- **Mandatory remarks:** `justification_remarks` required whenever `gross_assessed < claimed` / for any deduction/disallowance. Report finalization is **blocked** if any deduction line has an empty remark. [`User Stories.md` AC 11.1.5; `Requirement.MD` FR-11.3]
- The SRS/User-Stories wording is to be reconciled to this exact sequence and base (§19).

### 11.2 Forensic audit rules (Stage 10)
- `RATE_INFLATION_DETECTED` when claimed rate exceeds original purchase-invoice rate by **> 20%**.
- `DUPLICATE_CLAIM_ITEM` when an item description or invoice number appears twice across claim bills.
- `audit_deduction_reason` mandatory when `audit_status != Verified`.
- [`User Stories.md` AC 10.1.x; `11_document_verification_audit.md`]

### 11.3 Location discrepancy (Stage 4) — [Confirmed — Q&A 2026-08-30]
- GPS accuracy: **≤ 10 m target** (warn / prompt re-capture above 10 m); **≤ 50 m hard limit** (block save above 50 m).
- `discrepancy_remarks` mandatory when `location_discrepancy = true`.
- [`05_risk_location_verification.md` §4; `Requirement.MD` FR-4.3]

### 11.4 Chronology consistency (Stage 5)
- AI warns when reported loss time vs fire-brigade/log timestamps diverge by **> 2 hours**.
- `discovery_datetime ≥ incident_datetime`; `fire_brigade_call_time` mandatory for Fire claims.
- [`06_cause_investigation.md` §4; `User Stories.md` AC 5.1.3]

### 11.5 Policy period (Stage 2)
- Date of loss must fall within `inception_date`–`expiry_date`; `expiry_date ≥ inception_date`; at least one head with Sum Insured > 0. [`03_policy_coverage_review.md` §4]

### 11.6 Appointment intake (Stage 1)
- `appointment_date` not in the future; `date_of_loss` ≤ `appointment_date`; policy number ≥ 6 alphanumeric chars; insured phone 10 digits (India +91).
- Duplicate-claim warning on matching Policy No + Loss Date.
- [`02_appointment_claim_intake.md` §4–5]

### 11.7 Auth validation
- `login_identifier`: valid email OR 10-digit mobile (+91) OR alphanumeric username.
- OTP codes: exactly 6 numeric digits. Phone OTP resend 30 s; Email OTP resend 45 s.
- Signup password: min 8 chars, ≥1 uppercase, ≥1 number, ≥1 special char; `terms_accepted` must be `true`.
- SLA license syntax: regex `SLA-[0-9]{4,8}` (format only). License #, category, base location **optional at signup**; license # + category **required before FSR generation**.
- [`00_auth_login.md` §4; `00_auth_signup.md` §4; Q&A 2026-08-30]

### 11.8 Salvage (Stage 12) — [Confirmed — Q&A 2026-08-30]
- Disposal mode is one of: **Mode A — Retained by Insured**, **Mode B — Sold to Scrap Buyer**, **Mode C — Tender floated by Insurer**.
- Mode B / C require buyer/tender details + payment proof (`13_salvage_disposal_manager.md` §4).
- Net realized salvage feeds `assessment_line_items.salvage_amount` / FSR Section F.

### 11.9 Report export gates
- 4-point **Human Approval Gate** all checked before `.docx` export unlocks (§3 CR-W18).
- Stage 15 **7 audit gates** must pass before submission (§3 CR-W19).
- Every exported `.docx` embeds "Without Prejudice" + regulatory disclaimers (`Requirement.MD` §4.3, FR-14.3).

### 11.10 Media rules
- Photos: JPEG 1600×1200 @ 85%, EXIF preserved, indelible watermark (timestamp, GPS, claim ref, surveyor ID). ≥ 1 photo per damaged item.
- [`Requirement.MD` §6.1, FR-6.2; `07_damage_inspection_studio.md` §4]

### 11.11 Insurable interest (Stage 7) — [Confirmed — Q&A 2026-08-30]
- Status enum: **`Established` / `Under Verification` / `Incomplete Documentation` / `Disputed`**. Reconcile all docs to this 4-state set.

---

## 12. UI/UX and Design Context

**[Confirmed Requirement]** Source: `documentation/Visual Theme & Design System.md` (v2.0.0-Enterprise) + `documentation/assets/logo/README.md`.

### 12.1 Design philosophy
"Enterprise Precision, Operational Trust & Field Ergonomics." Mature B2B financial/insurance SaaS tone (reference points: FactSet, Guidewire, Linear). Deliberately **not** consumer-app / Dribbble / generic-AI-dashboard aesthetics.

### 12.2 Hard anti-patterns (prohibited) — `Design System.md` §2
No excessive gradients / glowing edges; no neon/cyberpunk accents; no oversized rounded cards (>20px radius); no floating widgets or chatbots; no heavy glassmorphism/blur; no decorative "sparkles"/AI icons; no gamified progress steppers; no huge display headings; no competing badge noise.

> `README.md` line 54 ("glassmorphic micro-surfaces", "Deep Cobalt #1E40AF") predates and partly conflicts with the stricter Design System v2.0.0. **`Visual Theme & Design System.md` is the authority**; README prose to be corrected (§19).

### 12.3 Core tokens
- **Primary blue — [Confirmed — Q&A 2026-08-30]:** `--color-primary: #1E3A8A`, `--color-primary-hover: #1E40AF`, `--color-primary-active: #172554`, `--color-primary-subtle: #EFF6FF`. Keep the design-system scale. README prose to be aligned; **logo SVGs stay `#1E40AF`** as an intentional brand-mark shade.
- Canvas `#F8FAFC`; surface `#FFFFFF`; text primary `#0F172A`, secondary `#475569`, muted `#94A3B8`; borders `#E2E8F0` / `#CBD5E1` / `#94A3B8`.
- Semantic: success `#059669` (bg `#F0FDF4`, border `#BBF7D0`); warning `#D97706` (bg `#FFFBEB`, border `#FDE68A`); critical `#DC2626` (bg `#FEF2F2`, border `#FECACA`); link `#2563EB`.
- **Status color semantics are strict:** green = verified, amber = warning, red = critical blocker. Nothing else.
- **Typography:** Plus Jakarta Sans (headings/labels) + Inter/system (body) + **JetBrains Mono** for all financial figures, policy numbers, GPS coords, serials. Scale table in `Design System.md` §3.2.
- **Numbers:** right-aligned, tabular figures (`"tnum" 1, "zero" 1`), comma separators (Indian lakh/crore grouping), `₹` prefix chip.
- **Spacing:** 8pt grid (4pt sub-unit). Tokens `--space-1..8` = 4/8/12/16/20/24/32 px.
- **Radii:** `--radius-xs..lg` = 4/6/8/12 px. Form controls 6–10px; surface cards 8–12px.
- **Icons:** Lucide / Heroicons outline, strict 1.5px stroke; sizes 16 / 20 / 24 px.
- **Buttons / inputs / shadows:** CSS in `Design System.md` §4.1–4.2, §3.1. Input height 44px mobile / 38px desktop; focus `1.5px #1E3A8A` + 3px ring.

### 12.4 Layout patterns
- **Mobile (primary):** sticky header (claim ref + insured + sync/offline badge), touch targets ≥ 44–48px, sticky bottom action bar ("Save & Continue to <next stage>"), 5-item bottom nav, bottom-sheet modals for OTP. (Exact bottom-nav labels differ slightly between `Design System.md` §6.1 and `01_dashboard.md` §2.1 — reconcile in §19.)
- **Desktop companion (post-MVP):** collapsible lifecycle sidebar; 50/50 split-screen verification layouts; contextual right-hand inspector; dense keyboard-navigable grids.
- **15-stage tracker:** professional linear pipeline — completed `(✓)` `#059669`, active `(●)` `#1E3A8A`, upcoming `(○)` `#94A3B8`; inline amber warning tags.
- **Loss matrix (Stage 11):** authoritative financial ledger — header `#F1F5F9` / 11px bold uppercase `#475569`; alternating `#F8FAFC` rows; subtotal row top border `2px #0F172A`, bold 14px mono; expandable justification chevrons.
- **Evidence cards:** `1px #E2E8F0` border, 8px radius; watermark banner `rgba(15,23,42,0.85)` white monospace; explicit audit-linkage tag to the Stage 6 item / Stage 10 invoice.

### 12.5 AI UI framing — `Design System.md` §5
Inline utilities with objective labels: "Draft Narrative with Field Notes", "Extract Invoice Line Items", "Check Claim Discrepancies", "Record Voice Field Note", "Review Applicable Warranties". Never "Magic AI Write", sparkles, or chatbot widgets. Discrepancy findings render as structured audit boxes (`#FFFBEB` / `1px #FDE68A` / `#92400E`) with a resolution action link.

### 12.6 Brand assets
`documentation/assets/logo/`: `logo_icon.svg` (512² emblem), `logo_app_icon.svg` (512² squircle launcher), `logo_horizontal_light.svg` / `logo_horizontal_dark.svg` (840×180). Logo palette: Cobalt `#1E40AF`, Electric Azure `#3B82F6`, Obsidian Slate `#0F172A`, Scribe Gold `#F59E0B`, Emerald Mint `#10B981`.

### 12.7 Delivered visual mockups
SVG artboards exist **only** for: `00_auth_login` (main, otp_tab, phone-otp modal, email-otp modal, forgot-password), `00_auth_signup` (step1, step2), `00_auth_terms`. Artboard size `375 × 812` (iOS). No SVGs for the dashboard or stages 1–15.

### 12.8 "No placeholder content" rule
`Design System.md` §7.3: every screen must use authentic insurance terminology, not lorem ipsum.

---

## 13. Development Conventions

### 13.1 Established conventions (observable)
- **Git commit messages:** Conventional Commits — `feat:`, `refactor:`, `docs:`, `chore:`, `design:`, `feat(ui):`. Continue this.
- **Screen spec files:** `NN_snake_case_name/` containing `NN_snake_case_name.md` (auth-login nests it under `description/`). Fixed section template: 1 Objective, 2 Layout (Mobile then Desktop), 3 Component Hierarchy, 4 Data Fields/Types/Validations table, 5 AI Integration, 6 Offline/Sync, 7 Action Triggers & Navigation.
- **Design SVGs:** `<screen>/designs/`, named `<screen_name>[_variant].svg`, `375 × 812`.
- **Field naming in specs:** `snake_case` data fields; `PascalCase` named UI components.
- **Enums in specs:** Title Case value strings; role scopes UPPER_SNAKE; status codes UPPER_SNAKE (`LOCATION_DISCREPANCY_DETECTED`, `STATUS_DRAFT_OFFLINE`).
- **Currency:** Indian numbering, `₹`, monospace, right-aligned.
- **Scaffold layout intent:** Go backend `cmd/ + internal/ + pkg/`; mobile **feature-first** (`src/features/<feature>/{api,components,hooks,screens,store,types}`) + `src/infrastructure/` + `src/shared/`; shared code in `packages/`.
- **Monorepo:** pnpm workspaces + Turborepo (JS/TS); Go backend separate `go.mod`.
- **ADRs:** to live in `documentation/decisions/`, one file per decision.

### 13.2 Not yet established (do not invent — ask / open an ADR)
- No linter/formatter config (ESLint/Prettier/golangci-lint) yet.
- No testing framework / test-naming / coverage convention yet.
- No branching strategy documented (all commits on `main`).
- No API versioning / error-envelope / pagination convention yet.
- No `.editorconfig`, no `.gitignore` yet.

---

## 14. Important Constraints — DO NOT BREAK

1. **Regulatory positioning is non-negotiable.** Never present the platform as an insurer, intermediary, IRDAI-approved body, or autonomous claims decision-maker. (`Requirement.MD` §1.3)
2. **AI is never autonomous on decisions or numbers.** No feature may let AI approve/repudiate a claim, dispatch a report, set/alter a monetary value, or make a binding coverage call. AI output is always draft, human-editable, human-gated. (`Requirement.MD` §4.3)
3. **Zero-hallucination grounding.** AI narrative consumes only structured, verified Stage 1–13 data. Missing input ⇒ literal `[SURVEYOR TO VERIFY]`. (`Requirement.MD` §4.1; `User Stories.md` AC 14.1.1)
4. **The 4-point Human Approval Gate blocks `.docx` export.** All four checkboxes set + recorded in the immutable audit log before any PSR/FSR document generates or downloads. (`Requirement.MD` FR-14.4)
5. **Deterministic financial engine.** All loss-assessment arithmetic is pure deterministic formula evaluation (§11.1), in the fixed sequence, with underinsurance based on net-of-depreciation. Section F totals reconcile to the rupee. (`Requirement.MD` FR-11.x, §4.3; `User Stories.md` AC 15.1.1)
6. **Mandatory deduction justifications.** Every rate cut / depreciation / betterment / salvage / disallowance needs a non-empty `justification_remarks`; finalization blocked otherwise. (`User Stories.md` AC 11.1.5)
7. **Offline-first is a hard requirement.** Every one of the 15 stages works fully offline. No server round-trip on any critical field path. (`Requirement.MD` §1.2, §2.1)
8. **Bi-directional sync with field-level timestamp conflict resolution.** Not last-write-wins. (`Requirement.MD` §2.2; `User Stories.md` AC 16.1.3)
9. **Indelible photo watermarking + category tagging.** Every photo carries timestamp, GPS, claim ref, surveyor ID + a mandatory category tag; photos link to the item/invoice they evidence. (`Requirement.MD` FR-6.2)
10. **Encryption + audit.** Local: WatermelonDB/SQLite + SQLCipher AES-256. Transport: TLS 1.3. Immutable audit log for every loss-assessment figure change and every insurer file access. (`Requirement.MD` §6.2, §5.1)
11. **RBAC schema columns exist from day one** (`store_id`, `client_id`, `assigned_surveyor_id`, `reviewer_id`, `access_role_scope`). **Store isolation is enforced from the first endpoint** — `store_id` comes from the verified JWT, never from a request body, query string, or path, and every repository method takes it as its first scope argument. Only *per-permission UI gating* is deferred. (`Requirement.MD` §5.1; ADR-0005 D38/D39; `identity-and-rbac.md` §3.2)
17. **Auth secrets are never stored reversibly or logged.** Passwords, refresh tokens and OTP codes are Argon2id-hashed; invite and reset tokens are SHA-256-hashed; failed logins store only a hash of the attempted identifier. No password, token, OTP, or raw failed identifier may appear in any column, log line, or crash report. `auth_events` is append-only at the database level. (ADR-0005 D42; `sprint_0003` DoD)
12. **9-section FSR structure and Section-to-Stage mapping** (A–I + Annexure) is an industry-standard contract — identity and ordering must not change. (`15_final_survey_report_generator.md` §4)
13. **The 15-stage sequence and screen↔stage numbering** (`NN` folder = Stage `NN−1`) is the backbone of navigation, the state machine, and the specs. Renumbering breaks all cross-references.
14. **Standard disclaimers embedded in every export** ("Without Prejudice", "Decision-support analysis for surveyor review. Final liability determination remains with the insurer.", registration disclaimer). Do not remove.
15. **Design system anti-patterns (§12.2)** are explicit acceptance-checklist gates (`Design System.md` §8) — new UI must pass them.
16. **`.docx` formatting parity.** The offline client engine and the authoritative server Go engine must produce equivalent documents from the same shared template contract. Do not let them drift.

---

## 15. Known Issues and Technical Debt

1. **No implementation exists.** The gap between `documentation/` (detailed, "Approved Baseline") and code (zero) is the entire project risk surface.
2. **Empty scaffold directories are untracked by git.** `apps/` and `packages/` show nothing in `git status` because git ignores empty dirs; a fresh clone won't contain them. Add real content + `.gitkeep`/README stubs when bootstrapping.
3. **~~`documentation/` source files not yet updated~~ — DONE 2026-08-30.** The 2026-08-30 decisions have been propagated into the SRS, User Stories, Visual Design System, README, and the affected screen specs; `documentation/decisions/ADR-0001` records them; the empty `docs/` tree was deleted. Remaining doc-adjacent follow-ups: physical repo-dir rename `SurveyAssist`→`SurvScribe`, monorepo bootstrap files, and the `00_auth_terms.svg` legal-copy "biometric" line (rendered asset). See §19.
4. **`README.md` repo-structure section is stale** — says "18 Dedicated Screen Specification Folders" and "designs/ (4 vector artboards)" for login; actual counts are 19 folders and 5 login SVGs; omits `00_auth_terms`.
5. **Dashboard SVG missing** — commit `ea73c91` claims a Screen 01 SVG mockup; none is present in `01_dashboard/`.
6. **Bottom-nav labels differ** between `Design System.md` §6.1 and `01_dashboard.md` §2.1 — reconcile.
7. **~~No provider/vendor decisions~~ — RESOLVED.** ADR-0002 fixes SMS (Twilio, AWS SNS fallback), email (SendGrid), maps, LLM and OCR vendors; ADR-0006 fixes geo-IP (local MaxMind GeoLite2). Remaining external dependency is operational, not architectural: **Twilio India SMS DLT registration takes weeks** (risk R4), which is why OTP login is deferred out of `sprint_0003`.
8. **No environment/config strategy** — no `.env.example`, config schema, or secrets-management approach documented. **RS256 signing-key custody and rotation is the sharpest instance** (§4 item 4, sprints Q13) and blocks a production-grade `sprint_0003`.
9. **Depreciation scale data source undefined** (§4 item 1).
10. **~~Session token format / lifetime / refresh undefined~~ — RESOLVED** by ADR-0003 as amended by ADR-0005 (§7.4).
11. **`auth_events` has no retention policy** — the table grows unbounded (§4 item 6).
12. **`users.username` is accepted at login but captured by no signup step** — assumed NULL at signup, settable from Profile; unconfirmed (§4 item 5).

---

## 16. Open Questions

> **Closed:** ~~Q1~~ (monorepo bootstrapped — root `package.json`, `pnpm-workspace.yaml`, `turbo.json`, `apps/backend/go.mod` and `.gitignore` are committed), ~~Q2~~ (ADR-0002 + ADR-0006), ~~Q3~~ (ADR-0003 as amended by ADR-0005), ~~Q5~~ (ADR-0004), ~~Q7~~ (ADR-0005 D39 — seeded role/permission matrices in `architecture/physical-schema.md` §7.6–§7.7). **Q4 is half-closed:** the identity slice is finalized DDL; the claim-workflow entities are not.

### Critical — blocks development
- **Q4.** Physical schema for the **claim-workflow entities** (§9.1 + §9.2b): column types, PK/FK, indexes, enum value lists, JSON payload shapes. `sprint_0001` task 1. (§4 item 2)
- **Q12.** **Owner approval of the identity contract** — `architecture/physical-schema.md` and `identity-and-rbac.md`. `sprint_0001` R8 requires owner sign-off before `sprint_0003` starts. Nothing is self-approved.

### Important — affects implementation or architecture
- **Q6.** Source/content of the standard surveyor / IRDAI depreciation scales for AI-5. (§4 item 1)
- **Q8.** Produce a worked numeric example of the §11.1 loss sequence for domain-expert sign-off. (§4 item 3)
- **Q13.** RS256 signing-key custody and rotation — needs its own ADR. (§4 item 4)
- **Q14.** `users.username` capture — NULL at signup and set from Profile, or an optional input in signup Step 2? (§4 item 5)
- **Q15.** `auth_events` retention period. (§4 item 6)
- **Q16.** Keychain/Keystore wipe recovery and the local-data-loss warning. (§4 item 7)
- **Q17.** **SLA licence format contradiction** — `Requirement.MD` FR-0.2 and AC 0.2.2 say `SLA-[0-9]{4,8}`; `00_auth_signup.md` §4 says *"`SLA-[0-9]{4,8}` **or alphanumeric**"*. The SRS is treated as authoritative pending your call; the DB holds only a loose sanity bound so the rule can change without a migration. (§4 item 8)

### Later — does not currently block progress
- **Q9.** Reconcile bottom-nav labels between the design system and the dashboard spec. (§15 item 6)
- **Q10.** Recreate the missing Screen 01 (dashboard) SVG, and add SVGs / Figma frames for stages 1–15 before building those screens. (§15 item 5)
- **Q11.** Linter/formatter, testing framework, branching strategy, `.editorconfig` — decide when the first code lands. (§13.2)

---

## 17. Recommended Next Steps

**Recommendations, not confirmed requirements.**

1. **Propagate the 2026-08-30 decisions into `documentation/`** using the §19 checklist, so the SRS/specs stop contradicting the decision log. Small, mechanical, high-value.
2. **(DONE 2026-08-30)** `documentation/decisions/` created with `ADR-0001` capturing the Q&A decisions; empty `docs/` tree deleted; `documentation/architecture/` placeholder created. Split ADR-0001 into per-decision ADRs later if finer traceability is wanted.
3. **(PARTLY DONE)** Root `package.json`, `pnpm-workspace.yaml`, `turbo.json`, `.gitignore` and `apps/backend/go.mod` are committed. Still owed: per-package `package.json` for `packages/*`, base `tsconfig`, lockfile, linter/formatter config, CI — `sprint_0001` task 5.
4. **(IDENTITY SLICE DONE 2026-08-30)** `architecture/physical-schema.md` and `architecture/identity-and-rbac.md` finalize `stores`, `users`, `sessions`, `user_devices`, the RBAC tables, `claim_access_grants`, `auth_events`, `store_invites`, `otp_challenges` and `password_reset_tokens` under ADR-0005/0006, and `Requirement.MD` §5.2 now carries entities 21–30. **Next:** owner approval (§16 Q12), then DDL for the claim-workflow entities, then the first migrations under `apps/backend/migrations/` — all entities in one set, never auto-executed.
5. **Define `packages/api-contracts/`** — an OpenAPI spec for the Gin backend, plus `packages/types/` shared TS types generated from it.
6. **Implement the deterministic loss-assessment engine first, with tests**, as a pure module in `packages/` (no I/O). It is the highest-risk correctness surface and is fully specified (§11.1). Verifiable without infrastructure.
7. **Build `AssistantService` / `IAssistantService` + `NotificationService` + `GeocodingService` as stubs** (Local/Cloud split, fake impls) so feature work can proceed before vendor selection.
8. **Start UI on the fully-designed auth screens** (`00_auth_login`, `00_auth_signup`, `00_auth_terms`) to establish the `packages/ui/` component library against the design system.
9. **Produce dashboard + stage 1–15 visual designs** before implementing those screens, per the project's "spec + design then build" pattern.

---

## 18. Project Decision Log

| # | Decision | Status | Evidence |
| :-- | :-- | :-- | :-- |
| D1 | Product is an **assistive** tool for licensed SLA surveyors; never an adjudicator/insurer/IRDAI body. | Confirmed | `Requirement.MD` §1.3; `README.md` L3–4 |
| D2 | Scope = the **15-stage** claim survey lifecycle (+ Stage 0 auth). | Confirmed | `Requirement.MD` §3; `User Stories.md` |
| D3 | **Mobile-first, offline-first**; every stage has a dedicated mobile view. | Confirmed | `Requirement.MD` §2.1; commit `62f882a` |
| D4 | **Five AI modules** with fixed roles (AI-1 voice, AI-2 OCR, AI-3 audit, AI-4 narrative [primary], AI-5 calculator). | Confirmed | `Requirement.MD` §4.1 |
| D5 | AI is **non-autonomous**, zero-hallucination, human-in-the-loop; deterministic math engine for all numbers. | Confirmed | `Requirement.MD` §4.3 |
| D6 | AI via a **provider interface** (`AssistantService` Go / `IAssistantService` TS), Cloud (online) + Local/on-device (offline) modes. | Confirmed | `Requirement.MD` §4.2 |
| D7 | **4-point Human Approval Gate** mandatory before any PSR/FSR `.docx` export. | Confirmed | `Requirement.MD` FR-14.4 |
| D8 | **9-section FSR** standard structure (A–I + photo annexure); AI drafts C/D/H/I only. | Confirmed | `15_final_survey_report_generator.md` §4 |
| D9 | Reports export as **editable Microsoft Word `.docx`** (PSR and FSR). | Confirmed | `Requirement.MD` §1.2, FR-8.2, FR-14.3 |
| D10 | **RBAC-ready schema** now (tenant + role-scope columns on all entities), enforcement deferred; roles `SURVEYOR/REVIEWER/ADMIN/INSURER_VIEWER`. | Confirmed | `Requirement.MD` §5.1; `User Stories.md` AC 16.2.2 |
| D11 | Local storage encrypted with **SQLCipher AES-256**; transport **TLS 1.3**; immutable audit logs. | Confirmed | `Requirement.MD` §6.2 |
| D12 | Field photos: **JPEG 1600×1200 @ 85%**, EXIF preserved, indelible watermark, mandatory 6-category tagging. | Confirmed | `Requirement.MD` §6.1, FR-6.2 |
| D13 | Offline sync = **bi-directional, field-level timestamp merge** with surveyor confirmation on conflict. | Confirmed | `Requirement.MD` §2.2; `User Stories.md` AC 16.1.3 |
| D14 | Internal claim reference **`SS-YYYY-XXXXX`**; offline temp IDs `TEMP-SS-XXXX`. (Renamed from `SA-` by D18/D37.) | Confirmed | `Requirement.MD` FR-1.3; `01_dashboard.md` §6 |
| D15 | SLA license field is **syntax-validated only** (`SLA-[0-9]{4,8}`), not regulatory verification; disclaimer required. | Confirmed | `Requirement.MD` FR-0.2 |
| D16 | Design system = **"Enterprise Precision"**; strict anti-pattern list; Plus Jakarta Sans + Inter + JetBrains Mono; 8pt grid; green/amber/red-only status colors. | Confirmed | `Visual Theme & Design System.md` v2.0.0 |
| D17 | Repo is a **monorepo**: `apps/{backend,mobile}` + shared `packages/{api-contracts,config,types,ui}`. | Confirmed | directory scaffold |
| **D18** | **Canonical product name = "SurvScribe"** for code/packages/UI. | Confirmed — Q&A 2026-08-30 | this session; ADR-0001 |
| **D37** | **Full rename** (amends D18): "SurvScribe" applies **everywhere**, including the internal claim-ref prefix → **`SS-YYYY-XXXXX`** / `TEMP-SS-XXXX`. All `documentation/` files updated. Physical repo-dir rename + git-remote update remain a manual follow-up. | Confirmed — user instruction 2026-08-30 | this session; ADR-0001 |
| **D19** | **Mobile client = React Native + TypeScript.** Feature-first `apps/mobile/src` layout. | Confirmed — Q&A 2026-08-30 | this session |
| **D20** | **Mobile local DB = WatermelonDB** (over SQLite) + **SQLCipher (AES-256)**. | Confirmed — Q&A 2026-08-30 | this session |
| **D21** | **Backend = Go + Gin, REST/JSON.** **gRPC dropped from MVP.** `pgx` + PostgreSQL. | Confirmed — Q&A 2026-08-30 | this session |
| **D22** | **`.docx` generation = dual engine.** Offline client (TS) for drafts + authoritative server-side Go engine for final reports; shared template contract; `<5 s`/50-plate benchmark applies to the server engine. | Confirmed — Q&A 2026-08-30 | this session |
| **D23** | **Monorepo tooling = pnpm workspaces + Turborepo** for JS/TS; Go backend keeps its own `go.mod`, built separately. | Confirmed — Q&A 2026-08-30 | this session |
| **D24** | **Desktop web app = DEFERRED to post-MVP.** MVP ships the React Native mobile app only; screen-spec desktop views are forward-looking design. | Confirmed — Q&A 2026-08-30 | this session |
| **D25** | **External integrations = provider-agnostic interfaces + config-driven adapters now; concrete vendors chosen per-integration in ADRs.** Add `NotificationService`, `GeocodingService` interfaces. | Confirmed — Q&A 2026-08-30 | this session |
| **D26** | **Loss-assessment deduction sequence** = Gross Assessed → less Depreciation → less Betterment → less Underinsurance → less Salvage → less Policy Excess. **Underinsurance (Average Clause) base = Net of Depreciation**: `Deduction = NetOfDepreciation × (1 − SI/VAR)` when `VAR > SI`. | Confirmed — Q&A 2026-08-30 | this session |
| **D27** | **Data model to be EXPANDED**: add `users`/`surveyors`, `tenants`, `sessions`, `audit_log`, `sync_queue`, `contact_logs`, `follow_up_visits`, `coverage_opinions`, `requisition_notices` (+ candidate `preservation_notices`) to SRS §5.2 (draft pending review). *(Superseded in part by D38–D43: `tenants`→`stores`; `users`/`stores`/`sessions` are finalized DDL, not draft.)* | Confirmed — Q&A 2026-08-30 | this session |
| **D28** | **Stage 4 GPS accuracy** = ≤ 10 m target (warn/re-capture above), ≤ 50 m hard limit (block save above). | Confirmed — Q&A 2026-08-30 | this session |
| **D29** | **Stage 12 salvage = three disposal modes**: A Retained by Insured, B Sold to Scrap Buyer, C Tender floated by Insurer. Add Mode C to SRS FR-12.2. | Confirmed — Q&A 2026-08-30 | this session |
| **D30** | **Primary brand blue** = `#1E3A8A` (primary) / `#1E40AF` (hover), per the design-system token scale. README prose to align; logo SVGs stay `#1E40AF`. | Confirmed — Q&A 2026-08-30 | this session |
| **D31** | **Single docs root = `documentation/`.** Delete the empty `docs/` tree; ADRs → `documentation/decisions/`, architecture → `documentation/architecture/`. | Confirmed — Q&A 2026-08-30 | this session |
| **D32** | **Biometric unlock = DEFERRED to post-MVP.** MVP uses cached encrypted token + device passcode only. Remove stale biometric references from docs. | Confirmed — Q&A 2026-08-30 | this session |
| **D33** | **OTP resend timers** = Phone 30 s, Email 45 s. Update SRS FR-0.1 to state both explicitly. | Confirmed — Q&A 2026-08-30 | this session |
| **D34** | **Insurable-interest status enum** = `Established` / `Under Verification` / `Incomplete Documentation` / `Disputed` (4-state). Reconcile all docs. | Confirmed — Q&A 2026-08-30 | this session |
| **D35** | **SLA license #, category, base location = OPTIONAL at signup**; license # + category **required before FSR generation** (sign-off block). Reconcile SRS FR-0.2 / User Stories AC 0.2.1. | Confirmed — Q&A 2026-08-30 | this session |
| **D36** | **Stage 15 pre-submission audit = 7 compliance gates** (see §3 CR-W19). Fix the "6" references in `16_internal_review_submission.md`. | Confirmed — Q&A 2026-08-30 | this session |
| **D38** | **`store` replaces `tenant`; `client` replaces `created_by_user_id`.** `tenants`→`stores`, `tenant_id`→`store_id`, `created_by_user_id`→`client_id`. One name each — no aliases. Amends SRS §5.1, ADR-0004 §4, AC 16.2. Taken while zero migrations and zero source files existed. | Confirmed — ADR-0005, 2026-08-30 | ADR-0005 |
| **D39** | **Full DB-driven RBAC**: `permissions` (seeded, code-defined, ~35 codes) / `roles` (4 immutable system + store custom) / `role_permissions` / `user_roles` (multi-role) / `claim_access_grants` (per-claim `INSURER_VIEWER` scoping). `users.permissions_version` → JWT `pv` gives ≤15-min revocation. Defines the `permissions` claim ADR-0003 named but never specified, and closes the `REVIEWER`/`ADMIN` matrix question. **Store isolation ships in MVP; only per-permission UI gating is deferred.** | Confirmed — ADR-0005, 2026-08-30 | ADR-0005 |
| **D40** | **Invite-only store join.** Registration always creates a new store; the registrant becomes owner with `SURVEYOR` scope **and** the `ADMIN` role. Joining an existing store requires an ADMIN-issued single-use expiring invite. Firm names are never auto-matched; `stores.firm_name` is not unique. Closes `sprint_0003` Q8. | Confirmed — ADR-0005, 2026-08-30 | ADR-0005 |
| **D41** | **Multi-device sessions** with rotation + family reuse detection. One `ACTIVE` session per `(user_id, device_id)`. Closes `sprint_0002` Q12. Two corrections: `sessions.encrypted_token_ref` → **`refresh_token_hash`** (ADR-0003 mandates hashing, not reversible encryption); **ADR-0003 §3.1 amended to passcode-only**, closing Q3. | Confirmed — ADR-0005, 2026-08-30 | ADR-0005 |
| **D42** | **Full auth telemetry.** Denormalised signup-provenance / login / logout / lockout columns on `users` and `sessions`, plus an append-only **`auth_events`** table (22 event types, immutable by trigger *and* `REVOKE UPDATE, DELETE`). Deliberately separate from `audit_log`. Failed logins store only a SHA-256 of the attempted identifier. | Confirmed — ADR-0005, 2026-08-30 | ADR-0005 |
| **D43** | **Identifier uniqueness (`email`, `mobile`, `username`) is GLOBAL, not per-store** — forced by universal-identifier login, which resolves a bare identifier with no store context. One human, one account. | Confirmed — ADR-0005, 2026-08-30 | ADR-0005 |
| **D44** | **Geo-IP via `GeoIPService` + local MaxMind GeoLite2 `.mmdb`** — no PII egress, no latency on the auth path, no availability coupling. Enrichment is best-effort; every geo column is nullable and a failure never blocks authentication. Geo-IP is a signal, never evidence, and never substitutes for GPS in `site_visits`. | Confirmed — ADR-0006, 2026-08-30 | ADR-0006 |

---

## 19. `documentation/` Reconciliation — Status

The 2026-08-30 decisions (§18 D18–D37, then D38–D44) have been **applied to `documentation/`**.

### 19.0 Identity model finalization — completed 2026-08-30 (ADR-0005 / ADR-0006, D38–D44)

**New documents**
- [x] **`documentation/architecture/physical-schema.md`** — finalized DDL for the identity slice: `stores`, `users`, `permissions`, `roles`, `role_permissions`, `user_roles`, `claim_access_grants`, `sessions`, `user_devices`, `auth_events`, `store_invites`, `otp_challenges`, `password_reset_tokens`. Includes the enum type list, partial unique indexes, `CHECK` constraints, the append-only trigger, the deferred-FK resolution for the `stores`↔`users` cycle, the seeded permission catalogue and role matrices, an ER summary, open items, and a requirement-traceability table.
- [x] **`documentation/architecture/identity-and-rbac.md`** — token contract (JWT claim set, `pv` revocation, rotation, family reuse detection), request pipeline (`RequestID → RealIP → Authenticate → StoreScope → RequirePermission`), the four auth flows, telemetry policy, API surface with error codes, Go and React Native layouts, and a threat model.
- [x] **`documentation/decisions/ADR-0005-identity-model-store-client-and-rbac.md`** — D38–D43.
- [x] **`documentation/decisions/ADR-0006-geoip-provider.md`** — D44.

**Amended**
- [x] **`Requirement.MD`** — §5.1 five common columns → `store_id`/`client_id`, plus the "where the five columns apply" rule and the DB-driven RBAC paragraph; §5.2 entity 1 `claims`, entity 11 `users` (finalized), entity 12 `tenants`→`stores`, entity 13 `sessions` (finalized, `refresh_token_hash`), entity 14 `audit_log`; **new entities 21–30** for RBAC, grants, devices, `auth_events`, invites, OTP and reset tokens.
- [x] **`User Stories.md`** — Story 16.2 narrative + AC 16.2.1–16.2.3 renamed to `store_id`/`client_id`, plus new **AC 16.2.4** (multi-role) and **AC 16.2.5** (immediate privilege revocation); new **AC 0.2.5** (store creation & founder role) and **AC 0.2.6** (signup provenance); new **Story 0.3** (invites, AC 0.3.1–0.3.3) and **Story 0.4** (sessions & sign-out, AC 0.4.1–0.4.5).
- [x] **`ADR-0003`** — status marked amended; §1 JWT claim set restated and the refresh-token storage/rotation model added; **§3.1 amended to device passcode only** (closes Q3).
- [x] **`ADR-0004`** — §4 tenant-isolation rule → `store_id UUID NOT NULL REFERENCES stores(id)`, with the scope qualification.
- [x] **`decisions/README.md`** — ADR-0005 and ADR-0006 indexed; new **amendment chain** table.
- [x] **`architecture/README.md`** — both new documents listed as delivered.
- [x] **`sprints/README.md`** — Q3, Q8, Q12 struck through as closed; **Q13/Q14/Q15 added**; contradiction table updated for the biometric, `tenant_id` and `encrypted_token_ref` items; §12 next-action rewritten.
- [x] **`sprint_0001`** — task 1 scoped to the remaining entities (identity slice pre-finalized); **task 8 conventions ADR renumbered 0005 → ADR-0007** (0005/0006 were taken) and task 9 key-custody ADR labelled ADR-0008; ACs updated to `store_id`/`client_id` and 30 entities; R8 narrowed; Q3 closed, Q13 added.
- [x] **`sprint_0003`** — task 1 rewritten (`stores`, `user_devices`, always-new-store registration, family reuse detection, logout-all); **new tasks 8–11** (RBAC foundation, store invites, auth telemetry, session management); ACs extended (no enumeration oracle, cross-store negative test, provenance, append-only events, no secrets in logs); **Q8 closed**; concurrent-refresh risk and Q14 added.
- [x] **`sprint_0002`** — task 7 and Q12 closed: multi-device is in scope and the merge model must handle it.
- [x] **`sprint_0004`** — task 4 and Q3 closed (passcode-only).
- [x] **`sprint_0015`** — task 3/4/5 renamed to store scoping and `store_id`/`client_id`; **new tasks 9 and 10** (auth-telemetry integrity, token lifecycle).
- [x] **`Screens/00_auth/00_auth_signup.md`** — §5 rewritten: store initialization (always new, invite-only join), dual role assignment, signup provenance, session provisioning, and the `username` gap noted.
- [x] **`CLAUDE.md`** — §3.1 (CR-A10 rewritten; **CR-A13/A14/A15 added**; CR-A12 extended), §4 (stale items closed, real remainder listed), §5 (rewritten for DB-driven RBAC and the MVP enforcement boundary), §7.4, §9 (common columns, `claims`, new §9.2 finalized-DDL table and §9.2b, data flow), §14 (item 11 rewritten, **item 17 added**), §15, §16, §18 (**D38–D44**), and this §19.0.

**Not done — deliberately**
- Migration files. `sprint_0001` task 2 owns them, requires all entities in one set, and its runbook states migrations are never executed automatically.
- Any Go or TypeScript source. That is `sprint_0003`.
- DDL for the claim-workflow entities. `sprint_0001` task 1.

### 19.1 Completed 2026-08-30
- [x] **`README.md`** — SurvScribe naming note (full rename); repo-structure counts fixed (19 screen folders, 5 login SVGs, `00_auth_terms` added, `decisions/` + `architecture/` listed, `apps/`/`packages/` shown); primary blue prose aligned to `#1E3A8A`/`#1E40AF`; "glassmorphic micro-surfaces" softened; mobile = React Native, backend = Gin/REST (no gRPC), web = post-MVP, `.docx` = dual engine; monorepo tooling note.
- [x] **`documentation/Requirement.MD`** — new **§2.3 Confirmed Technology Stack** table; §2.1/§2.2 rewritten (React Native, WatermelonDB/SQLCipher, Gin/REST, server `.docx` engine, web post-MVP); §4.2 provider-agnostic integration policy (`NotificationService`, `GeocodingService`, vendors via ADR); §5.2 additional entities 11–20 (draft); FR-0.1 OTP 30 s/45 s; FR-0.2 SLA optional at signup / required before FSR; FR-1.3 `SS-YYYY-XXXXX`; FR-4.1 GPS 10 m/50 m; FR-11.2 full deduction chain + underinsurance on net-of-depreciation; FR-11.3 blocking rule; FR-12.2 three salvage modes; FR-15.1 explicit 7 gates + SHA-256.
- [x] **`documentation/User Stories.md`** — design-paradigm note (React Native, web post-MVP); AC 0.2.1/0.2.2 (license optional at signup, required before FSR); AC 1.1.1 `SS-2026-00101`; AC 4.1.1 GPS 10 m/50 m; AC 11.1.3–11.1.4 (underinsurance on net-of-depreciation, sequence); AC 12.1.2 three salvage modes.
- [x] **`documentation/Visual Theme & Design System.md`** — canonical primary-blue note (`#1E3A8A`/`#1E40AF`); §6.1 canonical 5-tab bottom nav (`Dashboard · Claims · Field Studio · Reports · Profile`); §6.2 marked POST-MVP; `SA-2026-00101` → `SS-2026-00101` (×3).
- [x] **`documentation/Screens/00_auth_login/description/00_auth_login.md`** — hard-coded `file:///…/SurveyAssist/…` design links replaced with relative `../designs/…` paths. (Timers already 30 s/45 s; no biometric text present.)
- [x] **`documentation/Screens/00_auth_signup/00_auth_signup.md`** — added "license fields optional at signup; License # + Category required before FSR generation" note.
- [x] **`documentation/Screens/01_dashboard/01_dashboard.md`** — `TEMP-SS-XXXX`; canonical 5-tab bottom nav.
- [x] **`documentation/Screens/02_appointment_claim_intake/02_appointment_claim_intake.md`** — Survey ID `SS-YYYY-XXXXX`.
- [x] **`documentation/Screens/05_risk_location_verification/05_risk_location_verification.md`** — GPS `AccuracyGate` (10 m target / 50 m hard limit) in §3.1 and §4.
- [x] **`documentation/Screens/08_ownership_document_locker/08_ownership_document_locker.md`** — insurable-interest enum → `Established / Under Verification / Incomplete Documentation / Disputed` (×3).
- [x] **`documentation/Screens/12_loss_assessment_quantification/12_loss_assessment_quantification.md`** — §4 tightened formula chain (`After Underinsurance`) + worked numeric example.
- [x] **`documentation/Screens/13_salvage_disposal_manager/13_salvage_disposal_manager.md`** — §2.1 mode selector shows all three modes A/B/C.
- [x] **`documentation/Screens/16_internal_review_submission/16_internal_review_submission.md`** — "6 gates" / "6 core" → 7 (§2.1 and §7).
- [x] **Repo** — empty `docs/` deleted; `documentation/decisions/` (README + ADR-0001) and `documentation/architecture/` (README) created.

### 19.2 Still pending (not doc edits — infra / manual)
- [ ] Rename the physical git repo directory `SurveyAssist` → `SurvScribe` and update the git remote. *(Cannot be done from inside the working directory; manual step.)*
- [ ] Bootstrap the monorepo: root `package.json`, `pnpm-workspace.yaml`, `turbo.json`, `apps/backend/go.mod`, `.gitignore`, and `.gitkeep`/README stubs in `apps/*` and `packages/*`.
- [ ] `documentation/Screens/00_auth_terms/designs/00_auth_terms.svg` — legal-copy line still mentions "Biometric authentication keys". Low priority (rendered mockup asset); update when the terms screen is re-exported.
- [ ] Split ADR-0001 into per-decision ADRs if/when finer traceability is wanted (currently one consolidated record covers D18–D37).
- [ ] Pending vendor / schema / API-convention ADRs — see `documentation/decisions/README.md`.

---

# MANDATORY DEVELOPMENT RULES FOR AI AGENTS AND DEVELOPERS

## Understand before changing
- Read this `CLAUDE.md` (especially §3, §14, §18) before starting any significant task.
- Inspect the relevant `documentation/` spec(s) and any existing code before modifying.
- Search for usages and cross-references (screen specs reference each other and the SRS by ID).
- Understand existing patterns (spec template, feature-folder layout, Conventional Commits) before introducing new ones.
- Make the smallest safe change that accomplishes the task.

## Never assume
- Never invent requirements, business rules, calculations, workflows, roles, or config values.
- Never resolve a documented contradiction by silently picking a side — check §18 for a decided answer; if none, surface it and ask.
- Treat **[Unconfirmed — clarification required]** items as unresolved. Ask.
- If critical information is missing, stop and ask rather than guessing.

## Git safety — no autonomous git actions
Unless the user explicitly instructs otherwise in the current task:
- Never run `git commit`, `git push`, `git merge`, `git rebase`, `git reset`, `git revert`, `git cherry-pick`.
- Never create, delete, rename, or switch branches; never amend commits; never force-push; never rewrite history; never change git config.
- Read-only git inspection (`status`, `log`, `diff`, `show`) is fine when needed.

## Script & command safety
- Before running any command, know what it does, whether it writes files / DB / network, and whether it is reversible.
- Do not run commands "just to see what happens."
- Without explicit instruction, do not run: deploy scripts, production commands, database migrations, DB reset/seed/bulk scripts, infra changes, or anything that sends email / SMS / WhatsApp / notifications.
- If impact is unclear, inspect the script or ask first.

## Production safety
- Never connect to or modify production systems, live databases, or production config.
- Never deploy, delete production data, rotate secrets/credentials, or send real external communications.

## No destructive actions without explicit permission
- Do not delete, overwrite, reset, truncate, or drop data or important files without explicit authorization.
- Prefer reversible approaches. Before deleting/overwriting a file you did not create, inspect it and confirm.
  (The empty `docs/` tree was already removed on 2026-08-30 per D31, after verifying it contained zero files.)

## Keep changes focused
- No unrelated refactoring, reformatting, renaming, dependency bumps, or "cleanup" outside the task scope.
- Keep diffs minimal and reviewable.

## Dependency safety
- Do not add/remove/upgrade dependencies unless the task requires it.
- First check whether the capability already exists or an established project pattern covers it.
- Never change dependency versions as an unrelated side effect. (There are currently **no** dependency manifests — introducing the first ones follows D19/D21/D23 and should be done via ADR + the §17 bootstrap step.)

## Secrets & configuration
- Never hardcode secrets/credentials; never commit them; never invent config values; never replace env vars with literals.
- If configuration is missing, document what's missing and ask.

## Database safety
- Before touching schema or DB code, inspect the current schema and migration history (none exists yet — the first migrations must be reviewed carefully against §9 and the SRS).
- Do not assume a field/table is unused.
- Never run migrations automatically; only when explicitly requested.

## Verify honestly
- Distinguish in your reports: **Implemented** vs **Reviewed** vs **Tested** vs **Verified**.
- Never claim something works unless it was actually run/tested. State what was not verified and why.

## Preserve existing functionality
- Do not knowingly break user workflows, APIs, data contracts, auth, DB compatibility, or integrations.
- If a breaking change is necessary, identify and communicate the impact before implementing.
- Treat everything in §14 as a hard constraint.

## Do not hide problems
- Report failures honestly with the actual output.
- Do not suppress errors, delete functionality to make tests pass, or mask a broken state.
- Label temporary workarounds explicitly.

---

# REQUIRED DEVELOPMENT WORKFLOW

1. **Understand** — read `CLAUDE.md` + relevant `documentation/` specs + relevant code.
2. **Confirm** — separate what is confirmed (§3, §18), implemented, and unknown (§4, §16) for this task.
3. **Plan** — choose the smallest safe approach.
4. **Implement** — only the changes the task needs.
5. **Review** — check correctness and unintended impact against §14.
6. **Verify** — run safe, relevant checks; state what could not be verified.
7. **Report** — what changed, what was verified, what was not, remaining risks/questions.
8. **Update context** — when a confirmed requirement, decision, architecture, workflow, or constraint changes, update this `CLAUDE.md` (§3, §4, §16, §18, §19). Never record an assumption as fact.

---

# DEFAULT PERMISSION MODEL

The agent MAY, without asking: read/inspect files, search the codebase, analyze architecture, modify source files needed for the requested task, create necessary files, and run safe local non-destructive analysis.

The agent MAY NOT, without explicit user instruction: commit or push; run scripts with unknown or destructive effects; deploy; modify production systems or live databases; delete data; rewrite git history; send external communications; or change secrets/credentials.

**Having the ability to do something is not permission to do it. When uncertain, inspect and ask.**
