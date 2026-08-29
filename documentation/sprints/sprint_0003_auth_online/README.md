# Sprint 0003 — Auth: Online

| | |
| :-- | :-- |
| **Roadmap ref** | S1.1 |
| **Stage** | 1 — Core Data & Application Foundation |
| **Status** | Not started |
| **Depends on** | [`sprint_0001`](../sprint_0001_contract_and_toolchain_freeze/) |
| **Blocks** | sprint_0004 and everything after it |
| **Specs** | [`00_auth_login.md`](../../Screens/00_auth/00_auth_login.md) · [`00_auth_signup.md`](../../Screens/00_auth/00_auth_signup.md) · [`00_auth_terms.md`](../../Screens/00_auth/00_auth_terms.md) |
| **Roadmap** | [`../README.md`](../README.md) |

---

## 1. Sprint Objective

A surveyor can **register and sign in with a password, online**, and reach the dashboard shell. This is the first product feature and the only fully designed screen set in the repository (8 SVG artboards exist), so it also establishes the UI patterns for every later screen.

OTP login and password reset are deliberately **not** in this sprint — see §5.

---

## 2. Features & Tasks

| # | Feature / module | Task | Dependency | Priority | Expected outcome |
| :-- | :-- | :-- | :-- | :-- | :-- |
| 1 | Backend auth | Implement `stores`, `users`, `sessions`, `user_devices`; registration (**always creates a new store**; registrant becomes `owner_user_id` with role scope `SURVEYOR` and the `ADMIN` role); Argon2id password hashing; login issuing an RS256 JWT (15-minute expiry, claims per ADR-0003 §1 as amended) plus an opaque 64-byte refresh token (30-day, stored hashed); refresh rotation with `refresh_token_family_id` reuse detection; logout, logout-all, and per-session revoke. | sprint_0001; ADR-0005 | Critical | Auth endpoints pass contract tests against the OpenAPI spec. |
| 2 | Universal identifier | Resolve a login identifier that may be an email, a custom username, or a 10-digit Indian mobile number to a single user. | Task 1 | Critical | AC 0.1.1 |
| 3 | License validation | Syntax-only `SLA-[0-9]{4,8}` check **when a value is entered**; store nullable; render the mandatory registration disclaimer. Record that License Number + Category become required before FSR generation (D35) without enforcing it at signup. | CR-A7; D35 | Critical | AC 0.2.2 |
| 4 | Login screen | Password login with universal identifier, "Remember Me" (default `true`), validation per `00_auth_login.md` §4, error states. | `packages/ui` | Critical | Matches the login spec and its SVG artboard. |
| 5 | Signup screens | Two-step registration: Step 1 personal/firm (Full Legal Name, Firm Name, Mobile, Email — all mandatory), Step 2 SLA credentials (optional) and password with complexity meter (min 8 chars, ≥1 uppercase, ≥1 number, ≥1 special) plus mandatory Terms consent. | `packages/ui` | Critical | AC 0.2.1, AC 0.2.3, AC 0.2.4 |
| 6 | Terms screen | `00_auth_terms` reachable from signup, with Accept & Continue / Decline actions. | Task 5 | High | CR-A11 |
| 7 | API client | `apps/mobile/src/shared/api/client.ts`: base URL, envelope unwrapping, error mapping to the ADR-0004 error shape, auth header injection, 401 → refresh → retry. | `packages/types` | Critical | Every network call routes through one client. |
| 8 | RBAC foundation | Seed the `permissions` catalogue and the four system roles from versioned Go constants; implement `user_roles` resolution, the `permissions_version` / `pv` revocation path, and the `Authenticate` → `StoreScope` → `RequirePermission` middleware chain. Store isolation is enforced from the first endpoint; per-permission UI gating stays deferred per AC 16.2.2. | Task 1; ADR-0005 D39 | Critical | Seeded roles verified; a cross-store request is rejected. |
| 9 | Store invites | `store_invites` issue / accept / revoke endpoints with SHA-256 token hashing and expiry. Accepting an invite creates the user inside the inviting store with the named role. Closes **Q8**. | Task 8; ADR-0005 D40 | High | AC 0.3.1–0.3.3 |
| 10 | Auth telemetry | Populate signup provenance and login/logout state on `users` and `sessions`; write `auth_events` rows for every authentication action; add the `RealIP` trusted-proxy middleware and the `GeoIPService` adapter (ADR-0006). Failed logins store only a SHA-256 of the attempted identifier. | Task 1; ADR-0006 | Critical | AC 0.2.6, AC 0.4.5 |
| 11 | Session management | `GET /auth/sessions`, `DELETE /auth/sessions/{id}`, `POST /auth/logout-all`, and a Sessions screen listing devices with origin and last-used time. | Task 1 | High | AC 0.4.1–0.4.4 |

---

## 3. Acceptance Criteria

- [ ] **AC 0.1.1** — a valid email, username, or mobile number plus password authenticates and routes to `01_dashboard`.
- [ ] **AC 0.1.5** — "Register as Surveyor" navigates to `00_auth_signup`.
- [ ] **AC 0.2.1** — Full Name, Firm Name, Mobile, and Email are mandatory; License Number, Category, and Base Location are optional and can be skipped entirely.
- [ ] **AC 0.2.2** — license syntax validation plus the verbatim disclaimer: *"License details are provided by the user and are subject to independent verification. Platform registration does not constitute regulatory approval or endorsement."*
- [ ] **AC 0.2.3** — successful signup lands on the dashboard.
- [ ] **AC 0.2.4** — "Already have an account? Sign In" returns to `00_auth_login`.
- [ ] Registration assigns role scope `SURVEYOR`, grants the `ADMIN` role, and initialises a new `store_id` — always, never joining an existing store by firm name (CR-A10, AC 0.2.5).
- [ ] Refresh-token rotation verified; a revoked refresh token is rejected; replaying a superseded token revokes the whole family and logs `TOKEN_REUSE_DETECTED`.
- [ ] Invalid credentials, duplicate email, and weak password render correct, specific error states. An unknown identifier and a wrong password return the **same** `INVALID_CREDENTIALS` error — no account-enumeration oracle.
- [ ] A request carrying a valid token for store A cannot read or write any record in store B.
- [ ] Signup provenance (IP, user agent, device, geo) is recorded; a geo-IP lookup failure records NULL and does not block registration.
- [ ] `auth_events` rows are written for signup, login success and failure, refresh, and logout, and cannot be updated or deleted.
- [ ] No password, OTP code, token, or raw failed identifier appears in any column or log line.
- [ ] Every response uses the ADR-0004 envelope.

---

## 4. Dependencies

- sprint_0001: schema, OpenAPI auth paths, both skeletons, secrets strategy for the RS256 key.
- ADR-0005 + [`architecture/physical-schema.md`](../../architecture/physical-schema.md) and [`architecture/identity-and-rbac.md`](../../architecture/identity-and-rbac.md): the finalised identity contract this sprint implements. Read both before starting — the DDL, flows, middleware chain and threat model are already specified.

---

## 5. Risks & Open Questions

| Item | Detail |
| :-- | :-- |
| RS256 key management | Where the private key lives, how it rotates, and how it is injected in each environment must follow the sprint_0001 secrets strategy — not be improvised here. |
| OTP deferred | Phone OTP (30 s resend) and Email OTP (45 s resend) are Should-Have and gated on Twilio India SMS DLT (**R4**). Password login is the Critical access path. The login screen's OTP tab should be present but visibly disabled or hidden rather than half-wired. |
| Password reset | Requires the email vendor; deferred with OTP. |
| ~~**Q8**~~ | **Closed 2026-08-30 by ADR-0005 (D40).** Registration always creates a new store; joining an existing store is invite-only. Stores are multi-user at schema level from day one, and `stores.firm_name` is deliberately not unique. |
| D35 enforcement | The FSR block on a missing License Number + Category is **implemented in sprint_0013**, not here. Do not enforce it at signup. |
| Concurrent refresh | The mobile client must share a single in-flight refresh promise across concurrent 401s. Firing parallel rotations would present superseded tokens and trip reuse detection, logging the user out for being online. See `identity-and-rbac.md` §8. |
| **Q14** | `users.username` is accepted by the login screen but captured by no signup step. Assumed NULL at signup and set later from Profile; confirm, or add an optional input to `00_auth_signup.md` §4 Step 2. |

---

## 6. Definition of Done

Global DoD (see [`../README.md`](../README.md) §6) plus:

- Security check: no token, password, or refresh token appears in logs; the refresh token is never returned by a GET; passwords are never stored or transmitted in plain text beyond the TLS-protected login call.
- Screens visually match the existing SVG artboards and pass the design-system anti-pattern checklist.
- Auth endpoints have contract tests bound to the frozen OpenAPI spec.
