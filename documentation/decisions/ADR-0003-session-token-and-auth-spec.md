# ADR-0003 — Session Token, Authentication & Offline Security Specification

- **Status:** Accepted
- **Date:** 2026-08-30
- **Deciders:** Project owner (vipul@tezminds.com)
- **Context:** Mobile offline usage and multi-tenant security require an explicit token lifecycle, encryption strategy, and offline re-authentication model.

---

## Decisions

### 1. Dual-Token Architecture (JWT Access + Opaque Refresh)
- **Access Token:** Short-lived JWT (RS256 signed, 15-minute expiration) containing `user_id`, `tenant_id`, `role`, and `permissions` scope.
- **Refresh Token:** High-entropy opaque token (64-byte random, 30-day expiration) stored hashed (Argon2id) in PostgreSQL backend.

### 2. Mobile Storage & Encryption
- Tokens on device MUST be stored in native secure hardware storage (**iOS Keychain** / **Android Keystore** via React Native Encrypted Storage).
- Local WatermelonDB SQLite database encrypted via **SQLCipher (AES-256-CBC)**.

### 3. Offline Expiry & Re-entry Security
- **Active Session Idle Lock:** 15 minutes of user inactivity triggers local passcode / device biometrics lock screen without clearing cached session tokens.
- **Max Offline Session Duration:** 30 days maximum offline operation. If un-synced after 30 days, token invalidates and re-authentication via online network is required.

---

## Consequences

- Stage 0 (Auth) mobile UI and backend middleware will enforce JWT verification and SQLCipher database encryption initialization on startup.
