# ADR-0001 — Foundational Stack & MVP Scope Decisions

- **Status:** Accepted
- **Date:** 2026-08-30
- **Deciders:** Project owner (vipul@tezminds.com)
- **Context:** The project was at documentation-only stage. The SRS, User Stories, and screen specs contained several unresolved options and mutual contradictions (framework choices, `.docx` engine location, MVP scope, business-rule details). This ADR records the decisions taken in a single clarification session so implementation can begin without re-litigating them.

Where a decision changes an existing spec, the corresponding `documentation/` file has been updated in the same change set.

---

## Decisions

### D18 — Product name: SurvScribe (everywhere)
The product is **SurvScribe** across all aspects: code, package names, UI, documentation, and the **internal claim-reference prefix**, which becomes **`SS-YYYY-XXXXX`** (temp: `TEMP-SS-XXXX`).
*Note:* the git repository directory is currently still named `SurveyAssist`; renaming the physical folder and updating the git remote are manual follow-ups outside this change set.
*Supersedes* the earlier session note that kept the `SA-` prefix.

### D19 — Mobile client: React Native + TypeScript
Single React Native (TypeScript) app for iOS & Android is the **only MVP client**. Feature-first source layout under `apps/mobile/src/features/<feature>/{api,components,hooks,screens,store,types}` plus `src/infrastructure/` and `src/shared/`.

### D20 — Mobile local database: WatermelonDB
On-device store is **WatermelonDB** (reactive ORM over SQLite), encrypted with **SQLCipher (AES-256)**. Backs the offline store and the sync queue.

### D21 — Backend: Go + Gin, REST/JSON
Backend is **Go + Gin** exposing a **REST/JSON** API. **gRPC is out of scope for the MVP.** `pgx` driver + PostgreSQL, standard `cmd/ + internal/ + pkg/` layout.

### D22 — `.docx` engine: dual (client draft + authoritative server)
Two engines share one template contract:
1. **Client-side (TypeScript)** engine in the mobile app — offline PSR/FSR **drafts**.
2. **Authoritative server-side Go** engine — the **final compiled report**. The `< 5 s` / 50-photo-plate benchmark (SRS §6.3) applies here.
The two must produce equivalent output; template parity is a maintained spec.

### D23 — Monorepo tooling: pnpm workspaces + Turborepo
**pnpm workspaces + Turborepo** for the TypeScript packages (`apps/mobile`, future `apps/web`, `packages/*`). The Go backend keeps its own `go.mod` and is built separately (optionally wired into Turbo tasks).

### D24 — Desktop web app: deferred to post-MVP
MVP ships the React Native mobile app only. The "Responsive Desktop Web View" sections in the screen specs are forward-looking design, not MVP build/acceptance targets.

### D25 — External integrations: interfaces now, vendors via ADR
All third-party services sit behind provider-agnostic interfaces with config-driven adapters — `AssistantService` plus at least `NotificationService` (SMS OTP, email, WhatsApp) and `GeocodingService`. **Concrete vendors are not fixed in the SRS**; each is chosen in its own ADR (SMS OTP + email first, since Stage 0 is the first build target).

### D26 — Loss-assessment deduction sequence & underinsurance base
Strict order per line item: **Gross Assessed → less Depreciation → less Betterment → less Underinsurance → less Salvage → less Policy Excess = Net Recommended.**
The **Average Clause / underinsurance is applied to the Net-of-Depreciation base**: when `VAR > SI`, `Underinsurance Deduction = NetOfDepreciation × (1 − SI/VAR)`, else `0`. Worked example in `documentation/Screens/12_loss_assessment_quantification/12_loss_assessment_quantification.md` §4. A domain-expert sign-off on the worked example is still owed.

### D27 — Data model: expand the SRS entity list
Add `users`, `tenants`, `sessions`, `audit_log`, `sync_queue`, `contact_logs`, `follow_up_visits`, `coverage_opinions`, `requisition_notices` (candidate: `preservation_notices`) to `Requirement.MD` §5.2 as a draft. The finalized physical schema is produced separately in `documentation/architecture/`.

> **Superseded in part by [ADR-0005](ADR-0005-identity-model-store-client-and-rbac.md) (2026-08-30).** `tenants` is renamed **`stores`**; `users`, `stores` and `sessions` are no longer draft — their finalized DDL is in `architecture/physical-schema.md`, together with the additional identity entities `permissions`, `roles`, `role_permissions`, `user_roles`, `claim_access_grants`, `user_devices`, `auth_events`, `store_invites`, `otp_challenges` and `password_reset_tokens`. The remaining entities in this list stay draft pending `sprint_0001` task 1.

### D28 — Stage 4 GPS accuracy
Target **≤ 10 m** (readings worse than 10 m warn and prompt re-capture); hard limit **≤ 50 m** (readings worse than 50 m cannot be saved).

### D29 — Stage 12 salvage: three disposal modes
**Mode A** — Retained by Insured; **Mode B** — Sold to Scrap Buyer; **Mode C** — Tender floated by Insurer.

### D30 — Primary brand blue
`--color-primary: #1E3A8A`, `--color-primary-hover: #1E40AF`, `--color-primary-active: #172554`. The `Visual Theme & Design System.md` token scale is authoritative for the UI. Logo assets keep `#1E40AF` intentionally.

### D31 — Single documentation root
All documentation lives under **`documentation/`**. The empty `docs/` scaffold was deleted. ADRs → `documentation/decisions/`; physical schema, API contract, diagrams → `documentation/architecture/`.

### D32 — Biometric unlock: deferred to post-MVP
MVP offline re-entry uses a cached encrypted session token + device passcode only. (The only stale "biometric" mention remaining is legal-copy text inside `documentation/Screens/00_auth_terms/designs/00_auth_terms.svg`, a rendered mockup asset.)

### D33 — OTP resend timers
Phone SMS OTP: **30 s**. Email OTP: **45 s**.

### D34 — Insurable-interest status enum (Stage 7)
`Established` / `Under Verification` / `Incomplete Documentation` / `Disputed`.

### D35 — SLA license capture: optional at signup, required before FSR
License Number, Category, and Base Location are **optional at registration**. FSR generation is **blocked until License Number + Category are supplied** (they populate the report sign-off block). Syntax-only validation (`SLA-[0-9]{4,8}`) when a value is entered; registration is never regulatory verification.

### D36 — Stage 15 pre-submission audit: 7 gates
(1) Arithmetic Check, (2) Metadata Consistency, (3) Deduction Remarks, (4) Photo Annexure Compliance, (5) Document Completeness, (6) Contradiction Scanner, (7) Human Approval & AI Gate. All must pass before submission is enabled.

---

## Consequences

- The SRS, User Stories, Visual Design System, and eight screen specs were updated to match these decisions (see the change set that introduced this ADR).
- `CLAUDE.md` §3 / §7 / §11 / §18 record these as confirmed; `CLAUDE.md` §19 tracks the propagation checklist.
- Remaining open items (concrete vendors, session token spec, physical schema, API conventions) are listed in `documentation/decisions/README.md` as pending ADRs.
- Not yet done, as of this ADR's original date (2026-08-30): rename the physical repo directory `SurveyAssist` → `SurvScribe` and update the git remote; bootstrap the monorepo (`package.json`, `pnpm-workspace.yaml`, `turbo.json`, `apps/backend/go.mod`, `.gitignore`).
  **Status update:** the monorepo bootstrap was completed the same day (`sprint_0001`, `CLAUDE.md` §2.1a/§18 D45–D48). The physical repo-directory rename remains the one open item — it cannot be done from inside the working directory and stays a manual follow-up (`CLAUDE.md` §16 Q1, §19.2).
