# ADR-0005 — Identity Model: Store/Client Naming, DB-Driven RBAC, Invite-Only Join & Auth Telemetry

- **Status:** Accepted
- **Date:** 2026-08-30
- **Deciders:** Project owner (vipul@tezminds.com)
- **Amends:** `Requirement.MD` §5.1 and §5.2 (entities 11–13), ADR-0003 §1 and §3.1, ADR-0004 §4
- **Context:** `Requirement.MD` §5.2 entities 11–20 were added by ADR-0001 (D27) as an explicitly *draft, indicative* field list, "pending detailed schema review". `sprint_0001` cannot freeze the schema contract and `sprint_0003` cannot build authentication until the identity model is finalized. Four identity questions were formally open: the multi-user firm model (`sprint_0003` Q8, recorded as *"undefined even at schema level"*), multi-device sessions (`sprint_0002` Q12), the `permissions` JWT claim that ADR-0003 names but nothing defines, and the `REVIEWER`/`ADMIN` capability matrix. The project owner additionally requires every user to carry store and client identifiers, real RBAC structure, signup IP provenance, last-login state, and logout information — none of which existed anywhere in the documentation.

---

## Decisions

### D38 — `store` replaces `tenant`; `client` replaces `created_by_user_id`

The surveyor firm — the parent company that owns all records — is a **store**. The employee who logs in is a **client**.

| Was | Is |
| :-- | :-- |
| `tenants` table | **`stores`** |
| `tenant_id` column | **`store_id`** |
| `created_by_user_id` column | **`client_id`** (FK → `users.id`) |
| `assigned_surveyor_id`, `reviewer_id`, `access_role_scope` | unchanged |

The five common columns fixed by `Requirement.MD` §5.1 become: **`store_id`, `client_id`, `assigned_surveyor_id`, `reviewer_id`, `access_role_scope`.**

`store_id` is not an alias for `tenant_id` and both names do not coexist. There is one name.

**Why now.** This contradicts `Requirement.MD` §5.1, ADR-0004 §4, `User Stories.md` AC 16.2, and the acceptance criteria of `sprint_0001` and `sprint_0015`, so it is recorded as a formal amendment rather than applied silently. The repository contains zero migrations and zero `.go`/`.ts`/`.sql` files — the cost today is a documentation sweep, whereas the same rename after `sprint_0001` freezes the contract would span 20 tables, the OpenAPI spec, generated TypeScript types, and every repository method.

**Scope of the five columns.** §5.1's literal "all database entities" is impossible for a global catalogue like `permissions`. Precise rule, recorded in `physical-schema.md` §1: operational tables carry all five; identity tables carry `store_id` and `client_id` where an owner exists; global catalogue tables carry none; `stores` is the tenancy root and carries none.

### D39 — Full database-driven RBAC

Five tables: `permissions`, `roles`, `role_permissions`, `user_roles`, `claim_access_grants`. A user may hold **multiple roles**.

- The **permission catalogue is code-defined and seeded** (~35 `resource:action` codes) and is never written at runtime. A store-authored permission would name a capability no handler enforces.
- **System roles** (`SURVEYOR`, `REVIEWER`, `ADMIN`, `INSURER_VIEWER` — the `Requirement.MD` §5.1 enum) are global and immutable, stored with `store_id IS NULL`.
- **Custom roles** are store-scoped, composed from the seeded catalogue only. A `CHECK` constraint makes system and custom roles structurally exclusive, so no store can shadow a seeded role.
- `users.access_role_scope` is **retained** as a denormalised primary role for §5.1 compatibility and display. `user_roles` is authoritative for authorization.
- `users.permissions_version` is incremented on any privilege change and mirrored in the JWT `pv` claim, so a stale access token is rejected within one 15-minute lifetime instead of persisting for the 30-day refresh window. This defines the `permissions` claim ADR-0003 §1 named but never specified.
- **`claim_access_grants`** implements `Requirement.MD` §5.1 rule 2: insurer access is per-claim, time-boxed, and revocable. Holding `insurer:claim:read` is necessary but not sufficient — a live grant for that specific claim is also required, and every read under a grant writes an `audit_log` row per §5.1 rule 3.

**MVP enforcement boundary.** Per `User Stories.md` AC 16.2.2, per-permission gating of UI actions is deferred post-MVP, as is the role-administration UI. The tables, middleware, `pv` revocation, and **store isolation on every endpoint** ship in MVP. Store isolation is not deferred: "RBAC enforcement is future work" refers to intra-store role restrictions, never to cross-store data separation.

### D40 — Invite-only store join (resolves `sprint_0003` Q8)

`POST /auth/register` **always creates a new store**, and makes the registrant its `owner_user_id` with the `ADMIN` role. A matching `firm_name` is never joined automatically, and `stores.firm_name` is deliberately **not unique**.

Adding a colleague requires an `ADMIN` to issue a single-use, expiring invite (`store_invites`, SHA-256 token hash), which the recipient accepts to land in the existing store with the role the invite names.

**Why not firm-name matching.** Firm names are neither unique nor verified. Auto-joining on a name match would let anyone who can spell a firm's name reach its claim files — an unacceptable outcome for regulated survey work product that `Requirement.MD` §5.1 rule 4 defines as the surveyor's exclusive property.

**Founder role note.** The founder is stored with `access_role_scope = 'SURVEYOR'` (their professional role, which appears on reports) *and* granted the `ADMIN` role in `user_roles` (their administrative capability). This refines `00_auth_signup.md` §5, which states only `SURVEYOR`; multi-role assignment is what makes both true at once. Without it, the person who created a store could not invite anyone into it.

### D41 — Multi-device sessions with rotation and reuse detection (resolves `sprint_0002` Q12)

Concurrent use on multiple devices is **in scope**. One `ACTIVE` `sessions` row per `(user_id, device_id)`, with history retained. `sync_queue` is already keyed by `device_id`, so the sync design absorbs this unchanged.

Two corrections to the recorded specification:

1. **`sessions.encrypted_token_ref` → `refresh_token_hash`.** `Requirement.MD` §5.2 entity 13 implied a reversible reference, but ADR-0003 §1 requires the refresh token be *hashed* with Argon2id. Encryption is reversible and would let a database compromise yield live refresh tokens. ADR-0003 governs; the column name now states what it holds.
2. **ADR-0003 §3.1 amended to passcode-only.** As written it says the 15-minute idle lock uses "local passcode / device **biometrics**", which contradicts ADR-0001 D32, `Requirement.MD` §2.3, and `sprint_0004` task 4 — all of which defer biometrics post-MVP. Passcode only. This resolves the open Q3.

Refresh tokens rotate on every use; all descendants of one login share a `refresh_token_family_id`. Presenting an already-superseded token revokes the entire family, logs `TOKEN_REUSE_DETECTED`, and forces re-authentication.

Supporting entities added: `user_devices` (stable device identity, remote revoke anchor), `store_invites`, `otp_challenges`, `password_reset_tokens`. The last two are **defined now and wired later** — `sprint_0003` §5 defers OTP (Twilio India DLT, risk R4) and password reset (email vendor) — so those sprints need no second migration.

### D42 — Full auth telemetry: denormalised state plus an append-only event log

Two layers, deliberately:

**Columns on `users`** — `signup_ip` and the full signup provenance block (user agent, device, platform, country/region/city/ASN/ISP/timezone, source, inviter); `last_login_at`/`_ip`/`_user_agent`/`_device_id`; `previous_login_at`/`previous_login_ip`; `last_seen_at`; `login_count`; `last_logout_at`/`last_logout_reason`; `failed_login_count`/`last_failed_login_at`/`locked_until`. Plus lifecycle state that did not previously exist anywhere: `status`, `email_verified_at`, `mobile_verified_at`, `terms_accepted_at`, `terms_version`.

**`auth_events`** — an append-only log of 22 event types covering signup, login success and failure, OTP, token refresh and reuse, logout, revocation, password changes, lockout, role grants, invites, and offline unlock/expiry. Immutability is enforced by a `BEFORE UPDATE OR DELETE` trigger **and** by `REVOKE UPDATE, DELETE` from the application role. This satisfies `sprint_0004`'s acceptance criterion that authentication events are logged append-only.

`auth_events` is deliberately **separate from `audit_log`** (SRS entity 14): different shape (no old/new value), different cardinality (failed logins spike under attack), different retention, different audience. Merging them would impose a lowest-common-denominator schema on both and let an auth flood bury financial-change history.

**Privacy constraints.** Failed logins store only a SHA-256 of the attempted identifier — a failed login may name an account that does not exist, and storing it raw would accumulate an unauthenticated log of third parties' contact details. No password, OTP code, or token appears in any column or log line. Geo-IP enrichment (ADR-0006) is best-effort and every geo column is nullable; authentication never blocks on it.

### D43 — Identifier uniqueness is global, not per-store

`email`, `mobile`, and `username` are unique across the entire platform, via partial unique indexes that exclude soft-deleted rows.

This is forced by the design, not preferred: login accepts a bare identifier with no store context (`00_auth_login.md` §4), and `sprint_0003` task 2 requires resolution to a single user. Under per-store uniqueness the same email could exist in two stores with no way for the user to disambiguate.

Consequence: one human, one account. A surveyor genuinely employed by two firms needs a second identifier until a `store_memberships` model is added post-MVP.

---

## Consequences

**Documentation.** `Requirement.MD` §5.1/§5.2, `User Stories.md` AC 16.2, ADR-0003 §1/§3.1, ADR-0004 §4, `sprints/` 0001–0004 and 0015, the `00_auth` screen specs, and `CLAUDE.md` are all reconciled to this ADR in the same change set. `documentation/architecture/physical-schema.md` and `identity-and-rbac.md` are the resulting contract.

**Sprints.** `sprint_0001` inherits a pre-resolved identity slice and need only produce DDL for the remaining claim-workflow entities. `sprint_0003` gains invite, session-management, and RBAC-seeding tasks, and closes Q8. `sprint_0002` closes Q12. `sprint_0004` closes Q3.

**Migrations.** None are generated by this ADR. `sprint_0001` task 2 emits the first migration set covering all entities at once, and per its runbook migrations are never executed automatically.

**Cost accepted.** A rename touching roughly a dozen documents, taken deliberately at the only moment it is free.

## Open items — flagged, not decided

1. **`users.username` capture** — assumed NULL at signup and set later from Profile; the alternative adds an optional input to `00_auth_signup.md` §4 Step 2.
2. **Keychain/Keystore wipe recovery** (`sprint_0004` Q7) — forcing online re-authentication is clear; the local-data-loss warning shown to the surveyor is not.
3. **RS256 signing-key custody and rotation** (`sprint_0001` task 9) — needs its own ADR; no schema impact.
4. **`auth_events` retention period** — no retention policy exists anywhere in the documentation; the table grows unbounded without one.
5. **Multi-store membership** — out of MVP scope; see D43.
