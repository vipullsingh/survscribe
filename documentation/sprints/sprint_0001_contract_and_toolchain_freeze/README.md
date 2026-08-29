# Sprint 0001 — Contract & Toolchain Freeze

| | |
| :-- | :-- |
| **Roadmap ref** | S0.1 |
| **Stage** | 0 — Foundation & Technical Readiness |
| **Status** | Not started |
| **Depends on** | Nothing — this is the entry sprint |
| **Blocks** | Every other sprint |
| **Roadmap** | [`../README.md`](../README.md) |

---

## 1. Sprint Objective

Produce the two artifacts that unblock all parallel work — the **finalized physical schema** and the **frozen OpenAPI v1 contract** — and complete the monorepo bootstrap so both applications build and run locally.

At the end of this sprint no product feature exists, but every subsequent sprint can start without waiting on a contract decision.

---

## 2. Features & Tasks

| # | Feature / module | Task | Dependency | Priority | Expected outcome |
| :-- | :-- | :-- | :-- | :-- | :-- |
| 1 | Physical schema | Write `documentation/architecture/physical-schema.md`: DDL for all 20 entities in SRS §5.2 (10 core + 10 draft) — column types, PK/FK, indexes, enum value lists, JSON payload shapes. Apply ADR-0004 rules (UUIDv4 public PK, `TIMESTAMPTZ` timestamps, soft deletes on claims/documents, `tenant_id UUID NOT NULL` on every operational table). Resolve **Q2**. | SRS §5.2; ADR-0004 | Critical | Reviewed, owner-approved schema document. |
| 2 | Migrations | First migration set under `apps/backend/migrations/` matching the schema document. **Not executed against any shared or production database.** Local `docker-compose` Postgres for development only. | Task 1 | Critical | Migration files + a local database that a developer can create on demand. |
| 3 | API contract | `documentation/architecture/api-contract/openapi.yaml` v1: auth, claims CRUD, per-stage sub-resources, sync push/pull, media upload. Standard success and error envelopes plus pagination `meta` per ADR-0004. | Task 1 | Critical | Reviewed OpenAPI specification. |
| 4 | Shared types | Generate `packages/types` from the OpenAPI spec; add `packages/types/package.json` and `tsconfig`. | Task 3 | Critical | `import type { Claim } from "@survscribe/types"` resolves in the workspace. |
| 5 | Monorepo completion | Add per-package `package.json` for `packages/*`; base `tsconfig`; ESLint + Prettier configuration; commit `pnpm-lock.yaml`; wire Turbo `lint`/`test`/`build` tasks; GitHub Actions CI running lint + typecheck + test. | root scaffold | Critical | `pnpm install && pnpm lint && pnpm test` green in CI. |
| 6 | Backend skeleton | `cmd/server/main.go`; `internal/{config,server,handler,repository,service,model,pkg}`; Gin router; response-envelope middleware; `pgx` connection pool; `/healthz`; structured logging. | Tasks 1, 2 | Critical | `go run ./cmd/server` serves `/healthz` against local Postgres. |
| 7 | Mobile skeleton | Initialise the React Native + TypeScript app in `apps/mobile`; feature-first folder layout per ADR-0001 D19; navigation shell with the canonical 5-tab bottom nav placeholder; environment handling; runs on iOS simulator and Android emulator. | Task 5 | Critical | App boots to a placeholder Dashboard on both platforms. |
| 8 | Conventions ADR | ADR-0005: testing frameworks (Go `testing` + `testify`; mobile Jest + React Native Testing Library; Detox for e2e later), branching strategy, `.editorconfig`, commit conventions. Closes `CLAUDE.md` §13.2 / §16 Q11. | — | High | Accepted ADR. |
| 9 | Config & secrets | Document the configuration schema and secrets-management approach; add `.env.example` for both apps; decide where the RS256 signing key lives and how it rotates. | — | High | `.env.example` committed; approach documented. Closes `CLAUDE.md` §15 item 8. |
| 10 | Vendor provisioning | Project owner opens sandbox accounts (Twilio + **start India SMS DLT registration**, SendGrid, Google Maps, Anthropic, AWS Textract) and records key-management ownership. | ADR-0002 | High | A tracker of account and key status. |
| 11 | Clarifications | Obtain written answers to **Q3** (ADR-0003 biometric wording vs D32), **Q9** (is AI-4 inside the MVP release window?), and confirm the dual-`.docx` scope for MVP. | — | High | Answers appended to the relevant ADRs and `CLAUDE.md` §16. |

---

## 3. Acceptance Criteria

- [ ] `physical-schema.md` covers all 20 entities with types, PK/FK, indexes, enums, and JSON shapes; **reviewed and approved by the project owner**; Q2 answered in writing.
- [ ] Every operational table carries the five RBAC columns (`tenant_id`, `created_by_user_id`, `assigned_surveyor_id`, `reviewer_id`, `access_role_scope`) per SRS §5.1.
- [ ] Migration files exist and apply cleanly to a **local** Postgres; the runbook states that migrations are never run automatically.
- [ ] `openapi.yaml` v1 is reviewed and frozen under an explicit change-control note; it uses the ADR-0004 success/error envelopes and pagination `meta`.
- [ ] `packages/types` builds from the contract and is importable by `apps/mobile`.
- [ ] CI is green on the repository: install, lint, typecheck, test.
- [ ] `go run ./cmd/server` serves `/healthz` and connects to local Postgres via `pgx`.
- [ ] The React Native app builds and boots on an iOS simulator and an Android emulator.
- [ ] ADR-0005 (conventions) accepted; `.env.example` committed for both apps.
- [ ] The vendor tracker exists, with India SMS DLT registration started.
- [ ] Q3, Q9, and the dual-`.docx` MVP scope have written answers.

---

## 4. Dependencies

None. This is the entry sprint. Every other sprint depends on tasks 1, 3, 5, 6, and 7.

---

## 5. Risks & Open Questions

| Item | Detail |
| :-- | :-- |
| **R8** | The 10 draft entities in SRS §5.2 are explicitly "draft, pending detailed schema review". Churn here ripples into migrations, OpenAPI, and types. Mitigation: owner review before sprint_0003 starts; change control on the frozen contract. |
| **R4** | Twilio India SMS DLT registration commonly takes weeks. Starting it now is why OTP login can remain a Should-Have without blocking access. |
| **Q2** | `follow_up_visits` as a separate table or an extension of `site_visits`; `preservation_notices` as its own table or folded into `contact_logs`/`documents`. Must be decided here. |
| **Q3** | ADR-0003 §3.1 says the idle lock uses "device biometrics"; ADR-0001 D32 defers biometrics to post-MVP. Needs reconciliation before sprint_0004. |
| **Q9** | Whether AI-4 must ship inside the MVP window determines if sprint_0014 is a release gate. |
| OpenAPI churn | The contract may need changes once stage screens are built. Freeze with an explicit change-control process rather than pretending it is immutable. |

---

## 6. Definition of Done

Global DoD (see [`../README.md`](../README.md) §6) plus:

- Every artifact in tasks 1, 3, 8, and 9 is **reviewed and approved by the project owner** before any dependent sprint begins.
- No code in any sprint depends on an unfrozen contract.
- No migration has been executed against a shared or production database.
- The completion report distinguishes Implemented / Reviewed / Tested / Verified.
