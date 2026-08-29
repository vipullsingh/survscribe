# Identity, Authentication & RBAC Architecture

> **Document type:** Engineering architecture specification.
> **Version:** 1.0.0 · **Created:** 2026-08-30 · **Status:** Draft — awaiting project-owner approval.
> **Companion:** [`physical-schema.md`](physical-schema.md) holds the DDL. This document holds the runtime behaviour.
> **Governing decisions:** ADR-0003, ADR-0004, **ADR-0005**, ADR-0006.

---

## 1. Vocabulary

| Term | Means | Table |
| :-- | :-- | :-- |
| **Store** | The surveyor firm / parent company. The tenancy boundary. | `stores` |
| **Client** | The employee — a person who logs in. | `users` |
| **Role** | A named bundle of permissions, system-wide or store-defined. | `roles` |
| **Permission** | An atomic `resource:action` capability, code-defined. | `permissions` |
| **Session** | One device's live login, holding one refresh token. | `sessions` |

`client_id` is `users.id`. `store_id` is `stores.id`. These are the two scoping keys present on every operational record.

---

## 2. Token contract

### 2.1 Access token — JWT, RS256, 15 minutes (ADR-0003 §1)

```
{
  "iss": "survscribe",
  "aud": "survscribe-api",
  "sub": "<users.id>",              // the client_id
  "jti": "<unique token id>",
  "iat": 1756512000,
  "exp": 1756512900,                // iat + 15 min

  "store_id":  "<stores.id>",
  "client_id": "<users.id>",        // explicit; mirrors sub for read clarity
  "sid":       "<sessions.id>",
  "roles":     ["SURVEYOR"],
  "perms":     ["claim:read", "claim:update", "report:submit", ...],
  "pv":        3                    // users.permissions_version
}
```

**`pv` is the revocation lever.** A JWT cannot be un-issued. Any role or permission change increments `users.permissions_version`; the auth middleware compares the token's `pv` against the stored value and rejects on mismatch, forcing a refresh that mints correct claims. A privilege change therefore takes effect within **one access-token lifetime at worst, and immediately on the next refresh** — not after the 30-day refresh window.

**Claim-size guard.** `perms` is bounded by the ~35-code catalogue and short codes; an `ADMIN` token carries roughly 700 bytes of permissions. If a future catalogue pushes the encoded token past **4 KB** (the practical HTTP header limit), the fallback is to drop `perms`, keep `roles`, and resolve permissions server-side from a cache. The middleware is written to handle a token with no `perms` claim from day one so this switch needs no client change.

### 2.2 Refresh token — opaque, 64 bytes, 30 days

Generated from a CSPRNG, returned to the client exactly once, and stored only as an **Argon2id hash** in `sessions.refresh_token_hash`. It is never returned by any `GET`, never logged, and never recoverable from the database.

### 2.3 Rotation and reuse detection

Every refresh mints a new refresh token and a new `sessions` row sharing the predecessor's `refresh_token_family_id`; the predecessor becomes `SUPERSEDED`.

Presenting a token whose session is already `SUPERSEDED` means the token was captured and replayed. The server then:

1. Revokes **every** session in that `refresh_token_family_id`.
2. Writes `TOKEN_REUSE_DETECTED` to `auth_events`.
3. Increments `permissions_version`, invalidating outstanding access tokens.
4. Forces full re-authentication.

This is why sessions are rows rather than a mutable token column: without the family lineage, a stolen-and-rotated token is indistinguishable from a legitimate one.

### 2.4 Signing keys

RS256 with an asymmetric pair, so verification never requires the private key. Keys are referenced by `kid` in the JWT header, and the middleware accepts any key in the active set — allowing rotation without invalidating live tokens. **Key custody and the rotation schedule are `sprint_0001` task 9 and need their own ADR**; nothing in this document depends on the outcome.

---

## 3. Request pipeline

```
RequestID
  └─ RealIP            trusted-proxy list → the true client IP
      └─ Authenticate  verify JWT signature, exp, pv
          └─ StoreScope   inject store_id into request context
              └─ RequirePermission("claim:read")
                  └─ handler
```

### 3.1 `RealIP` is a correctness dependency, not a convenience

`users.signup_ip`, `users.last_login_ip`, `sessions.created_ip` and every `auth_events.ip_address` are only meaningful if the recorded address is the client's. Behind a load balancer, the socket address is the balancer's. The middleware therefore resolves the client IP from `X-Forwarded-For` **only** for requests arriving from a configured trusted-proxy CIDR list, and otherwise uses the socket address. Without that list an attacker sets their own `X-Forwarded-For` and the entire IP audit trail becomes attacker-controlled fiction.

### 3.2 `StoreScope` and the isolation rule

`store_id` is read from the **verified token**, injected into the request context, and passed to every repository call. It is never read from a request body, query string, or path parameter.

Every repository method signature therefore begins with the scope:

```go
func (r *ClaimRepo) GetByID(ctx context.Context, storeID, claimID uuid.UUID) (*Claim, error)
```

A method that queries by `claimID` alone is a cross-store data leak, and code review treats it as one. `sprint_0015` task 4 already mandates negative cross-store tests per resource.

PostgreSQL row-level security is noted as defence in depth for a later hardening pass — valuable, but it protects against a class of bug the repository signature already prevents, so it is not MVP.

### 3.3 `RequirePermission`

Reads `perms` from the token. On a token without `perms`, it resolves them from `user_roles → role_permissions → permissions` through a short-TTL in-process cache keyed by `(user_id, permissions_version)` — so the cache self-invalidates on any privilege change rather than needing explicit eviction.

**Insurer access needs a second check.** `insurer:claim:read` grants nothing by itself. The handler must additionally find a live `claim_access_grants` row for that exact claim, and every read served under a grant writes an `audit_log` entry (`Requirement.MD` §5.1 rule 3).

### 3.4 MVP enforcement boundary

Per `User Stories.md` AC 16.2.2, role scopes are stored "without restricting MVP UI actions". Concretely:

- **Shipping in MVP:** the tables, the middleware, `pv` revocation, and **store isolation on every endpoint**.
- **Deferred post-MVP:** per-permission gating of UI affordances, and the role-administration UI.

Store isolation is emphatically *not* deferred. "RBAC enforcement is future work" refers to intra-store role restrictions, never to cross-store data separation.

---

## 4. Flows

### 4.1 Registration — always creates a new store

`POST /api/v1/auth/register`, one transaction:

1. Validate Step 1 (name, firm, mobile, email) and Step 2 (password complexity, ToS accepted). License fields are syntax-checked **only if supplied** (FR-0.2, AC 0.2.2).
2. `INSERT stores` with `owner_user_id` NULL.
3. `INSERT users` — `store_id`, `access_role_scope = 'SURVEYOR'`, `signup_source = 'SELF_SIGNUP'`, `terms_accepted_at`/`terms_version`, and the full signup provenance block (IP, user agent, device, geo).
4. `UPDATE stores SET owner_user_id` (deferred FK resolves at commit).
5. `INSERT user_roles` granting the seeded **`ADMIN`** system role — the founder of a store administers it.
6. `INSERT sessions` + `INSERT auth_events (SIGNUP, SUCCESS)`.
7. Return access + refresh tokens; navigate to `01_dashboard` (AC 0.2.3).

> Note the deliberate divergence from `00_auth_signup.md` §5, which says registration assigns `SURVEYOR`. The founder is stored as `access_role_scope = 'SURVEYOR'` (their professional role, and what appears on reports) **and** granted the `ADMIN` role in `user_roles` (their administrative capability). Multi-role assignment is exactly what makes this expressible; without it, the person who created the store could not invite anyone into it.

### 4.2 Joining an existing store — invite only

Resolves `sprint_0003` Q8, recorded as undefined "even at schema level".

1. An `ADMIN` posts `POST /api/v1/store-invites` with an email and a `role_id`.
2. The server mints a single-use token, stores its SHA-256 in `store_invites.token_hash`, and dispatches the raw token by email via `NotificationService` (SendGrid, ADR-0002). `INVITE_SENT` is logged.
3. The recipient opens the link and posts `POST /api/v1/store-invites/{token}/accept` with their profile and password.
4. The server creates the user inside the **inviting store**, `signup_source = 'INVITE'`, `invited_by_user_id` and `invite_id` populated, and grants the invited role. `INVITE_ACCEPTED` is logged.

A matching `firm_name` never joins anything. Firm names are not unique and not verified; auto-joining on one would let anyone who can spell a firm's name enter its claim files.

### 4.3 Login

1. Resolve the universal identifier: email, E.164 mobile, or username → exactly one user (global uniqueness, `physical-schema.md` §6.3). No match still performs a dummy Argon2id verification so response timing does not disclose account existence.
2. Reject if `status != 'ACTIVE'` or `locked_until > NOW()`.
3. Verify the password (Argon2id). On failure: increment `failed_login_count`, set `last_failed_login_at`, apply the lockout policy, log `LOGIN_FAILED` with the **hashed** attempted identifier, and return a generic error.
4. On success, in one transaction: reset `failed_login_count`; shift `last_login_at`/`last_login_ip` into `previous_login_at`/`previous_login_ip`; write the new login values; increment `login_count`; upsert `user_devices`; supersede any existing `ACTIVE` session for that device; insert the new session; log `LOGIN_SUCCESS`.
5. Return the token pair plus the user's roles and permission snapshot.

The `previous_login_*` pair exists so the app can surface *"Last sign-in: 29 Aug, 14:02 from Mumbai"* — the cheapest account-compromise detector available, and one the surveyor is well placed to notice.

### 4.4 Logout

- `POST /auth/logout` — sets the current session to `LOGGED_OUT` with `logout_at`; updates `users.last_logout_at` / `last_logout_reason = 'USER_INITIATED'`; logs `LOGOUT`. The client wipes secure storage and the SQLCipher key handle.
- `POST /auth/logout-all` — revokes every `ACTIVE` session for the user, increments `permissions_version` so outstanding access tokens die immediately, logs `LOGOUT_ALL`.
- `DELETE /auth/sessions/{id}` — revokes one remote session (the "sign out my lost tablet" path), reason `REVOKED_BY_ADMIN` when performed by an ADMIN.
- A password change revokes all sessions except the initiating one, reason `PASSWORD_CHANGED`.

Local data is **not** wiped on logout. An offline claim draft that has not synced is surveyor work product; discarding it on sign-out would destroy field evidence. The client warns when signing out with a non-empty sync queue.

### 4.5 Offline session

- Tokens live in iOS Keychain / Android Keystore via React Native Encrypted Storage (ADR-0003 §2).
- **15-minute idle lock**, re-entry by **device passcode only**. Tokens are not cleared by the lock.
- **30-day offline grace** (`sessions.offline_grace_until`). Past it, local reads still work but mutations are blocked pending online re-authentication.
- The permission snapshot is cached in the encrypted WatermelonDB store at login and refreshed on every successful sync, so permission checks resolve offline.
- `local_auth_event` rows (`OFFLINE_UNLOCK`, `OFFLINE_GRACE_EXPIRED`) queue locally and sync upward; they are append-only on the device too, never mutated or deleted.

> **Contradiction resolved (Q3).** ADR-0003 §3.1 as written says the idle lock uses "local passcode / device **biometrics**". ADR-0001 D32, `Requirement.MD` §2.3, and `sprint_0004` task 4 all defer biometrics to post-MVP. **Passcode only.** ADR-0003 §3.1 is amended accordingly.

---

## 5. Auth telemetry

Two layers, deliberately:

**Denormalised columns** on `users` and `sessions` answer "what is the current state?" in one row read — last login, last logout and why, current failed-attempt count, this session's origin IP. These drive the UI.

**`auth_events`** answers "what happened, and when?" — an append-only record of every authentication-relevant action, successful or not, enforced immutable by trigger and by `REVOKE UPDATE, DELETE`. This satisfies `sprint_0004`'s acceptance criterion that authentication events are logged append-only.

### 5.1 What is deliberately not stored

- **Raw failed identifiers.** A failed login may name an account that does not exist. Storing it raw would accumulate an unauthenticated log of third parties' emails and phone numbers. Only a SHA-256 is kept — still groupable for rate limiting and forensics.
- **Passwords, OTP codes, tokens, or their fragments** — in any column or any log line. `sprint_0003`'s definition of done requires this.

### 5.2 Geo-IP enrichment

`country_code` / `region` / `city` / `asn` / `isp` / `timezone` come from `GeoIPService` (ADR-0006), backed by a local MaxMind GeoLite2 file — no network call, no PII egress, works offline.

**Every geo column is nullable and enrichment is best-effort.** A lookup failure, a missing database file, or a private-range IP must log the event with geo fields NULL. Authentication never blocks on geo-IP. City-level accuracy is roughly 50–70% and ASN accuracy far better; the data is a signal for "this login looks unusual", never evidence of a user's location.

---

## 6. API surface

All paths under `/api/v1`, plural kebab-case, in the ADR-0004 envelopes.

| Method | Path | Permission |
| :-- | :-- | :-- |
| POST | `/auth/register` | public |
| POST | `/auth/login` | public |
| POST | `/auth/token/refresh` | refresh token |
| POST | `/auth/logout` | authenticated |
| POST | `/auth/logout-all` | authenticated |
| GET | `/auth/sessions` | authenticated (own) |
| DELETE | `/auth/sessions/{id}` | own, or `user:update` |
| GET | `/auth/events` | own, or `audit:read` |
| POST | `/auth/otp/request` · `/auth/otp/verify` | public — *deferred, R4* |
| POST | `/auth/password/forgot` · `/reset` | public — *deferred* |
| POST | `/auth/password/change` | authenticated |
| GET/PATCH | `/users/me` | authenticated |
| GET | `/users` | `user:read` |
| POST/GET/DELETE | `/store-invites` | `user:invite` |
| POST | `/store-invites/{token}/accept` | public (token-bearing) |
| GET/PATCH | `/stores/current` | `store:read` / `store:update` |
| GET | `/roles` · `/permissions` | `role:read` |
| PUT | `/users/{id}/roles` | `user:role:assign` |
| POST/DELETE | `/claims/{id}/access-grants` | `claim:assign` |

**Error codes** follow ADR-0004 §3: `VALIDATION_FAILED`, `INVALID_CREDENTIALS`, `ACCOUNT_LOCKED`, `ACCOUNT_INACTIVE`, `TOKEN_EXPIRED`, `TOKEN_REUSE_DETECTED`, `PERMISSION_DENIED`, `STORE_SCOPE_VIOLATION`, `INVITE_EXPIRED`, `DUPLICATE_IDENTIFIER`.

`INVALID_CREDENTIALS` is returned for both an unknown identifier and a wrong password. Distinguishing them turns the login endpoint into an account-enumeration oracle.

---

## 7. Backend layout

Matches the documented `cmd/ + internal/ + pkg/` scaffold and ADR-0002's `internal/platform/*` convention.

```
apps/backend/internal/
├── model/         store.go  user.go  session.go  rbac.go  auth_event.go  device.go
├── repository/    store_repo.go  user_repo.go  session_repo.go
│                  rbac_repo.go  auth_event_repo.go  invite_repo.go
├── service/       auth_service.go       login, register, refresh, logout
│                  identity_service.go   profile, invites, devices
│                  rbac_service.go       role resolution, permission cache
│                  session_service.go    rotation, reuse detection, revocation
├── handler/       auth_handler.go  user_handler.go  store_handler.go  rbac_handler.go
├── platform/      notification/{sms,email}   Twilio / SendGrid adapters (ADR-0002)
│                  geoip/                     GeoIPService (ADR-0006)
│                  token/                     RS256 signer, key set, rotation
├── pkg/crypto/    argon2id.go  random.go  hash.go
└── server/middleware/
                   request_id.go  real_ip.go  authenticate.go
                   store_scope.go  require_permission.go
```

Every `platform/` package is an interface with a config-selected adapter, per `Requirement.MD` §4.2 — vendors are swappable by environment variable with no code change.

**Argon2id parameters** are centralised in `pkg/crypto` (one place to retune), stored alongside each hash via `users.password_algo`, and applied to passwords, refresh tokens, and OTP codes.

---

## 8. Mobile layout

Feature-first, per `CLAUDE.md` §13.1.

```
apps/mobile/src/
├── features/auth/
│   ├── api/          register.ts  login.ts  refresh.ts  logout.ts  sessions.ts
│   ├── components/   OTPBottomSheet, PasswordStrengthMeter, SessionCard,
│   │                 LicenseDisclaimer
│   ├── hooks/        useAuth, usePermissions, useIdleLock
│   ├── screens/      LoginScreen, SignupStep1, SignupStep2, TermsScreen,
│   │                 LockScreen, SessionsScreen, InviteAcceptScreen
│   ├── store/        authStore.ts  permissionStore.ts
│   └── types/        generated from the OpenAPI contract
├── infrastructure/storage/  secureStorage.ts   Keychain / Keystore
│                            database.ts        WatermelonDB + SQLCipher
└── shared/api/client.ts     401 → refresh → retry interceptor
```

**`client.ts` refresh discipline.** A 401 triggers exactly one refresh attempt, and concurrent 401s share a single in-flight refresh promise — otherwise ten parallel requests fire ten rotations, nine of which present a superseded token and trip reuse detection, logging the user out for being online. This is the single most important detail in the client.

**Local WatermelonDB models:** `local_user` (cached profile), `local_session`, `local_permissions` (the offline snapshot), `local_auth_event` (append-only, syncs upward).

**`usePermissions`** reads the cached snapshot, so the same permission check works online and offline. In MVP it drives display only, per §3.4.

---

## 9. Threat model — what this design defends against

| Threat | Control |
| :-- | :-- |
| Stolen refresh token | Rotation + family reuse detection (§2.3) |
| Stolen access token | 15-minute lifetime + `pv` invalidation (§2.2) |
| Database compromise | Argon2id on passwords, refresh tokens, OTP codes; SHA-256 on invite/reset tokens; no reversible secret at rest |
| Cross-store data access | `store_id` from token only; scoped repository signatures (§3.2); negative tests in `sprint_0015` |
| Account enumeration | Uniform `INVALID_CREDENTIALS`; dummy hash verification on unknown identifier |
| Brute force | `failed_login_count` + `locked_until`; per-IP and per-identifier rate limits from `auth_events` |
| Spoofed audit IPs | Trusted-proxy list on `RealIP` (§3.1) |
| Tampered auth history | Append-only trigger + `REVOKE UPDATE, DELETE` (§5) |
| Lost/stolen device | Remote session and device revocation (§4.4); 15-min passcode lock; SQLCipher at rest |
| Privilege escalation via role grant | `roles_system_is_global` check; store-match assertion on `user_roles` (§7.4 of the schema) |

**Not defended against, and out of MVP scope:** a rooted or jailbroken device with the passcode (SQLCipher keys live in the OS keystore, which a rooted device can reach); server-side key compromise (mitigated only by rotation, `sprint_0001` task 9).

---

## 10. Open items

Carried from `physical-schema.md` §14 — `users.username` capture, Keychain wipe recovery (`sprint_0004` Q7), RS256 key custody (`sprint_0001` task 9), `auth_events` retention, and multi-store membership. None block implementation of the above; each is flagged for owner decision.
