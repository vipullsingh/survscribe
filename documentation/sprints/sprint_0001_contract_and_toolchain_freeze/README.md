# Sprint 0001 — Contract & Toolchain Freeze

| | |
| :-- | :-- |
| **Roadmap ref** | S0.1 |
| **Stage** | 0 — Foundation & Technical Readiness |
| **Status** | Complete — awaiting project-owner approval (§16 Q12 of `CLAUDE.md`). All 11 tasks delivered 2026-08-30; nothing here is self-approved. |
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
| 1 | Physical schema | Extend `documentation/architecture/physical-schema.md` with DDL for the **remaining** entities in SRS §5.2 — the 10 core claim-workflow entities plus 15–20 — with column types, PK/FK, indexes, enum value lists, JSON payload shapes. Apply ADR-0004 rules (UUIDv4 public PK, `TIMESTAMPTZ` timestamps, soft deletes on claims/documents, `store_id UUID NOT NULL` on every operational table). Resolve **Q2**. **The identity slice (entities 11–13 and 21–30) is already finalised by ADR-0005 — do not redesign it; extend it.** | SRS §5.2; ADR-0004; **ADR-0005** | Critical | Reviewed, owner-approved schema document. |
| 2 | Migrations | First migration set under `apps/backend/migrations/` matching the schema document. **Not executed against any shared or production database.** Local `docker-compose` Postgres for development only. | Task 1 | Critical | Migration files + a local database that a developer can create on demand. |
| 3 | API contract | `documentation/architecture/api-contract/openapi.yaml` v1: auth, claims CRUD, per-stage sub-resources, sync push/pull, media upload. Standard success and error envelopes plus pagination `meta` per ADR-0004. | Task 1 | Critical | Reviewed OpenAPI specification. |
| 4 | Shared types | Generate `packages/types` from the OpenAPI spec; add `packages/types/package.json` and `tsconfig`. | Task 3 | Critical | `import type { Claim } from "@survscribe/types"` resolves in the workspace. |
| 5 | Monorepo completion | Add per-package `package.json` for `packages/*`; base `tsconfig`; ESLint + Prettier configuration; commit `pnpm-lock.yaml`; wire Turbo `lint`/`test`/`build` tasks; GitHub Actions CI running lint + typecheck + test. | root scaffold | Critical | `pnpm install && pnpm lint && pnpm test` green in CI. |
| 6 | Backend skeleton | `cmd/server/main.go`; `internal/{config,server,handler,repository,service,model,pkg}`; Gin router; response-envelope middleware; `pgx` connection pool; `/healthz`; structured logging. | Tasks 1, 2 | Critical | `go run ./cmd/server` serves `/healthz` against local Postgres. |
| 7 | Mobile skeleton | Initialise the React Native + TypeScript app in `apps/mobile`; feature-first folder layout per ADR-0001 D19; navigation shell with the canonical 5-tab bottom nav placeholder; environment handling; runs on iOS simulator and Android emulator. | Task 5 | Critical | App boots to a placeholder Dashboard on both platforms. |
| 8 | Conventions ADR | **ADR-0007** (renumbered — 0005 and 0006 were taken by the identity model and geo-IP provider): testing frameworks (Go `testing` + `testify`; mobile Jest + React Native Testing Library; Detox for e2e later), branching strategy, `.editorconfig`, commit conventions. Closes `CLAUDE.md` §13.2 / §16 Q11. | — | High | Accepted ADR. |
| 9 | Config & secrets | Document the configuration schema and secrets-management approach; add `.env.example` for both apps; decide where the RS256 signing key lives and how it rotates (**ADR-0008** — flagged as open by ADR-0005). | — | High | `.env.example` committed; approach documented. Closes `CLAUDE.md` §15 item 8. |
| 10 | Vendor provisioning | Project owner opens sandbox accounts (Twilio + **start India SMS DLT registration**, SendGrid, Google Maps, Anthropic, AWS Textract) and records key-management ownership. | ADR-0002 | High | A tracker of account and key status. |
| 11 | Clarifications | Obtain written answers to **Q9** (is AI-4 inside the MVP release window?) and confirm the dual-`.docx` scope for MVP. **Q3 is closed** — ADR-0005 (D41) amended ADR-0003 §3.1 to passcode-only. | — | High | Answers appended to the relevant ADRs and `CLAUDE.md` §16. |

---

## 3. Acceptance Criteria

- [x] `physical-schema.md` covers all **38** tables (30 SRS-named entities + 8 net additions after folding `follow_up_visits` into `site_visits` — see §17) with types, PK/FK, indexes, enums, and JSON shapes; Q2 answered in writing (§17). **Not yet reviewed/approved by the project owner** — `CLAUDE.md` §16 Q12 is the tracking item; this checkbox is left unchecked in spirit even though the artifact exists.
- [x] Every operational table carries the five RBAC columns per SRS §5.1 as amended by ADR-0005 (D38); identity and global catalogue tables follow the narrower §1 rule. Verified by inspection of every `CREATE TABLE` in Part B.
- [x] Migration files exist, are structurally verified (`apps/backend/scripts/check_migrations.py`, 0 errors), and apply cleanly to a **disposable CI Postgres** (apply-then-roll-back, `.github/workflows/ci.yml` job `migrations`). **Not yet applied to a standing local Postgres by a human** — the `docker-compose.yml` and runbook exist, but no one has run the apply step against a persistent instance. The runbook states migrations are never run automatically.
- [x] `openapi.yaml` v1 is generated, lints clean (`redocly lint`, 0 errors), and is frozen under an explicit change-control note in its own `info.description`; uses the ADR-0004 envelopes and pagination `meta`.
- [x] `packages/types` builds from the contract; `apps/mobile` imports it (`src/shared/api/client.ts`, `@survscribe/types`) and typechecks.
- [x] CI is green **locally, run with equivalent commands** (`pnpm install`, `pnpm run format:check/lint/typecheck/test`, `go build/vet/test`, migration apply/rollback) — **not yet confirmed inside GitHub Actions itself**, since no push/PR has triggered the workflow.
- [x] `go run ./cmd/api` (not `./cmd/server` — see `apps/backend/cmd/api/main.go`) fails fast and legibly with no `DATABASE_URL`, and fails fast and legibly against an unreachable Postgres. **Not verified against a reachable local Postgres** — no standing instance exists in this environment to connect to.
- [ ] The React Native app **typechecks** cleanly but has **not** been built or booted on an iOS simulator or Android emulator — no such toolchain exists in this development environment. Genuinely unverified, left unchecked.
- [x] `.env.example` committed for both apps. ADR-0007 (conventions) is **written and Proposed, not yet Accepted** — needs the same owner sign-off as the schema.
- [x] The vendor tracker (`documentation/decisions/vendor-tracker.md`) exists. **India SMS DLT registration has NOT been started** — it is an owner action (requires a company identity and regulatory filing) and is flagged as the single most urgent open item in the tracker.
- [x] Q9 and the dual-`.docx` MVP scope have written answers — ADR-0009 (Accepted): AI-4 is a post-launch fast-follow; MVP ships the server-side `.docx` engine only.

---

## 4. Dependencies

None. This is the entry sprint. Every other sprint depends on tasks 1, 3, 5, 6, and 7.

---

## 5. Risks & Open Questions

| Item | Detail |
| :-- | :-- |
| **R8** | The remaining draft entities in SRS §5.2 (15–20) are drafted now (`physical-schema.md` Part B, 2026-08-30) but **not yet owner-reviewed**. Churn is now bounded to §38's `[ADDITION]` list plus the specific open items (§38, §16 Q18–Q20), rather than the whole schema. Mitigation unchanged: owner review before sprint_0003 starts; change control on the frozen contract. **The identity slice (11–13, 21–30) remains fully out of scope for churn — ADR-0005 finalised it.** |
| **R4** | Twilio India SMS DLT registration commonly takes weeks. **Still NOT started** as of 2026-08-30 (see `vendor-tracker.md`) — flagged there as the one urgent item. Starting it is why OTP login can remain a Should-Have without blocking access, but the mitigation only holds once registration is actually filed. |
| ~~**Q2**~~ | **Closed 2026-08-30.** `follow_up_visits` extends `site_visits` via a `visit_type` enum; `preservation_notices` stays its own table. See `physical-schema.md` §17. |
| ~~**Q3**~~ | **Closed 2026-08-30.** ADR-0005 (D41) amended ADR-0003 §3.1 to device passcode only; biometrics stay deferred per D32. |
| ~~**Q13**~~ | **Closed 2026-08-30 by ADR-0008.** RS256 custody by environment, 90-day rotation via a dual-`kid` overlap window that never forces a re-login. Status: Proposed, awaiting the same owner sign-off as everything else in this sprint. |
| ~~**Q9**~~ | **Closed 2026-08-30 by ADR-0009.** AI-4 is a post-launch fast-follow; `sprint_0014` is not a release gate. |
| OpenAPI churn | The contract may need changes once stage screens are built. It is generated from the migration DDL specifically so a schema change and a contract change happen together, under CI's drift check, rather than needing separate manual synchronization. |

---

## 6. Definition of Done

Global DoD (see [`../README.md`](../README.md) §6) plus:

- Every artifact in tasks 1, 3, 8, and 9 is **reviewed and approved by the project owner** before any dependent sprint begins. **This remains the single open item blocking `sprint_0003`** — every artifact exists (2026-08-30) but none has owner sign-off (`CLAUDE.md` §16 Q12).
- No code in any sprint depends on an unfrozen contract.
- No migration has been executed against a shared or production database.
- The completion report distinguishes Implemented / Reviewed / Tested / Verified.
