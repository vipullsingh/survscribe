# Project Overview

> **Document type:** Persistent, evidence-based project context for **SurvScribe** (git repo directory still `SurveyAssist` — physical rename pending, see §16 Q1).
> **Created:** 2026-08-30 · **Last updated:** 2026-08-30 (Q&A resolutions folded in **and propagated into `documentation/`**; see §19; **`sprint_0001` bootstrap completed same day** — see §2.1a and §18 D45–D48).
> **Maintained by:** Future developers and AI agents working in this repository.
>
> Every statement below is tagged with one of:
> - **[Confirmed Requirement]** — explicitly stated in `documentation/` (SRS, User Stories, Screen Specs, Design System).
> - **[Confirmed — Q&A 2026-08-30]** — decided by the project owner during a clarification session on 2026-08-30, and **propagated into the `documentation/` source files the same day** (see §19 for the file-by-file record). Recorded in `documentation/decisions/ADR-0001`.
> - **[Implemented]** — demonstrably present as working code in the repository.
> - **[Planned / Referenced]** — named as intended/future work but not implemented.
> - **[Unconfirmed — clarification required]** — cannot be verified; still open.
>
> **The single most important fact:** As of 2026-08-30 (post-`sprint_0001`) this repository contains a **working, verified toolchain skeleton**: a Go backend that builds, vets, and passes its tests; a five-package pnpm/Turborepo workspace that lints, typechecks and tests clean; a generated-and-linted OpenAPI v1 contract; and 12 SQL migration files (never executed against a live database — see §2.1a). **No feature is implemented and no database has been created.** See §2.

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

### 2.1a `sprint_0001` bootstrap — [Implemented, verified 2026-08-30]

Every task in `sprint_0001` is complete. This supersedes the "empty scaffold" and "partial monorepo skeleton" claims above wherever they conflict — those describe the pre-bootstrap state.

**Physical schema — `documentation/architecture/physical-schema.md`, v2.0.0.** Extended with **Part B** (§16–§39): DDL for all 20 remaining SRS §5.2 entities plus 9 additions the specs required but did not name (`policy_sections`, `chronology_events`, `document_line_items`, `assessment_heads`, `discrepancy_flags`, `preliminary_survey_reports`, `pre_submission_audits`, `report_dispatches`, `document_damage_links`) — flagged `[ADDITION]` throughout and listed in §38 for owner review. **38 tables total** (Part A's 13 + Part B's 25), **50 enum types**. **Q2 resolved** (§17): follow-up visits extend `site_visits` via a `visit_type` enum rather than a separate `follow_up_visits` table; `preservation_notices` stays its own table, not folded into `contact_logs`. Still Draft pending project-owner review (§16 Q12 remains open — nothing here is self-approved).

**Migrations — `apps/backend/migrations/`.** 12 migration pairs (`.up.sql`/`.down.sql`, `golang-migrate` naming), extracted verbatim from the schema document by `apps/backend/scripts/gen_openapi.py`'s sibling `check_migrations.py`. 246 statements. **Verified** by a static structural checker (`apps/backend/scripts/check_migrations.py` — 0 errors: no forward references, no unbalanced statements, every up has a down, every table/type is dropped) and by CI's apply-then-roll-back job against a disposable Postgres. **Not yet verified against a real, persistent database** — `sprint_0001` §5 R8 and §16 Q12 (owner approval) are still open, and per the runbook (`migrations/README.md`) they are never executed automatically anywhere. A local `docker-compose` Postgres (`apps/backend/deployments/docker-compose.yml`, port 5433) is provided for that manual step.

**API contract — `documentation/architecture/api-contract/openapi.yaml`, v1.0.0.** **Generated**, not hand-written, from the migration DDL (`apps/backend/scripts/gen_openapi.py`), so contract and schema cannot silently drift — CI regenerates and diffs on every run. 149 component schemas, 50 enums, 73 paths, 135 operations. **Verified**: passes `redocly lint` with 0 errors (1 accepted warning — see `.redocly.yaml`). Frozen under the change-control note in the spec's own `info.description`. Money is a decimal string, never a JSON number (`NUMERIC(15,2)` cannot round-trip through IEEE-754). `store_id`/`client_id` are never accepted in a request body (ADR-0004 §4) — write schemas set `additionalProperties: false`.

**Shared types — `packages/types`.** `openapi-typescript` output (`src/schema.d.ts`, generated, never hand-edited) plus a hand-written `src/index.ts` giving ergonomic names (`import type { Claim } from "@survscribe/types"`). **Verified**: typechecks; a drift-check script (`check-generated.mjs`, wired as its `test`) fails the build if `schema.d.ts` no longer matches the OpenAPI source.

**Monorepo completion.** `packages/{types,ui,config,api-contracts}` each have a real `package.json` and (where applicable) `tsconfig.json`; `pnpm-lock.yaml` is committed; root `tsconfig.json`, ESLint 9 flat config, Prettier config (all in `packages/config`, consumed via workspace `exports`); Turbo `lint`/`typecheck`/`test`/`build` tasks; `.github/workflows/ci.yml` (4 jobs: contract integrity, migrations apply/rollback, Go build/vet/test, workspace lint/typecheck/test). **Verified**: `pnpm install && pnpm run format:check && pnpm run lint && pnpm run typecheck && pnpm run test` all exit 0 across all 5 JS/TS packages, run locally in this session (not yet run inside the GitHub Actions environment itself — CI has not executed on this repository yet).

**Backend skeleton — `apps/backend`.** `cmd/api/main.go` (config → logger → DB connect-with-ping → server, clean SIGTERM/SIGINT shutdown; **no automatic migrations**); `internal/config` (fail-fast env loading, all problems reported at once); `internal/server` (Gin router, envelope middleware chain `RequestID → RealIP → Recovery → AccessLog`; `Authenticate → StoreScope → RequirePermission` are sprint_0003 seams, not yet wired); `internal/repository` (pgx pool with Ping-at-connect); `internal/handler` (`/healthz`); `pkg/response` (ADR-0004 envelope + typed error codes); `pkg/logger` (structured `log/slog`, JSON or text). **Verified**: `go build ./...`, `go vet ./...`, and `go test ./...` (real `httptest` coverage of the envelope, 404/405 handling, and the degraded-without-database health path) all pass. Manually verified: fails fast and legibly with no `DATABASE_URL`; fails fast and legibly against an unreachable Postgres. Go pinned to **1.25** (not 1.22 — `pgx/v5` v5.10.0 requires it; ADR-0007 §1 records and supersedes the earlier `go.mod` line).

**Mobile skeleton — `apps/mobile`.** React Native 0.75 + TypeScript scaffold: `src/app/App.tsx` (navigation shell, the canonical 5-tab bottom nav, one named `PlaceholderScreen` per tab stating which sprint owns it — no lorem ipsum, per Design System §7.3); `src/core/env.ts` (build-time config; **no provider secret ever enters this file or the bundle** — see ADR-0008 §3); `src/shared/api/client.ts` (envelope-aware fetch wrapper, typed `ApiRequestError` with an `isOffline` discriminator for the future sync engine; auth-header attachment and refresh-on-401 are marked `sprint_0003` seams). **Verified**: typechecks clean with `exactOptionalPropertyTypes` on. **Not verified**: has not been run on an actual iOS simulator or Android emulator — no such device/toolchain is available in this environment. That check remains outstanding against `sprint_0001`'s acceptance criterion "runs on iOS simulator and Android emulator."

**ADR-0007 (conventions).** Go 1.25; backend testing = `testing` + `testify`, `-race` in CI, no unit test may require Postgres; mobile testing = Jest + React Native Testing Library, Detox deferred; the deterministic loss engine held to a higher bar (shared Go/TS fixture, the §30.2 worked example as a committed regression case) once `sprint_0011` builds it; Prettier owns formatting (100-col), ESLint owns correctness (four added rules, each justified); short-lived branches off `main`, squash merge, Conventional Commits (continuing existing practice); generated artifacts are committed and CI proves they're current. **Status: Proposed** — needs project-owner sign-off like every other ADR in this repo.

**ADR-0008 (config & secrets) — closes Q13.** Environment-only configuration, validated once at boot, every problem reported together; layered `.env` for dev only, gitignored; **no provider secret ever reaches the mobile bundle** (the app calls providers only through the backend); RS256 key custody: dev = local throwaway pair, CI = ephemeral, staging/production = platform secret manager (AWS Secrets Manager, provisional — no environment is provisioned yet); **90-day rotation via an overlap window that never forces a re-login** (refresh tokens are opaque and unaffected by a signing-key change — this is the constraint that makes rotation safe for an offline surveyor); database: application role gets `INSERT`/`SELECT` only on `audit_log`/`auth_events`, never owner privileges; migrations run under a separate human-operated role. **Status: Proposed.**

**Vendor tracker — `documentation/decisions/vendor-tracker.md`.** Every ADR-0002/0006 vendor listed with status (**all 14 rows `NOT STARTED` or `NOT DECIDED`** — account creation is an owner action, not something performed here), what each blocks, and the rule that a missing key degrades a feature rather than breaking the app (offline-first was never allowed to depend on a network call on a critical path). **India SMS DLT registration (row 3) flagged as the one urgent item** — weeks of lead time, and starting it now is the only way Phone OTP stays a Should-Have rather than a blocker.

**ADR-0009 (MVP release scope) — closes Q9 and the dual-`.docx` scope question.** Both were explicitly put to the project owner rather than resolved silently (`CLAUDE.md`'s own rule). **AI-4 is a post-launch fast-follow, not an MVP release gate** — `sprint_0014` stays where the roadmap already placed it, and Stage 14 must work completely with sections C/D/H/I entered by the surveyor with no AI assist. **MVP builds the server-side Go `.docx` engine only**; the offline client-side TypeScript engine (ADR-0001 D22's other half) is deferred post-MVP — every stage of *data capture* stays fully offline per `CLAUDE.md` §14 constraint 7, only final-document *rendering* needs connectivity in MVP. **Status: Accepted.**

**What `sprint_0001` deliberately did not do:** apply any migration to a persistent database; provision any vendor account or secret; run the mobile app on a simulator/emulator; get owner approval on the schema, contract, ADR-0007 or ADR-0008 (all four need it before `sprint_0003` starts, per `sprint_0001` R8/Q12); execute CI inside GitHub Actions itself (only run locally, equivalently, in this session).

### 2.2 Implemented and working functionality

**None as a product feature.** Toolchain and scaffolding only (§2.1a). No claim can be created, no user can register, no screen beyond five navigation placeholders exists.

### 2.3 Partially implemented functionality

**Design-side:** unchanged — only screens `00_auth_login`, `00_auth_signup`, `00_auth_terms` have visual SVG mockups; screens 01–16 have written specs but no visuals.

**Code-side:** the backend and the API contract are further along than the mobile app or any feature: a real HTTP server with a real (if featureless) route exists and is tested; the mobile app has a navigation shell and an API client with no screen behind either yet.

### 2.4 Planned / referenced functionality

Everything product-facing is still planned. High-level scope (see §6 for detail):
- Auth (Stage 0): password + universal identifier login, Phone OTP, Email OTP, forgot password, offline session, registration, Terms screen.
- 15 workflow stages (Stage 1 Appointment Intake … Stage 15 Internal Review & Submission).
- 5 AI touchpoints: Voice-to-Text (AI-1), Document/Invoice OCR (AI-2), Cross-Check/Fraud Audit (AI-3), Report Draft Generator (AI-4, primary — **post-MVP fast-follow, ADR-0009**), Loss Assessment Calculator (AI-5, deterministic).
- Offline sync engine, RBAC enforcement middleware, server-side `.docx` report engine (MVP scope — ADR-0009).

### 2.5 Known incomplete / undecided areas (after `sprint_0001`)

Resolved 2026-08-30 in the 08-30 Q&A (see §18 decision log D18–D44) **and now also**: Q2 (follow-up-visit/preservation-notice table shape — §17 of `physical-schema.md`), Q9 (AI-4 MVP timing — ADR-0009), the dual-`.docx` MVP scope (ADR-0009), Q13 (RS256 key custody — ADR-0008). §19 tracks propagation into `documentation/`.

Still genuinely open — see §16:
- **Q12** — owner approval of the physical schema, API contract, ADR-0007 and ADR-0008. Nothing in `sprint_0001`'s output is self-approved; `sprint_0003` cannot start without it.
- Part B `[ADDITION]` tables (`physical-schema.md` §38) — 9 tables the SRS didn't name but the stage screens require; each needs a specific yes.
- Concrete external vendor accounts — selected (ADR-0002/0006), **none provisioned** (vendor tracker).
- Depreciation scale data source (§4 item 1).
- Migrations have never touched a real database (only CI's disposable one).

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
**[Planned / Referenced]** for every product feature. **[Implemented]** for the toolchain: the Go backend, the five-package JS/TS workspace, the generated OpenAPI contract, and 12 SQL migration files all exist, build, and are verified per §2.1a. No feature is built and no migration has touched a persistent database.

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
| **`.docx` engine** | **Two engines with a shared template contract are the target architecture; MVP builds the server engine only (ADR-0009).** (1) **Client-side** (TS) generation on the mobile app for **offline PSR/FSR drafts** — deferred post-MVP. (2) **Authoritative server-side Go engine** for the **final compiled report**; the `< 5 s` / 50-plate benchmark (CR-NF5) applies here, and this is what MVP ships. Formatting parity is a shared spec for when the client engine is added. | Q&A 2026-08-30; **ADR-0009 (scope), 2026-08-30** |
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
**[Confirmed — ADR-0003 as amended by ADR-0005]** Dual token: **RS256 JWT access token, 15 min**, claims `sub`/`store_id`/`client_id`/`sid`/`roles[]`/`perms[]`/`pv`; **opaque 64-byte refresh token, 30 days**, Argon2id-hashed in `sessions.refresh_token_hash`, rotated on every use with `refresh_token_family_id` reuse detection. Tokens live in iOS Keychain / Android Keystore. Offline access via cached token or **device passcode**; 15-minute background auto-lock; 30-day offline grace. OTP via SMS (30 s resend) and email (45 s resend); universal-identifier resolution (email/username/phone, globally unique). Biometric unlock post-MVP. Middleware chain: `RequestID → RealIP → Authenticate → StoreScope → RequirePermission` — **`RequestID` and `RealIP` are implemented** (`apps/backend/internal/server/middleware.go`); `Authenticate`/`StoreScope`/`RequirePermission` are `sprint_0003` seams, not yet written. Full specification in [`documentation/architecture/identity-and-rbac.md`](documentation/architecture/identity-and-rbac.md). **Signing-key custody / rotation — [Confirmed — ADR-0008, 2026-08-30]: closes §4 item 4 / §16 Q13.** RS256, 2048-bit minimum, `kid`-identified; dev = local throwaway pair, CI = ephemeral, staging/production = platform secret manager (provisional, no environment provisioned yet); 90-day scheduled rotation via a dual-`kid` overlap window sized to one access-token lifetime plus margin, which never forces a re-login because refresh tokens are opaque and unaffected by a signing-key change.

---

## 8. Codebase Structure

```
SurveyAssist/  (git dir; product name = SurvScribe — physical rename pending)
├── README.md  CLAUDE.md               # Project summary; this file
├── .editorconfig  .redocly.yaml  .gitignore  .prettierignore
├── package.json  pnpm-workspace.yaml  pnpm-lock.yaml  turbo.json  tsconfig.json
├── eslint.config.mjs  prettier.config.mjs   # thin re-exports of packages/config
├── .github/workflows/ci.yml           # 4 jobs: contract, migrations, backend, workspace
│
├── documentation/                    # THE SINGLE DOCS ROOT
│   ├── Requirement.MD                # SRS v1.0.0-MVP ("Approved Baseline") + §2.3 stack baseline
│   ├── User Stories.md               # Epic 0 + Epics 1–16, acceptance criteria
│   ├── Visual Theme & Design System.md  # Design system v2.0.0-Enterprise
│   ├── decisions/                    # ADR log — README index + ADR-0001…0009
│   │                                 #   0001 stack/scope · 0002 vendors · 0003 auth tokens
│   │                                 #   0004 API+schema rules · 0005 identity model · 0006 geo-IP
│   │                                 #   0007 conventions (Proposed) · 0008 config/secrets (Proposed)
│   │                                 #   0009 MVP scope (Accepted) · vendor-tracker.md
│   ├── architecture/
│   │   ├── physical-schema.md        # v2.0.0 — Part A identity (FINAL) + Part B workflow (Draft, 38 tables)
│   │   ├── identity-and-rbac.md      # FINAL
│   │   └── api-contract/openapi.yaml # GENERATED — v1.0.0, 149 schemas / 73 paths / 135 ops
│   ├── sprints/                      # Master MVP roadmap + 17 individual sprint execution plans
│   ├── assets/logo/                  # 4 brand SVGs + README (brand colors, symbolism)
│   └── Screens/                      # 17 screen spec folders
│       ├── 00_auth/        (00_auth_login.md, 00_auth_signup.md, 00_auth_terms.md + designs/ 8 SVGs)
│       ├── 01_dashboard/   (01_dashboard.md — NO designs/)
│       └── 02_… through 16_…  (<folder_name>.md only, NO designs/)
│
├── apps/
│   ├── backend/                      # Go 1.25 / Gin — BUILDS, VETS, TESTS clean
│   │   ├── go.mod  go.sum  .env.example
│   │   ├── cmd/api/main.go           # config → logger → DB(ping) → server; no auto-migrate
│   │   ├── internal/config/          # fail-fast env loading
│   │   ├── internal/server/          # router + middleware (RequestID, RealIP, Recovery, AccessLog)
│   │   │                             #   + server_test.go (httptest coverage)
│   │   ├── internal/handler/         # /healthz (degrades to 503 if DB unreachable)
│   │   ├── internal/repository/      # pgx pool, Connect() Pings before returning
│   │   ├── pkg/response/             # ADR-0004 envelope + typed ErrorCode
│   │   ├── pkg/logger/               # log/slog, JSON or text
│   │   ├── migrations/               # 12 pairs, .up/.down.sql — NEVER auto-executed; see README.md
│   │   ├── deployments/docker-compose.yml  # local Postgres 16, port 5433, dev-only
│   │   └── scripts/                  # gen_openapi.py, check_migrations.py
│   └── mobile/                       # React Native 0.75 + TS — TYPECHECKS clean
│       ├── package.json  tsconfig.json  metro.config.js  babel.config.js  .env.example
│       ├── src/app/                  # App.tsx (5-tab nav shell) + PlaceholderScreen.tsx
│       ├── src/core/env.ts           # build-time config; no secret ever lands here
│       ├── src/shared/api/client.ts  # envelope-aware fetch client, typed ApiRequestError
│       └── src/{features,infrastructure}/  # empty — feature work starts sprint_0003+
│
└── packages/                         # pnpm workspace — all 4 have real manifests
    ├── types/         # @survscribe/types  — GENERATED src/schema.d.ts + hand-written index.ts
    ├── api-contracts/ # @survscribe/api-contracts — vendors openapi.yaml for tooling
    ├── ui/            # @survscribe/ui — design-system tokens (tokens.ts), components not yet built
    └── config/        # @survscribe/config — shared tsconfig.base.json, eslint.config.mjs, prettier.config.mjs
```
(The former empty `docs/` tree was deleted on 2026-08-30. `pkg/response`/`pkg/logger` are under `apps/backend/`, not repo root — the CLAUDE.md §2.1 "empty scaffold" listing that put them at root predates the actual bootstrap.)

**Where to look for authority today:** `documentation/Requirement.MD` (SRS) is the top-level source; `documentation/User Stories.md` refines it into testable ACs; `documentation/Screens/<name>/<name>.md` is the most detailed layer. **When the SRS and a screen spec disagree, this `CLAUDE.md` §3 / §18 records the resolved answer — use that, and update the underlying doc per §19.**

**Screen ↔ Stage numbering:** screen folder `NN` = Stage `NN−1` (screens 02–16). Screen 00 = Stage 0 (auth, 3 sub-screens). Screen 01 = global dashboard (no stage).

---

## 9. Data Model

**[Confirmed Requirement — schema-level]** From `Requirement.MD` §5.2. **The identity slice (Part A) is finalized DDL**, per ADR-0005. **[Draft — schema-level, awaiting owner approval]** The claim-workflow entities (Part B, §16–§39 of `physical-schema.md`) now also have complete DDL — 25 tables including 9 flagged `[ADDITION]` beyond the original SRS §5.2 list — produced by `sprint_0001` task 1. **Q2 is resolved** (§17): `follow_up_visits` folds into `site_visits`; `preservation_notices` stays separate. **Migrations exist** — 12 files under `apps/backend/migrations/`, structurally verified and CI-applied to a disposable database, but **never executed against any persistent database**; `sprint_0001`'s runbook (`migrations/README.md`) states they never run automatically. **§16 Q12 (owner approval) is still open** — nothing in Part B should be treated as final until reviewed.

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

### 9.2b Claim-workflow entities — [Draft DDL complete, D27 superseded] — `physical-schema.md` Part B, §16–§39
All 25 Part B tables now have DDL: `sync_queue`, `audit_log`, `contact_logs`, `coverage_opinions`, `requisition_notices`, `preservation_notices` (kept separate — **Q2 resolved**), plus `policy_sections`, `chronology_events`, `document_line_items`, `assessment_heads`, `discrepancy_flags`, `preliminary_survey_reports`, `pre_submission_audits`, `report_dispatches`, `document_damage_links` (9 `[ADDITION]` tables the SRS field lists didn't name — flagged individually in `physical-schema.md` §38 for owner review). `follow_up_visits` was **not** created as a separate table — it is `site_visits` rows with `visit_type = 'FOLLOW_UP'` (§17.1). **Status: Draft, not yet owner-approved** (§16 Q12) — extend, don't redesign, without a documented reason.

### 9.3 Data flow (intended)
Stage 0 → `stores` + `users` + `sessions` + `user_devices` + `user_roles` + `auth_events`; Stage 1 → `claims` + `claim_ref_no`; Stage 2 → `policy_details` + `policy_sections`; Stage 3 → `contact_logs` + `preservation_notices`; Stage 4 → `site_visits` (`visit_type='INITIAL'`); Stage 5 → `cause_investigations` + `chronology_events`; Stage 6 → `damage_items` + `media_attachments`; Stages 7 & 10 → `documents` + `document_line_items` (+ OCR JSON) + `document_damage_links`; Stage 8 → `requisition_notices` + `preliminary_survey_reports`; Stage 9 → `site_visits` (`visit_type='FOLLOW_UP'`); Stage 11 → `assessment_heads` + `assessment_line_items`; Stage 12 → `salvage_records` (feeds `assessment_line_items.salvage_amount` / FSR Section F); Stage 13 → `coverage_opinions`; Stage 14 → `final_survey_reports`; Stage 15 → `pre_submission_audits` + status lock + SHA-256 hash snapshot + `report_dispatches`; all figure edits and insurer file access → `audit_log`; all authentication actions → `auth_events`; rule-and-AI findings across every stage → `discrepancy_flags`.

**Physical schema for the claim-workflow entities is now drafted** (§4 item 2 substantially addressed) — what remains is project-owner review and sign-off (§16 Q12), plus the specific `[ADDITION]` confirmations in `physical-schema.md` §38.

---

## 10. APIs and External Integrations

### 10.1 Internal API
**[Implemented — contract only]** `documentation/architecture/api-contract/openapi.yaml` v1.0.0 exists, is generated from the migration DDL (`apps/backend/scripts/gen_openapi.py`), and passes `redocly lint` with 0 errors. 149 schemas, 73 paths, 135 operations, vendored into `packages/api-contracts/`. `packages/types` provides generated TypeScript types over it. **[Planned / Referenced] for the server itself:** the Go/Gin API implements only `/healthz` (`apps/backend/internal/handler/health.go`) — none of the 135 contracted operations has a handler yet. The contract is frozen under an explicit change-control note (see the spec's own `info.description`) and is not to be hand-edited — regenerate instead.

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

### 13.2 Established 2026-08-30 by ADR-0007 — [Proposed, awaiting owner approval]
- **Linter/formatter:** ESLint 9 flat config + Prettier (100-col), shared via `@survscribe/config`; `gofmt` defaults for Go, no local additions. Config lives in `packages/config/{eslint,prettier}.config.mjs`.
- **Testing:** Go = `testing` + `testify`, `-race` in CI, no unit test may require Postgres; mobile = Jest + React Native Testing Library, Detox deferred; the Stage 11 deterministic loss engine held to a higher bar (shared Go/TS fixture) once `sprint_0011` builds it.
- **Branching:** short-lived `feat/`/`fix/`/`docs/`/`chore/`/`refactor/` branches off `main`, squash merge, Conventional Commits subjects (continuing existing practice). `main` protected, CI-green-to-merge — **enabling branch protection in GitHub settings is an owner action**, not yet done.
- **API conventions:** ADR-0004 already fixed envelope/pagination/versioning; ADR-0007 adds nothing new here.
- **`.editorconfig`:** committed at repo root (UTF-8, LF, trimmed trailing whitespace, 2-space indent / tabs in Go / 4-space in SQL).
- Full rationale and alternatives considered: [`ADR-0007`](documentation/decisions/ADR-0007-engineering-conventions.md).

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
16. **`.docx` formatting parity.** The offline client engine and the authoritative server Go engine must produce equivalent documents from the same shared template contract. Do not let them drift. **MVP builds the server engine only** (ADR-0009) — the client engine is deferred post-MVP, but the shared template contract (`final_survey_reports.section_*_json` envelope, `physical-schema.md` §33) is still built to the full spec now, precisely so parity is achievable later without a rewrite.

---

## 15. Known Issues and Technical Debt

1. **No feature implementation exists.** `sprint_0001` closed the gap between "Approved Baseline" documentation and zero code by delivering a verified toolchain (§2.1a) — but that toolchain has no product feature behind it yet. The gap between documentation and *features* remains the project's central risk surface.
2. **~~Empty scaffold directories are untracked by git~~ — RESOLVED 2026-08-30.** `apps/` and `packages/` now hold real, committed files throughout (§2.1a, §8).
3. **~~`documentation/` source files not yet updated~~ — DONE 2026-08-30.** The 2026-08-30 decisions have been propagated into the SRS, User Stories, Visual Design System, README, and the affected screen specs; `documentation/decisions/ADR-0001` records them; the empty `docs/` tree was deleted. Remaining doc-adjacent follow-ups: physical repo-dir rename `SurveyAssist`→`SurvScribe`, and the `00_auth_terms.svg` legal-copy "biometric" line (rendered asset). See §19.
4. **`README.md` repo-structure section is stale** — says "18 Dedicated Screen Specification Folders" and "designs/ (4 vector artboards)" for login; actual counts are 19 folders and 5 login SVGs; omits `00_auth_terms`. Also predates `sprint_0001`'s bootstrap and does not describe the current `apps/`/`packages/` contents.
5. **Dashboard SVG missing** — commit `ea73c91` claims a Screen 01 SVG mockup; none is present in `01_dashboard/`.
6. **Bottom-nav labels differ** between `Design System.md` §6.1 and `01_dashboard.md` §2.1 — reconcile. (The 5-tab set implemented in `apps/mobile/src/app/App.tsx` follows the canonical `Design System.md` §6.1 list.)
7. **~~No provider/vendor decisions~~ — RESOLVED.** ADR-0002 fixes SMS (Twilio, AWS SNS fallback), email (SendGrid), maps, LLM and OCR vendors; ADR-0006 fixes geo-IP (local MaxMind GeoLite2). **No account is provisioned** — see `documentation/decisions/vendor-tracker.md`, created `sprint_0001` task 10, every row `NOT STARTED`/`NOT DECIDED`. Remaining external dependency is operational, not architectural: **Twilio India SMS DLT registration takes weeks** (risk R4) — flagged in the tracker as the one urgent item, and it has not been started.
8. **~~No environment/config strategy~~ — RESOLVED 2026-08-30 by ADR-0008** (Proposed, awaiting owner approval). `.env.example` committed for both apps; fail-fast env loading implemented (`apps/backend/internal/config`); RS256 signing-key custody and 90-day rotation specified (§4 item 4, §16 Q13 — closed).
9. **Depreciation scale data source undefined** (§4 item 1). Still open — `assessment_line_items.depreciation_basis` is a free-text column, not a lookup against a scale table, because no scale data source has been provided.
10. **~~Session token format / lifetime / refresh undefined~~ — RESOLVED** by ADR-0003 as amended by ADR-0005 (§7.4).
11. **`auth_events` has no retention policy** — the table grows unbounded (§4 item 6). `physical-schema.md` §10.2 and §38 item 10 both flag this; `audit_log` has the same open question and is evidentiary, which raises the stakes.
12. **`users.username` is accepted at login but captured by no signup step** — assumed NULL at signup, settable from Profile; unconfirmed (§4 item 5).
13. **`physical-schema.md` Part B contains 9 tables the SRS never named** (`policy_sections`, `chronology_events`, `document_line_items`, `assessment_heads`, `discrepancy_flags`, `preliminary_survey_reports`, `pre_submission_audits`, `report_dispatches`, `document_damage_links`) — each is architecturally justified in the document itself and flagged `[ADDITION]`, but none is approved. Listed for review in `physical-schema.md` §38 and tracked here as debt until §16 Q12 closes.
14. **The mobile app has not run on any simulator or emulator.** It typechecks; `sprint_0001`'s own acceptance criterion ("runs on iOS simulator and Android emulator") is unverified because no such toolchain exists in this development environment.
15. **CI has never executed inside GitHub Actions.** `.github/workflows/ci.yml` exists and its four jobs were run locally, by hand, with equivalent commands and equivalent (0-error) results — but the workflow itself has not fired on a real push or pull request yet.
16. **No migration has ever touched a persistent database.** Only CI's disposable, job-scoped Postgres has applied them (apply, then roll back). `sprint_0001` R8 and §16 Q12 require owner sign-off before that changes.

---

## 16. Open Questions

> **Closed:** ~~Q1~~ (monorepo bootstrapped — root `package.json`, `pnpm-workspace.yaml`, `turbo.json`, `apps/backend/go.mod` and `.gitignore` are committed), ~~Q2~~ (vendors: ADR-0002 + ADR-0006), ~~Q3~~ (ADR-0003 as amended by ADR-0005), ~~Q5~~ (ADR-0004), ~~Q7~~ (ADR-0005 D39 — seeded role/permission matrices in `architecture/physical-schema.md` §7.6–§7.7), ~~Q9~~ (bottom-nav labels — implemented per Design System §6.1 in `App.tsx`; `01_dashboard.md` still needs the doc-side reconciliation), ~~Q11~~ (ADR-0007), ~~Q13~~ (ADR-0008). **Q4 is now further along:** all 38 tables (Part A + Part B) have DDL; what remains is owner approval (Q12), not drafting.
>
> Note: `sprint_0001`'s **own** Q9 (whether AI-4 gates the MVP release) is a **different question** from this file's Q9 above — that one is closed by **ADR-0009**, not by this list, and was never numbered here.

### Critical — blocks `sprint_0003`
- **Q12.** **Owner approval of the schema, contract and ADR-0007/ADR-0008.** `architecture/physical-schema.md` (both parts), `api-contract/openapi.yaml`, and the two Proposed ADRs. `sprint_0001` R8 requires sign-off before `sprint_0003` starts. Nothing produced by `sprint_0001` is self-approved — not the schema, not the contract, not the conventions, not the secrets model.
- **Q4 (remaining half).** Not the DDL itself (drafted — §9.2b) but the **9 `[ADDITION]` tables** listed in `physical-schema.md` §38: each needs a specific owner decision, not a blanket approval.

### Important — affects implementation or architecture
- **Q6.** Source/content of the standard surveyor / IRDAI depreciation scales for AI-5. (§4 item 1)
- **Q8.** Produce a worked numeric example of the §11.1 loss sequence for domain-expert sign-off. (§4 item 3) — Note: `12_loss_assessment_quantification.md` §4 already carries one worked example (₹4,97,500 net recommended); confirm whether that satisfies this or a second, domain-expert-reviewed example is still wanted.
- **Q14.** `users.username` capture — NULL at signup and set from Profile, or an optional input in signup Step 2? (§4 item 5)
- **Q15.** `auth_events` **and** `audit_log` retention period. (§4 item 6; `physical-schema.md` §38 item 10 extends this to `audit_log`, which is evidentiary)
- **Q16.** Keychain/Keystore wipe recovery and the local-data-loss warning. (§4 item 7)
- **Q17.** **SLA licence format contradiction** — `Requirement.MD` FR-0.2 and AC 0.2.2 say `SLA-[0-9]{4,8}`; `00_auth_signup.md` §4 says *"`SLA-[0-9]{4,8}` **or alphanumeric**"*. The SRS is treated as authoritative pending your call; the DB holds only a loose sanity bound so the rule can change without a migration. (§4 item 8)
- **Q18.** `physical-schema.md` §38 item 5 — is Policy Excess genuinely per-line-item (as SRS entity 8, FR-11.2 step 9, and the screen's §5 field table all say), or does the screen's single claim-level `PolicyExcessDeductionInput` (§3) mean it should be claim-level with per-line distribution? Schema currently assumes per-line.
- **Q19.** `physical-schema.md` §38 item 4 — FR-6.1 names "Electrical" as a Stage 6 damage head; FR-11.1's five heads do not include it. Does Stage 6 need a sixth `head_category` value, or does "Electrical" map to `PLANT_MACHINERY`?

### Later — does not currently block progress
- **Q10.** Recreate the missing Screen 01 (dashboard) SVG, and add SVGs / Figma frames for stages 1–15 before building those screens. (§15 item 5)
- **Q20.** `physical-schema.md` §38 items 8–9 — the `uom` (12 values) and `document_type` (32 values) enums were closed from specs that ended in "etc."; worth a domain-expert pass before they're locked in by a migration.

---

## 17. Recommended Next Steps

**Recommendations, not confirmed requirements.**

1. **(DONE 2026-08-30)** 2026-08-30 decisions propagated into `documentation/`; §19 checklist complete for that round.
2. **(DONE 2026-08-30)** `documentation/decisions/` holds `ADR-0001` through `ADR-0009` plus `vendor-tracker.md`.
3. **(DONE 2026-08-30 — `sprint_0001`)** Monorepo fully bootstrapped: per-package `package.json` for all of `packages/*`, base `tsconfig`, `pnpm-lock.yaml`, ESLint/Prettier config, CI (`.github/workflows/ci.yml`). `pnpm install && pnpm run format:check && pnpm run lint && pnpm run typecheck && pnpm run test` all pass locally (§2.1a). Not yet verified: an actual GitHub Actions run.
4. **(DONE 2026-08-30 — `sprint_0001`)** `physical-schema.md` now covers all 38 tables (Part A identity, finalized; Part B workflow, drafted). **Next, in order:** (a) owner approval — §16 Q12, the single hardest blocker on `sprint_0003` starting; (b) the specific `[ADDITION]` and open-item decisions in `physical-schema.md` §38; (c) applying the migrations to a real, persistent database for the first time, following `apps/backend/migrations/README.md`.
5. **(DONE 2026-08-30 — `sprint_0001`)** `packages/api-contracts/` vendors the generated OpenAPI spec; `packages/types/` provides generated TS types with a drift check. Both wired into CI.
6. **Implement the deterministic loss-assessment engine next, with tests**, as a pure module (no I/O). Still the highest-risk correctness surface (`CLAUDE.md` §14 constraint 5), still fully specified (§11.1), still unbuilt. `sprint_0011` owns it; ADR-0007 §4 already commits it to a shared Go/TS test fixture.
7. **Build `AssistantService` / `IAssistantService` + `NotificationService` + `GeocodingService` as stubs** (Local/Cloud split, fake impls) so feature work can proceed before vendor accounts exist (per the vendor tracker, none do yet).
8. **Start UI on the fully-designed auth screens** (`00_auth_login`, `00_auth_signup`, `00_auth_terms`) to build out the `packages/ui/` component library — currently tokens-only (`packages/ui/src/tokens.ts`) — against the design system. This is `sprint_0002`/`sprint_0003` work, not yet started.
9. **Produce dashboard + stage 1–15 visual designs** before implementing those screens, per the project's "spec + design then build" pattern. Not started.
10. **New, `sprint_0001`-specific:** run `.github/workflows/ci.yml` for real (push a branch, open a PR) to verify it behaves the same in GitHub Actions as it did locally in this session.
11. **New:** get the mobile app onto an actual iOS simulator or Android emulator — genuinely unverified, since no such device exists in this development environment.

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
| **D45** | **Claim-workflow physical schema drafted** — `physical-schema.md` Part B, 25 tables (§16–§39), covering all 20 remaining SRS §5.2 entities plus 9 `[ADDITION]` tables the specs required without naming (`policy_sections`, `chronology_events`, `document_line_items`, `assessment_heads`, `discrepancy_flags`, `preliminary_survey_reports`, `pre_submission_audits`, `report_dispatches`, `document_damage_links`). **Q2 resolved**: follow-up visits extend `site_visits` via `visit_type`; `preservation_notices` stays a separate table. All rupee amounts `NUMERIC(15,2)`, never `FLOAT`; the FR-11.2 deduction chain is enforced by database `CHECK` constraints, not only application code. **Status: Draft — owner approval is §16 Q12, still open.** | Draft — `sprint_0001` task 1, 2026-08-30 | `physical-schema.md` Part B |
| **D46** | **First migration set emitted** — 12 files under `apps/backend/migrations/`, `golang-migrate` naming, extracted verbatim from the schema document. Structurally verified (0 errors: no forward references, every up has a matching down, every table/type is dropped somewhere). **Never executed against a persistent database** — only CI's disposable, job-scoped Postgres (apply then roll back). Local dev Postgres provided via `docker-compose.yml` on port 5433 (deliberately not 5432). | Confirmed — `sprint_0001` task 2, 2026-08-30 | `apps/backend/migrations/README.md` |
| **D47** | **OpenAPI v1 contract frozen and generated, not hand-written** — `api-contract/openapi.yaml`, generated from the migration DDL so contract and schema cannot drift (CI diffs on every run). Money crosses the wire as a decimal string, never a JSON number. `store_id`/`client_id` are never accepted from a client. `packages/types` provides generated TS types with its own drift check. Change-control note lives in the spec's own `info.description`, not a separate document. | Confirmed — `sprint_0001` task 3/4, 2026-08-30 | `api-contract/openapi.yaml` |
| **D48** | **Monorepo, backend and mobile skeletons bootstrapped and verified** — pnpm workspace (5 packages, all with real manifests), ESLint/Prettier/`.editorconfig`, CI (4 jobs); Go 1.25 backend (`gin` v1.12, `pgx/v5` v5.10 — both require 1.25, superseding the earlier `go 1.22` line) that builds/vets/tests clean with real `httptest` coverage; React Native 0.75 mobile app with a 5-tab nav shell and an envelope-aware API client, typechecking clean under `exactOptionalPropertyTypes`. **Not verified:** GitHub Actions has not run the workflow; the mobile app has not run on a simulator/emulator (none available in this environment). | Confirmed — `sprint_0001` tasks 5/6/7, 2026-08-30 | `apps/backend/`, `apps/mobile/`, `.github/workflows/ci.yml` |
| **D49** | **Engineering conventions decided (ADR-0007)** — Go 1.25; testing = `testing`+`testify` (backend, `-race`, no Postgres in unit tests) and Jest+RNTL (mobile, Detox deferred); the Stage 11 loss engine gets a shared Go/TS test fixture once built; formatting = Prettier (100-col) + `gofmt`; linting = ESLint 9 flat config, four rules added past `recommended`, each justified; branching = short-lived off `main`, squash merge, existing Conventional Commits practice continued; generated artifacts committed, CI proves currency. **Status: Proposed**, needs sign-off like every ADR here. | Proposed — `sprint_0001` task 8, 2026-08-30 | ADR-0007 |
| **D50** | **Configuration and RS256 key custody decided (ADR-0008) — closes Q13** — environment-only config, fail-fast, all problems reported together; no provider secret ever reaches the mobile bundle; RS256 custody by environment (dev = local throwaway, CI = ephemeral, staging/prod = secret manager, provisional); 90-day rotation via a dual-`kid` overlap window that never forces a re-login, because refresh tokens are opaque and unaffected by a signing-key change; database application role gets `INSERT`/`SELECT` only on `audit_log`/`auth_events`, never owner privileges. **Status: Proposed.** | Proposed — `sprint_0001` task 9, 2026-08-30 | ADR-0008 |
| **D51** | **Vendor tracker created** — every ADR-0002/0006 vendor listed with status; **all 14 rows `NOT STARTED`/`NOT DECIDED`**, account provisioning is an explicit owner action; India SMS DLT registration (R4) flagged as the one urgent item because of its multi-week lead time; a missing vendor key degrades a feature, never breaks the app, by design (offline-first was never allowed to depend on a network call on a critical path). | Confirmed — `sprint_0001` task 10, 2026-08-30 | `vendor-tracker.md` |
| **D52** | **AI-4 is a post-launch fast-follow, not an MVP release gate — closes Q9 (`sprint_0001`'s own, distinct from this file's dashboard-nav Q9)** — `sprint_0014` stays scheduled where the roadmap already placed it; Stage 14 must work completely with sections C/D/H/I entered by the surveyor with no AI assist, as a **tested** requirement, not an incidental one. | Accepted — ADR-0009, 2026-08-30 | ADR-0009 |
| **D53** | **MVP ships the server-side `.docx` engine only — the client-side TS engine (the other half of D22) is deferred post-MVP.** Every stage of *data capture* stays fully offline (constraint 7 unaffected); only final-document *rendering* needs connectivity in MVP. The shared template contract is still built to the full D22 spec now, so the client engine can be added later without a rewrite. | Accepted — ADR-0009, 2026-08-30 | ADR-0009 |

---

## 19. `documentation/` Reconciliation — Status

The 2026-08-30 decisions (§18 D18–D37, then D38–D44, then **D45–D53** — `sprint_0001`) have been **applied to `documentation/`**. See §19.3 for the `sprint_0001` round.

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
- [x] ~~Bootstrap the monorepo~~ — **DONE, `sprint_0001`, 2026-08-30.** See §19.3.
- [ ] `documentation/Screens/00_auth_terms/designs/00_auth_terms.svg` — legal-copy line still mentions "Biometric authentication keys". Low priority (rendered mockup asset); update when the terms screen is re-exported.
- [ ] Split ADR-0001 into per-decision ADRs if/when finer traceability is wanted (currently one consolidated record covers D18–D37).
- [x] ~~Pending vendor / schema / API-convention ADRs~~ — ADR-0007, ADR-0008, ADR-0009 added; `vendor-tracker.md` added. See `documentation/decisions/README.md`.
- [ ] Enable branch protection on `main` in GitHub repository settings (ADR-0007 §7) — an owner action, not a code change.
- [ ] Owner sign-off on `physical-schema.md`, `api-contract/openapi.yaml`, ADR-0007, ADR-0008 (§16 Q12) — blocks `sprint_0003`.
- [ ] Provision the vendor accounts in `vendor-tracker.md` — start India SMS DLT registration first (weeks of lead time).
- [ ] Run `.github/workflows/ci.yml` for real (push/PR) — only run locally-equivalent so far.
- [ ] Run the mobile app on an actual iOS simulator / Android emulator — no such toolchain in this environment.
- [ ] Apply the migrations to a real, persistent database for the first time, per `apps/backend/migrations/README.md` — only CI's disposable database has seen them.

### 19.3 `sprint_0001` — completed 2026-08-30 (D45–D53)

**New documents**
- [x] `documentation/architecture/physical-schema.md` **Part B** appended (§16–§39) — 25 tables, 9 flagged `[ADDITION]`, Q2 resolved. Document retitled and re-versioned (v2.0.0) with a two-part structure table at the top.
- [x] `apps/backend/migrations/000001`–`000012` (`.up.sql`/`.down.sql` pairs) + `apps/backend/migrations/README.md` (runbook) + `apps/backend/deployments/docker-compose.yml` (local dev Postgres).
- [x] `documentation/architecture/api-contract/openapi.yaml` (generated) + `.redocly.yaml` (lint config).
- [x] `packages/types/` (generated `src/schema.d.ts` + hand-written `src/index.ts` + drift-check script), `packages/api-contracts/` (vendors the spec), `packages/ui/src/tokens.ts` (design-system tokens), `packages/config/` (shared tsconfig/eslint/prettier).
- [x] `apps/backend/{cmd/api,internal/{config,server,handler,repository},pkg/{response,logger}}` — working Go skeleton, tested.
- [x] `apps/mobile/src/{app,core,shared/api}` — working RN skeleton, typechecked.
- [x] `.github/workflows/ci.yml`, `.editorconfig`, root `tsconfig.json`/`eslint.config.mjs`/`prettier.config.mjs`, `apps/{backend,mobile}/.env.example`.
- [x] `documentation/decisions/ADR-0007-engineering-conventions.md` (Proposed), `ADR-0008-configuration-and-secrets.md` (Proposed), `ADR-0009-mvp-release-scope.md` (Accepted), `vendor-tracker.md`.

**Amended**
- [x] `documentation/decisions/README.md` — ADR-0007/0008/0009 and the vendor tracker indexed.
- [x] `CLAUDE.md` — §0 header, §2.1a (new), §2.2–§2.5, §7.1, §7.2 (`.docx` engine row), §7.4 (key custody), §8 (full directory tree rewrite), §9 (Part B status, §9.2b, §9.3, §10.1), §13.2 (rewritten from "not yet established" to "established by ADR-0007"), §14 constraint 16, §15 (items 2, 3, 7, 8 marked resolved; items 13–16 added), §16 (Q9/Q11/Q13 closed; Q4 narrowed to the `[ADDITION]` list; Q18–Q20 added), §17 (items 1–5 marked done, items 10–11 added), §18 (D45–D53 added), and this §19.3.

**Not done — deliberately, per this session's own rules**
- No migration executed against a persistent database (§19.2).
- No vendor account opened, no secret provisioned (§19.2) — explicitly an owner action.
- No `git commit`/`push` — per this file's own git-safety rule, changes are left staged for the user to review and commit.
- Q2 (dashboard/design-system nav labels doc-side reconciliation), Q6, Q8, Q14–Q20 remain open; none was silently resolved.

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
