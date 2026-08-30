# ADR-0008 — Configuration, Secrets, and RS256 Signing-Key Custody

- **Status:** Proposed — awaiting project-owner approval (`sprint_0001` §6 DoD)
- **Date:** 2026-08-30
- **Deciders:** Project owner (vipul@tezminds.com)
- **Sprint:** `sprint_0001` task 9
- **Closes:** `CLAUDE.md` §15 item 8, §4 item 4, §16 Q13; `sprint_0001` Q13
- **Depends on:** ADR-0003 (token spec), ADR-0005 (identity model), ADR-0007 (conventions)

---

## Context

The repository has no configuration strategy at all: no `.env.example`, no config schema, no statement of where secrets live. `CLAUDE.md` §15 item 8 records this, and names its sharpest instance — **ADR-0003 mandates RS256 access tokens but never says where the private key lives or how it rotates.** ADR-0005 flagged the same gap.

This is a release blocker for `sprint_0003`, which implements login. A signing key improvised during that sprint is a signing key that ends up in a repository or an environment variable in a screenshot.

---

## Decisions

### 1. Configuration is read from the environment, once, at startup

`internal/config.Load()` reads every value at boot, validates all of them, and reports **every** problem at once rather than the first. A misconfigured process exits immediately with a readable list; it never starts in a half-configured state and fails later on the one request that happens to need the missing value.

No value has a production-shaped default. `DATABASE_URL` is required, not defaulted to localhost — a default that silently points a production process at the wrong database is worse than a crash.

### 2. The layers, in precedence order

1. Actual environment variables (what deployed environments use).
2. `apps/backend/.env` in development only, gitignored, never committed.
3. Defaults in `config.Load()`, which exist only for values that are genuinely safe to guess: timeouts, pool sizes, log level.

`.env.example` is committed for both apps and is the documentation of what exists. It carries no real values.

### 3. Nothing secret ships inside the mobile bundle

A React Native bundle is readable on every device it reaches. `apps/mobile/.env.example` therefore contains only an API base URL and an environment name, and says so explicitly.

The app holds no Twilio, SendGrid, Google Maps, Anthropic or AWS credential. It reaches every one of those providers **through the SurvScribe backend**, which holds the keys. This is not only a secrets decision — it is what makes the ADR-0002 vendor choices swappable without shipping a new app version to surveyors who may be offline for up to 30 days (CR-A12).

The SQLCipher passphrase protecting the offline claim database is likewise **not** configuration. It is generated on the device at first run and stored in the iOS Keychain / Android Keystore. A passphrase compiled into the bundle would make the AES-256 encryption of CR-NF2 decorative.

### 4. RS256 signing-key custody — **this closes Q13**

**Algorithm and shape.** RS256, 2048-bit minimum, one active signing key at a time, identified by a `kid` in the JWT header.

**Where the private key lives.**

| Environment | Custody |
| :-- | :-- |
| Development | A throwaway key pair generated locally by the developer, in `apps/backend/.env` or a gitignored `secrets/` directory. Never shared, never reused between developers, never promoted. |
| Test / CI | An ephemeral key pair generated at the start of the run and discarded with the job. CI never holds a real key. |
| Staging / Production | The platform secret manager (AWS Secrets Manager, given ADR-0002 already places AWS Textract in `ap-south-1`), injected into the process environment at start. |

Rules that hold everywhere:

- **The private key is never committed**, in any form, in any branch. `*.pem` is already gitignored; this ADR makes it a review-blocking rule as well.
- **The private key is never logged**, never included in an error message, never returned by any endpoint, and never written to a crash report. This is `CLAUDE.md` §14 constraint 17 applied to the key that authenticates every request.
- **The application process does not need write access to the secret store.** It reads its key at boot and nothing else.
- **The public key is not secret.** It may be published at a JWKS endpoint when there is a second service that needs to verify tokens independently. Until then there is only one verifier — the API itself — so no JWKS endpoint is exposed; an endpoint with no consumer is attack surface with no benefit.

**Rotation.**

- **Scheduled:** every 90 days.
- **Immediately, on any suspicion of compromise.**

The rotation procedure is designed around one fact from ADR-0003: **access tokens live 15 minutes, refresh tokens live 30 days.** So rotation must not invalidate refresh tokens, or every surveyor in the field is logged out at once.

1. Generate the new pair; add it to the secret store with a new `kid`.
2. Deploy with the new key **as a verification key only**. The service now verifies tokens signed with either `kid`; it still signs with the old one.
3. After one full access-token lifetime plus a margin (**one hour**), switch signing to the new `kid`.
4. Keep the old key as a verification key for a further hour, then remove it.

Refresh tokens are unaffected throughout: they are opaque 64-byte values Argon2id-hashed in `sessions.refresh_token_hash` (ADR-0005 D41), not JWTs, and carry no signature. **Rotation therefore never forces a re-login** — which matters because a forced re-login for an offline surveyor means being locked out of their own field data until they find a signal.

The verifier must accept a set of keys keyed by `kid`, not a single key. That is a design constraint on `sprint_0003`, recorded here so it is not discovered during a compromise.

**What is deliberately not decided.** The specific secret-manager product is provisional: `ap-south-1` and AWS are inferred from ADR-0002's use of AWS Textract, not from a deployment decision, because **no environment has been provisioned yet** (`sprint_0001` task 10). If hosting lands elsewhere, only the "Staging / Production" row changes; the custody rules and the rotation procedure do not.

### 5. Database credentials

The application connects as a role with `INSERT` and `SELECT` on `audit_log` and `auth_events`, and **not** as the database owner. Owner privileges bypass the `REVOKE UPDATE, DELETE, TRUNCATE` that makes those tables append-only, which would quietly void the immutable-audit guarantee of `CLAUDE.md` §14 constraints 10 and 17 and SRS §6.2.

Migrations run under a **separate, higher-privileged role**, used only by a human running the documented procedure (`apps/backend/migrations/README.md`). The application role cannot alter the schema. A service account that can migrate is a service account that can drop `audit_log`.

The development credentials in `deployments/docker-compose.yml` are committed on purpose: they reach only a disposable container on `localhost`, and pretending they are secret would teach the wrong habit for the ones that are.

### 6. Rotation cadence for everything else

| Secret | Cadence |
| :-- | :-- |
| RS256 signing key | 90 days, or immediately on suspicion |
| Database application password | 180 days, or immediately on suspicion |
| Provider API keys (Twilio, SendGrid, Maps, Anthropic, AWS) | 180 days, or on staff change / suspicion |
| MaxMind GeoLite2 licence key | On expiry |

Every rotation is recorded in the vendor tracker (`documentation/decisions/vendor-tracker.md`) with the date and who performed it.

---

## Consequences

- `sprint_0003` must implement JWT verification against a **key set** keyed by `kid`, not a single key, or the rotation procedure in §4 cannot be executed without downtime.
- A `secrets/` directory and `*.pem` must stay gitignored; `*.pem` already is.
- Provisioning must create two database roles, not one. This belongs in the deployment runbook, which does not exist yet.
- The secret-manager choice is revisited once hosting is decided (`sprint_0017`).
- `CLAUDE.md` §15 item 8 and §16 Q13 are closed by this ADR; §4 item 4 is closed.

---

## Alternatives considered

**HS256 with a shared secret.** Simpler, and rejected. RS256 lets a future verifier — an insurer portal, a reporting service — check a token without holding a key that can *mint* one. ADR-0003 already chose RS256; this ADR keeps it and explains why rotation is worth the extra step.

**Rotating by invalidating all sessions.** Rejected outright. It logs out every surveyor, including those mid-survey on a site with no connectivity, and it converts a routine 90-day maintenance task into an incident. The overlap window in §4 exists precisely to avoid it.

**A JWKS endpoint from day one.** Rejected as premature. There is exactly one verifier today. An unused public endpoint is surface to defend for no current benefit; it is added when a second verifier exists.

**Keeping secrets in CI variables and injecting at deploy.** Rejected as the primary mechanism: CI variables are readable by anyone who can edit a pipeline file, and a pipeline file is a reviewed-but-mutable artifact. A dedicated secret manager gives audited access; CI holds only the credential that reads from it.
