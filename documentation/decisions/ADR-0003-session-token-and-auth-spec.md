# ADR-0003 — Session Token, Authentication & Offline Security Specification

- **Status:** Accepted — **§1 and §3.1 amended by [ADR-0005](ADR-0005-identity-model-store-client-and-rbac.md) (2026-08-30)**
- **Date:** 2026-08-30
- **Deciders:** Project owner (vipul@tezminds.com)
- **Context:** Mobile offline usage and multi-store security require an explicit token lifecycle, encryption strategy, and offline re-authentication model.

---

## Decisions

### 1. Dual-Token Architecture (JWT Access + Opaque Refresh)
- **Access Token:** Short-lived JWT (RS256 signed, 15-minute expiration).
- **Refresh Token:** High-entropy opaque token (64-byte random, 30-day expiration) stored hashed (Argon2id) in PostgreSQL backend.

> **Amended by ADR-0005 (D38, D39).** The claim set is finalised as `sub` (= `client_id`), `store_id`, `client_id`, `sid` (session id), `roles[]`, `perms[]`, and `pv` (`users.permissions_version`), alongside the standard `iss`/`aud`/`iat`/`exp`/`jti`. This replaces the original `user_id`, `tenant_id`, `role`, `permissions` wording: the tenancy key is now `store_id`, roles are plural (a user may hold several), and the previously undefined `permissions` scope is now the code-defined catalogue in `architecture/physical-schema.md` §7.6.
>
> `pv` is the revocation lever — any privilege change increments `users.permissions_version`, so a stale access token is rejected within one 15-minute lifetime rather than persisting for the 30-day refresh window.

> **Amended by ADR-0005 (D41).** The refresh token is stored in `sessions.refresh_token_hash` (renamed from the SRS's `encrypted_token_ref`, which implied reversible encryption). Tokens rotate on every use; all descendants of one login share a `refresh_token_family_id`, and presenting an already-superseded token revokes the entire family and logs `TOKEN_REUSE_DETECTED`.

### 2. Mobile Storage & Encryption
- Tokens on device MUST be stored in native secure hardware storage (**iOS Keychain** / **Android Keystore** via React Native Encrypted Storage).
- Local WatermelonDB SQLite database encrypted via **SQLCipher (AES-256-CBC)**.

### 3. Offline Expiry & Re-entry Security
- **Active Session Idle Lock:** 15 minutes of user inactivity triggers a local **device-passcode** lock screen without clearing cached session tokens.
- **Max Offline Session Duration:** 30 days maximum offline operation. If un-synced after 30 days, token invalidates and re-authentication via online network is required.

> **§3.1 amended by ADR-0005 (D41) — resolves open question Q3.** This clause originally read "local passcode / device **biometrics**", contradicting ADR-0001 D32, `Requirement.MD` §2.3, and `sprint_0004` task 4, all of which defer biometric unlock to post-MVP. **MVP re-entry is device passcode only.** Biometric unlock may be reinstated post-MVP by a superseding ADR.

---

## Consequences

- Stage 0 (Auth) mobile UI and backend middleware will enforce JWT verification and SQLCipher database encryption initialization on startup.
- The runtime specification of this ADR — request pipeline, rotation, reuse detection, revocation, and offline behaviour — is elaborated in [`../architecture/identity-and-rbac.md`](../architecture/identity-and-rbac.md) §2–§5.
