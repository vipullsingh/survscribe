# Physical Schema — SurvScribe

> **Document type:** PostgreSQL physical schema — the complete entity set.
> **Version:** 2.0.0 · **Created:** 2026-08-30 · **Last updated:** 2026-08-30 · **Status:** Draft — awaiting project-owner approval per `sprints/sprint_0001` R8.
> **Governing decisions:** ADR-0003 (tokens/auth), ADR-0004 (schema rules), **ADR-0005** (identity model — `store`/`client` naming, DB-driven RBAC, invite-only join, auth telemetry), ADR-0006 (geo-IP provider).
>
> **Scope — two parts.**
>
> | Part | Sections | Covers | Status |
> | :-- | :-- | :-- | :-- |
> | **A — Identity** | §1–§15 | `Requirement.MD` §5.2 entities **11–13** and **21–30**: tenancy, users, RBAC, sessions, devices, auth telemetry, invites, OTP and reset tokens. | Finalized by ADR-0005 / ADR-0006. **Do not redesign — extend.** |
> | **B — Claim workflow** | §16–§39 | `Requirement.MD` §5.2 entities **1–10** and **14–20**, plus the child tables the 15-stage workflow requires. Produced by `sprint_0001` task 1; resolves **Q2**. | Draft — first review. |
>
> **No migration is generated from this document yet.** `sprint_0001` task 2 emits the first migration set covering all entities at once, and per its runbook migrations are never executed automatically.

---

# Part A — Identity, Tenancy, RBAC & Auth Telemetry

*Entities 11–13 and 21–30. Finalized by ADR-0005 and ADR-0006.*

## 1. Naming contract

ADR-0005 renames two of the five common columns fixed by `Requirement.MD` §5.1:

| Was | Is | Meaning |
| :-- | :-- | :-- |
| `tenant_id` → `tenants` | **`store_id` → `stores`** | The surveyor firm / parent company that owns the record |
| `created_by_user_id` | **`client_id`** | The employee (user) the record belongs to |
| `assigned_surveyor_id` | `assigned_surveyor_id` | unchanged |
| `reviewer_id` | `reviewer_id` | unchanged |
| `access_role_scope` | `access_role_scope` | unchanged |

**Where the five columns apply.** `Requirement.MD` §5.1 says "all database entities". Read literally that is impossible for a global catalogue table like `permissions`. The precise rule:

- **Operational tables** (every claim-workflow entity, and every table holding surveyor work product) carry all five.
- **Identity tables** (`users`, `sessions`, `user_devices`, `store_invites`) carry `store_id` and, where a distinct owner exists, `client_id`. `assigned_surveyor_id` / `reviewer_id` do not apply and are omitted rather than left permanently NULL.
- **Global catalogue tables** (`permissions`, and `roles` rows where `store_id IS NULL`) carry none — they are cross-store by definition.
- **`stores`** is the tenancy root and carries none.

## 2. Conventions (ADR-0004 §4)

- Public primary keys are `UUID` defaulting to `gen_random_uuid()`. High-volume internal log tables use `BIGSERIAL`.
- `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`, `updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()` maintained by trigger, `deleted_at TIMESTAMPTZ` for soft-deletable entities.
- Append-only tables carry neither `updated_at` nor `deleted_at`.
- All uniqueness on soft-deletable tables is expressed as a **partial unique index** with `WHERE deleted_at IS NULL`, so a deactivated user does not permanently reserve an email address.
- Enumerations are native PostgreSQL `ENUM` types, not `CHECK` constraints, so the value list is introspectable and shared with generated Go/TS types.

---

## 3. Prerequisites

```sql
CREATE EXTENSION IF NOT EXISTS citext;    -- case-insensitive email / username
CREATE EXTENSION IF NOT EXISTS pgcrypto;  -- gen_random_uuid()

-- Maintains updated_at on every UPDATE. Attached to all mutable tables.
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Blocks mutation of append-only tables. Attached to auth_events.
CREATE OR REPLACE FUNCTION reject_mutation() RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'Table % is append-only; % is not permitted',
        TG_TABLE_NAME, TG_OP;
END;
$$ LANGUAGE plpgsql;
```

---

## 4. Enumerated types

```sql
CREATE TYPE firm_type          AS ENUM ('SOLE_PROPRIETORSHIP','PARTNERSHIP','LLP','PRIVATE_LIMITED','OTHER');
CREATE TYPE store_status       AS ENUM ('ACTIVE','SUSPENDED');

CREATE TYPE user_status        AS ENUM ('PENDING_VERIFICATION','ACTIVE','SUSPENDED','DEACTIVATED');
CREATE TYPE sla_category       AS ENUM ('Fellow','Associate','Licentiate','Trainee');
CREATE TYPE role_scope         AS ENUM ('SURVEYOR','REVIEWER','ADMIN','INSURER_VIEWER');
CREATE TYPE signup_source      AS ENUM ('SELF_SIGNUP','INVITE');
CREATE TYPE logout_reason      AS ENUM ('USER_INITIATED','TOKEN_EXPIRED','REVOKED_BY_ADMIN',
                                        'OFFLINE_GRACE_EXPIRED','PASSWORD_CHANGED','DEVICE_WIPE',
                                        'ALL_SESSIONS_REVOKED');

CREATE TYPE device_platform    AS ENUM ('IOS','ANDROID','WEB');
CREATE TYPE session_status     AS ENUM ('ACTIVE','LOGGED_OUT','EXPIRED','REVOKED','SUPERSEDED');

CREATE TYPE auth_outcome       AS ENUM ('SUCCESS','FAILURE');
CREATE TYPE auth_method        AS ENUM ('PASSWORD','PHONE_OTP','EMAIL_OTP','REFRESH_TOKEN','OFFLINE_TOKEN');
CREATE TYPE auth_event_type    AS ENUM (
    'SIGNUP','LOGIN_SUCCESS','LOGIN_FAILED',
    'OTP_REQUESTED','OTP_VERIFIED','OTP_FAILED',
    'TOKEN_REFRESHED','TOKEN_REUSE_DETECTED',
    'LOGOUT','LOGOUT_ALL','SESSION_REVOKED',
    'PASSWORD_CHANGED','PASSWORD_RESET_REQUESTED','PASSWORD_RESET_COMPLETED',
    'ACCOUNT_LOCKED','ACCOUNT_UNLOCKED',
    'ROLE_GRANTED','ROLE_REVOKED',
    'INVITE_SENT','INVITE_ACCEPTED',
    'OFFLINE_UNLOCK','OFFLINE_GRACE_EXPIRED');

CREATE TYPE invite_status      AS ENUM ('PENDING','ACCEPTED','EXPIRED','REVOKED');
CREATE TYPE otp_channel        AS ENUM ('SMS','EMAIL');
CREATE TYPE otp_purpose        AS ENUM ('LOGIN','SIGNUP_VERIFY','PASSWORD_RESET');
CREATE TYPE grant_scope        AS ENUM ('READ_ONLY');
```

---

## 5. `stores` — the surveyor firm (renames `tenants`, SRS entity 12)

```sql
CREATE TABLE stores (
    id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firm_name                 VARCHAR(200) NOT NULL,
    legal_name                VARCHAR(200),
    firm_type                 firm_type    NOT NULL DEFAULT 'SOLE_PROPRIETORSHIP',

    -- Founding ADMIN. Nullable ONLY to break the stores <-> users circular FK on
    -- first insert; set within the same registration transaction. See §5.1.
    owner_user_id             UUID,

    status                    store_status NOT NULL DEFAULT 'ACTIVE',

    -- Report identity (consumed by sprint_0013 FSR letterhead + sign-off block)
    letterhead_config_json    JSONB        NOT NULL DEFAULT '{}'::jsonb,
    default_claim_ref_prefix  VARCHAR(8)   NOT NULL DEFAULT 'SS',

    primary_contact_email     CITEXT,
    primary_contact_phone     VARCHAR(16),
    registered_address        TEXT,

    created_at                TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at                TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    deleted_at                TIMESTAMPTZ,

    CONSTRAINT stores_prefix_format CHECK (default_claim_ref_prefix ~ '^[A-Z]{2,8}$')
);

CREATE INDEX idx_stores_owner  ON stores (owner_user_id);
CREATE INDEX idx_stores_status ON stores (status) WHERE deleted_at IS NULL;

CREATE TRIGGER trg_stores_updated_at
    BEFORE UPDATE ON stores FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

**`firm_name` is deliberately NOT unique.** Two unrelated firms may legitimately share a name, and ADR-0005 decision 3 removes firm-name matching from the join path entirely — a user joins an existing store only via an invite token, never by typing a matching name. A unique constraint here would let one firm block another's registration.

### 5.1 Resolving the circular foreign key

`stores.owner_user_id → users.id` and `users.store_id → stores.id` are mutually dependent. The FK from `stores` is added **after** `users` exists and is declared `DEFERRABLE INITIALLY DEFERRED`, so registration completes in one transaction:

```sql
ALTER TABLE stores
    ADD CONSTRAINT fk_stores_owner_user
    FOREIGN KEY (owner_user_id) REFERENCES users(id)
    DEFERRABLE INITIALLY DEFERRED;
```

Registration order inside the transaction: `INSERT stores` (owner NULL) → `INSERT users` → `UPDATE stores SET owner_user_id` → `INSERT user_roles` (ADMIN) → `INSERT sessions` → `INSERT auth_events`.

---

## 6. `users` — the employee / client (SRS entity 11, extended)

`users.id` **is** the `client_id` referenced by every other table.

```sql
CREATE TABLE users (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id               UUID NOT NULL REFERENCES stores(id),

    ---- Identity ---------------------------------------------------------
    full_name              VARCHAR(150) NOT NULL,
    email                  CITEXT       NOT NULL,
    mobile                 VARCHAR(16)  NOT NULL,      -- E.164, e.g. +919876543210
    username               CITEXT,                     -- nullable; see §6.2

    ---- Credentials ------------------------------------------------------
    password_hash          TEXT,                       -- nullable: OTP-only accounts
    password_algo          VARCHAR(32)  NOT NULL DEFAULT 'argon2id',
    password_updated_at    TIMESTAMPTZ,

    ---- Professional (SRS FR-0.2, D35) -----------------------------------
    sla_license_no         VARCHAR(32),
    sla_category           sla_category,
    base_location          VARCHAR(120),
    signature_uri          TEXT,

    ---- RBAC -------------------------------------------------------------
    -- Denormalised primary role, retained for SRS §5.1 compatibility and
    -- cheap display. `user_roles` is authoritative for authorization.
    access_role_scope      role_scope   NOT NULL DEFAULT 'SURVEYOR',
    -- Bumped on any role/permission change; mirrored in the JWT `pv` claim so
    -- a stale access token is rejected within one 15-minute lifetime.
    permissions_version    INTEGER      NOT NULL DEFAULT 1,

    ---- Lifecycle & verification -----------------------------------------
    status                 user_status  NOT NULL DEFAULT 'ACTIVE',
    email_verified_at      TIMESTAMPTZ,
    mobile_verified_at     TIMESTAMPTZ,
    terms_accepted_at      TIMESTAMPTZ  NOT NULL,
    terms_version          VARCHAR(16)  NOT NULL,

    ---- Signup provenance ------------------------------------------------
    signup_source          signup_source NOT NULL DEFAULT 'SELF_SIGNUP',
    invited_by_user_id     UUID REFERENCES users(id),
    invite_id              UUID,                       -- FK added after store_invites
    signup_ip              INET,
    signup_user_agent      TEXT,
    signup_device_id       VARCHAR(128),
    signup_platform        device_platform,
    signup_app_version     VARCHAR(32),
    signup_country_code    CHAR(2),
    signup_region          VARCHAR(120),
    signup_city            VARCHAR(120),
    signup_asn             INTEGER,
    signup_isp             VARCHAR(160),
    signup_timezone        VARCHAR(64),

    ---- Login state ------------------------------------------------------
    last_login_at          TIMESTAMPTZ,
    last_login_ip          INET,
    last_login_user_agent  TEXT,
    last_login_device_id   VARCHAR(128),
    previous_login_at      TIMESTAMPTZ,   -- powers "your last sign-in was…"
    previous_login_ip      INET,
    last_seen_at           TIMESTAMPTZ,
    login_count            BIGINT       NOT NULL DEFAULT 0,

    ---- Logout & lockout -------------------------------------------------
    last_logout_at         TIMESTAMPTZ,
    last_logout_reason     logout_reason,
    failed_login_count     INTEGER      NOT NULL DEFAULT 0,
    last_failed_login_at   TIMESTAMPTZ,
    locked_until           TIMESTAMPTZ,

    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    deleted_at             TIMESTAMPTZ,

    ---- Field-level validation (mirrors 00_auth_signup.md §4) -------------
    CONSTRAINT users_full_name_len  CHECK (char_length(full_name) >= 3),
    CONSTRAINT users_email_format   CHECK (email ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'),
    CONSTRAINT users_mobile_format  CHECK (mobile ~ '^\+[1-9][0-9]{7,14}$'),
    CONSTRAINT users_username_format
        CHECK (username IS NULL OR username ~ '^[A-Za-z0-9._-]{3,40}$'),
    -- Loose sanity bound only; the SLA-[0-9]{4,8} regex is enforced in the
    -- application validation layer, not here. See §6.5.
    CONSTRAINT users_license_format
        CHECK (sla_license_no IS NULL OR sla_license_no ~ '^[A-Za-z0-9-]{4,32}$'),
    CONSTRAINT users_country_format
        CHECK (signup_country_code IS NULL OR signup_country_code ~ '^[A-Z]{2}$')
);
```

### 6.1 Indexes and uniqueness

```sql
-- Universal-identifier resolution (AC 0.1.1). Uniqueness is GLOBAL, not per-store:
-- see §6.3. Partial so a soft-deleted user releases the identifier.
CREATE UNIQUE INDEX uq_users_email    ON users (email)    WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX uq_users_mobile   ON users (mobile)   WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX uq_users_username ON users (username) WHERE deleted_at IS NULL AND username IS NOT NULL;

CREATE INDEX idx_users_store        ON users (store_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_status       ON users (store_id, status) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_last_login   ON users (last_login_at DESC NULLS LAST);
CREATE INDEX idx_users_locked       ON users (locked_until) WHERE locked_until IS NOT NULL;
CREATE INDEX idx_users_invited_by   ON users (invited_by_user_id);

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

### 6.2 `username` is nullable — an acknowledged specification gap

`00_auth_login.md` §4 accepts an alphanumeric username as a `login_identifier`, but **no signup step captures one** — it is absent from the `00_auth_signup.md` §4 field table.

Resolved here as: `username` is `NULL` at registration and settable later from the Profile screen. Identifier resolution must therefore tolerate a NULL username without matching it. The alternative — adding an optional username input to signup Step 2 — changes a screen spec and is flagged for owner decision in §14.

### 6.3 Why identifier uniqueness is global, not per-store

Login accepts a bare identifier with no store context (`00_auth_login.md` §4; `sprint_0003` task 2 requires resolution to *a single user*). If `email` were unique only within a store, `surveyor@firm.com` could exist in two stores and the login would be ambiguous with no way for the user to disambiguate. Global uniqueness is therefore a functional requirement of the universal-identifier design, not a preference.

Consequence: one human = one account. A surveyor who genuinely works for two firms needs a second identifier, or the future multi-store membership model noted in §14.

### 6.4 The FSR license gate (D35) is enforced in the application, not the schema

`sla_license_no` and `sla_category` are nullable because FR-0.2 makes them optional at signup. The rule that FSR generation is blocked until both are present is a **Stage 14 service-layer check** (`sprint_0013` task 4), deliberately not a DB constraint — a NOT NULL here would break registration.

### 6.5 The license regex lives in the application layer — and the specs disagree on it

Two documents state different rules for `sla_license_no`:

- `Requirement.MD` FR-0.2 and `User Stories.md` AC 0.2.2: regex **`SLA-[0-9]{4,8}`**.
- `00_auth_signup.md` §4 field table: *"Format: `SLA-[0-9]{4,8}` **or alphanumeric**"* — materially looser.

The DB constraint is therefore only a loose sanity bound (`^[A-Za-z0-9-]{4,32}$`), with the AC 0.2.2 regex enforced in application validation where it can be changed without a migration. Hard-coding the strict regex as a `CHECK` would mean that if a legitimate Indian SLA licence format falls outside it, existing rows become unmodifiable and registration silently fails for real surveyors — a regulatory-facing field is the wrong place for an irreversible guess.

**Flagged for owner decision:** which of the two spec statements is authoritative. The application enforces AC 0.2.2 (the strict regex) until told otherwise, since the SRS outranks a screen spec.

---

## 7. RBAC

### 7.1 `permissions` — code-defined catalogue

```sql
CREATE TABLE permissions (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code          VARCHAR(96) NOT NULL UNIQUE,   -- 'claim:read'
    resource      VARCHAR(48) NOT NULL,          -- 'claim'
    action        VARCHAR(48) NOT NULL,          -- 'read'
    description   TEXT        NOT NULL,
    is_assignable BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT permissions_code_shape CHECK (code = resource || ':' || action)
);
```

This table is **seeded from a versioned Go constant and never written at runtime.** Stores may compose custom roles, but may not invent permissions — a store-authored permission would name a capability no handler enforces, which is worse than useless.

### 7.2 `roles` — system + per-store custom

```sql
CREATE TABLE roles (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id    UUID REFERENCES stores(id),   -- NULL => immutable system role
    code        VARCHAR(64)  NOT NULL,
    name        VARCHAR(120) NOT NULL,
    description TEXT,
    is_system   BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ,

    CONSTRAINT roles_system_is_global CHECK (
        (is_system = TRUE  AND store_id IS NULL) OR
        (is_system = FALSE AND store_id IS NOT NULL))
);

-- A system role code is globally unique; a custom role code is unique per store.
CREATE UNIQUE INDEX uq_roles_system ON roles (code)
    WHERE store_id IS NULL AND deleted_at IS NULL;
CREATE UNIQUE INDEX uq_roles_store  ON roles (store_id, code)
    WHERE store_id IS NOT NULL AND deleted_at IS NULL;

CREATE TRIGGER trg_roles_updated_at
    BEFORE UPDATE ON roles FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

The `roles_system_is_global` check makes the two states structurally exclusive: a system role is always global and a store role is never marked system, so no store can shadow or mutate a seeded role.

### 7.3 `role_permissions`

```sql
CREATE TABLE role_permissions (
    role_id       UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE RESTRICT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (role_id, permission_id)
);
CREATE INDEX idx_role_permissions_permission ON role_permissions (permission_id);
```

### 7.4 `user_roles` — multi-role assignment

```sql
CREATE TABLE user_roles (
    user_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id            UUID NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
    store_id           UUID NOT NULL REFERENCES stores(id),
    granted_by_user_id UUID REFERENCES users(id),
    granted_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at         TIMESTAMPTZ,
    revoked_at         TIMESTAMPTZ,
    revoke_reason      TEXT,
    PRIMARY KEY (user_id, role_id)
);

CREATE INDEX idx_user_roles_active ON user_roles (user_id)
    WHERE revoked_at IS NULL;
CREATE INDEX idx_user_roles_role   ON user_roles (role_id);
CREATE INDEX idx_user_roles_store  ON user_roles (store_id);
```

`store_id` is denormalised onto the assignment so an authorization query never needs to join `users` to establish store scope. The application must assert `user_roles.store_id = users.store_id`, and that a store-scoped role's `roles.store_id` matches too — a cross-store role grant is a privilege-escalation path.

A role is effective when `revoked_at IS NULL AND (expires_at IS NULL OR expires_at > NOW())`.

### 7.5 `claim_access_grants` — per-claim insurer scoping

`Requirement.MD` §5.1 rule 2 requires insurer access be "strictly scoped to individual assigned claims, never broad firm-wide access". A role alone cannot express that, so the grant is a first-class row.

```sql
CREATE TABLE claim_access_grants (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id           UUID NOT NULL REFERENCES stores(id),
    claim_id           UUID NOT NULL,               -- FK added with the claims table
    grantee_user_id    UUID NOT NULL REFERENCES users(id),
    granted_by_user_id UUID NOT NULL REFERENCES users(id),
    scope              grant_scope NOT NULL DEFAULT 'READ_ONLY',
    granted_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at         TIMESTAMPTZ,
    revoked_at         TIMESTAMPTZ,
    revoked_by_user_id UUID REFERENCES users(id),
    revoke_reason      TEXT,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX uq_claim_grant_active
    ON claim_access_grants (claim_id, grantee_user_id) WHERE revoked_at IS NULL;
CREATE INDEX idx_claim_grants_grantee ON claim_access_grants (grantee_user_id)
    WHERE revoked_at IS NULL;

CREATE TRIGGER trg_claim_grants_updated_at
    BEFORE UPDATE ON claim_access_grants FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

Holding `insurer:claim:read` is necessary but **not sufficient**: the handler must also find a live grant for that specific claim. Every read performed under a grant writes an `audit_log` row (`Requirement.MD` §5.1 rule 3).

### 7.6 Seeded permission catalogue

| Group | Codes |
| :-- | :-- |
| Store | `store:read`, `store:update`, `store:branding:update` |
| User | `user:read`, `user:invite`, `user:update`, `user:deactivate`, `user:role:assign` |
| Role | `role:read`, `role:create`, `role:update`, `role:delete` |
| Claim | `claim:create`, `claim:read`, `claim:update`, `claim:delete`, `claim:assign`, `claim:stage:advance` |
| Evidence | `evidence:capture`, `evidence:read`, `evidence:delete` |
| Document | `document:upload`, `document:read`, `document:verify` |
| Assessment | `assessment:read`, `assessment:write`, `assessment:approve` |
| Salvage | `salvage:read`, `salvage:write` |
| Coverage | `coverage-opinion:read`, `coverage-opinion:write` |
| Report | `report:psr:generate`, `report:fsr:generate`, `report:export`, `report:submit` |
| Audit | `audit:read` |
| AI | `ai:invoke` |
| Insurer | `insurer:claim:read` |

### 7.7 Seeded system roles

| Role | Permissions |
| :-- | :-- |
| `SURVEYOR` | all `claim:*`, `evidence:*`, `document:*`, `assessment:read|write`, `salvage:*`, `coverage-opinion:*`, `report:*` (incl. `submit`), `ai:invoke`, `audit:read`, `store:read`, `user:read` |
| `REVIEWER` | `claim:read`, `evidence:read`, `document:read`, `assessment:read`, `assessment:approve`, `salvage:read`, `coverage-opinion:read`, `report:psr:generate`, `report:fsr:generate`, `report:export`, `audit:read`, `store:read`, `user:read` |
| `ADMIN` | everything in `SURVEYOR`, plus `store:update`, `store:branding:update`, all `user:*`, all `role:*` |
| `INSURER_VIEWER` | `insurer:claim:read` only — and only where a live `claim_access_grants` row exists |

> **MVP enforcement boundary.** Per `User Stories.md` AC 16.2.2, role scopes are stored as valid metadata "without restricting MVP UI actions". The tables, middleware and store-isolation checks all ship in MVP; per-permission **UI gating** is switched on post-MVP. Store isolation is *not* deferred — it is enforced from the first endpoint.

---

## 8. `sessions` (SRS entity 13, extended)

```sql
CREATE TABLE sessions (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                 UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    store_id                UUID NOT NULL REFERENCES stores(id),

    ---- Device ------------------------------------------------------------
    device_id               VARCHAR(128) NOT NULL,
    device_name             VARCHAR(120),
    device_platform         device_platform NOT NULL,
    app_version             VARCHAR(32),
    os_version              VARCHAR(32),

    ---- Refresh token (ADR-0003 §1) ---------------------------------------
    -- Argon2id hash of the opaque 64-byte refresh token. NEVER the token itself.
    refresh_token_hash      TEXT NOT NULL,
    -- Rotation lineage: all descendants of one login share a family id.
    refresh_token_family_id UUID NOT NULL,
    rotated_from_session_id UUID REFERENCES sessions(id),

    ---- Lifecycle ---------------------------------------------------------
    issued_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at              TIMESTAMPTZ NOT NULL,          -- issued_at + 30 days
    last_used_at            TIMESTAMPTZ,
    last_refreshed_at       TIMESTAMPTZ,
    offline_grace_until     TIMESTAMPTZ NOT NULL,          -- ADR-0003 §3.2
    remember_device         BOOLEAN     NOT NULL DEFAULT TRUE,

    ---- Origin telemetry --------------------------------------------------
    created_ip              INET,
    created_user_agent      TEXT,
    created_country_code    CHAR(2),
    created_region          VARCHAR(120),
    created_city            VARCHAR(120),
    last_ip                 INET,

    ---- Termination -------------------------------------------------------
    status                  session_status NOT NULL DEFAULT 'ACTIVE',
    logout_at               TIMESTAMPTZ,
    revoked_at              TIMESTAMPTZ,
    revoked_by_user_id      UUID REFERENCES users(id),
    revoke_reason           logout_reason,

    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT sessions_expiry_after_issue CHECK (expires_at > issued_at),
    -- A terminated session must say when. EXPIRED is excluded because expiry is
    -- a function of wall-clock time: PostgreSQL rejects CHECK constraints
    -- containing non-immutable functions such as NOW().
    CONSTRAINT sessions_terminal_has_timestamp CHECK (
        status IN ('ACTIVE','EXPIRED')
        OR logout_at IS NOT NULL
        OR revoked_at IS NOT NULL)
);

-- One live session per device per user; history is retained.
CREATE UNIQUE INDEX uq_sessions_active_device
    ON sessions (user_id, device_id) WHERE status = 'ACTIVE';
CREATE UNIQUE INDEX uq_sessions_refresh_hash ON sessions (refresh_token_hash);
CREATE INDEX idx_sessions_family  ON sessions (refresh_token_family_id);
CREATE INDEX idx_sessions_user    ON sessions (user_id, status);
CREATE INDEX idx_sessions_expiry  ON sessions (expires_at) WHERE status = 'ACTIVE';

CREATE TRIGGER trg_sessions_updated_at
    BEFORE UPDATE ON sessions FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

**Reconciliation — `encrypted_token_ref` is renamed to `refresh_token_hash`.** SRS §5.2 entity 13 named this column `encrypted_token_ref`, but ADR-0003 §1 requires the refresh token be *hashed with Argon2id*, not encrypted. Encryption is reversible and would let a database compromise yield live refresh tokens. ADR-0003 governs; the column name now states what the column holds.

**Multi-device is supported** (resolves `sprint_0002` Q12). One `ACTIVE` session per `(user_id, device_id)`; a surveyor may hold concurrent sessions on a phone and a tablet. Because `sync_queue` is already keyed by `device_id`, the sync design absorbs this without change.

**Rotation and reuse detection.** Every refresh issues a new session row carrying the same `refresh_token_family_id` and sets the predecessor to `SUPERSEDED`. Presenting a refresh token whose row is already `SUPERSEDED` means the token leaked: the server revokes **every** session in that family, writes `TOKEN_REUSE_DETECTED`, and forces re-authentication.

**Field-name note.** `remember_device` matches the `RememberDeviceCheckbox` UI label; the login request field stays `remember_me` per `00_auth_login.md` §4. The API contract maps one to the other — both names are intentional and documented.

---

## 9. `user_devices`

Stable device identity across many sessions, and the anchor for administrative revoke and future push delivery.

```sql
CREATE TABLE user_devices (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    store_id      UUID NOT NULL REFERENCES stores(id),
    device_id     VARCHAR(128) NOT NULL,
    device_name   VARCHAR(120),
    platform      device_platform NOT NULL,
    model         VARCHAR(120),
    os_version    VARCHAR(32),
    app_version   VARCHAR(32),
    push_token    TEXT,
    is_trusted    BOOLEAN     NOT NULL DEFAULT FALSE,
    first_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_seen_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    revoked_at    TIMESTAMPTZ,
    revoke_reason logout_reason,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX uq_user_devices ON user_devices (user_id, device_id);
CREATE INDEX idx_user_devices_store ON user_devices (store_id);

CREATE TRIGGER trg_user_devices_updated_at
    BEFORE UPDATE ON user_devices FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

Revoking a device cascades in the service layer to revoking its `ACTIVE` sessions. `device_id` is an app-generated install identifier persisted in secure storage — deliberately not a hardware serial, which is restricted on both platforms and would be a privacy liability.

---

## 10. `auth_events` — append-only security telemetry

```sql
CREATE TABLE auth_events (
    id                        BIGSERIAL PRIMARY KEY,   -- internal sequence, ADR-0004 §4
    store_id                  UUID REFERENCES stores(id),
    user_id                   UUID REFERENCES users(id),
    session_id                UUID REFERENCES sessions(id),

    event_type                auth_event_type NOT NULL,
    outcome                   auth_outcome    NOT NULL,
    auth_method               auth_method,
    failure_reason            VARCHAR(120),

    -- SHA-256 of the submitted identifier. A failed login may name a
    -- non-existent account; storing it raw would build an unauthenticated
    -- log of third-party emails and phone numbers.
    identifier_attempted_hash CHAR(64),

    ip_address                INET,
    user_agent                TEXT,
    device_id                 VARCHAR(128),
    device_platform           device_platform,
    app_version               VARCHAR(32),

    country_code              CHAR(2),
    region                    VARCHAR(120),
    city                      VARCHAR(120),
    asn                       INTEGER,
    isp                       VARCHAR(160),
    timezone                  VARCHAR(64),

    occurred_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT auth_events_failure_has_reason
        CHECK (outcome = 'SUCCESS' OR failure_reason IS NOT NULL)
);

CREATE INDEX idx_auth_events_user    ON auth_events (user_id, occurred_at DESC);
CREATE INDEX idx_auth_events_store   ON auth_events (store_id, occurred_at DESC);
CREATE INDEX idx_auth_events_ip      ON auth_events (ip_address, occurred_at DESC);
CREATE INDEX idx_auth_events_type    ON auth_events (event_type, occurred_at DESC);
CREATE INDEX idx_auth_events_failed  ON auth_events (identifier_attempted_hash, occurred_at DESC)
    WHERE outcome = 'FAILURE';

-- Append-only enforcement (sprint_0004 AC).
CREATE TRIGGER trg_auth_events_immutable
    BEFORE UPDATE OR DELETE ON auth_events
    FOR EACH ROW EXECUTE FUNCTION reject_mutation();
```

Plus a grant-level backstop, so immutability does not rest on a trigger alone:

```sql
REVOKE UPDATE, DELETE, TRUNCATE ON auth_events FROM survscribe_app;
GRANT  INSERT, SELECT              ON auth_events TO   survscribe_app;
```

`store_id` and `user_id` are nullable because a failed login against an unknown identifier resolves to neither — and that is precisely the event worth recording.

### 10.1 Why this is separate from `audit_log`

`audit_log` (SRS entity 14) is field-level business-data change tracking — `entity`, `field`, `old_value`, `new_value` — mandated by §6.2 for loss-assessment figures and insurer file access. `auth_events` has a different shape (no old/new value), a different cardinality (failed logins can spike under attack), a different retention need, and a different audience. Merging them would force a lowest-common-denominator schema on both and let an auth flood bury financial-change history. They are cross-referenced by `actor_user_id` / `user_id`, not merged.

### 10.2 Retention

No retention policy exists anywhere in the current documentation. `auth_events` grows unbounded without one — flagged in §14. The table is designed for `RANGE` partitioning on `occurred_at` should volume require it; nothing in the schema needs to change to adopt it.

---

## 11. `store_invites` — the only path into an existing store

```sql
CREATE TABLE store_invites (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id           UUID NOT NULL REFERENCES stores(id),
    email              CITEXT NOT NULL,
    mobile             VARCHAR(16),
    role_id            UUID NOT NULL REFERENCES roles(id),
    invited_by_user_id UUID NOT NULL REFERENCES users(id),

    -- SHA-256 of the single-use token. The raw token exists only in the
    -- invitation email and is never recoverable from the database.
    token_hash         CHAR(64) NOT NULL UNIQUE,

    status             invite_status NOT NULL DEFAULT 'PENDING',
    expires_at         TIMESTAMPTZ NOT NULL,
    accepted_at        TIMESTAMPTZ,
    accepted_user_id   UUID REFERENCES users(id),
    revoked_at         TIMESTAMPTZ,
    revoked_by_user_id UUID REFERENCES users(id),

    created_ip         INET,
    created_user_agent TEXT,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX uq_store_invites_pending
    ON store_invites (store_id, email) WHERE status = 'PENDING';
CREATE INDEX idx_store_invites_store ON store_invites (store_id, status);

CREATE TRIGGER trg_store_invites_updated_at
    BEFORE UPDATE ON store_invites FOR EACH ROW EXECUTE FUNCTION set_updated_at();

ALTER TABLE users
    ADD CONSTRAINT fk_users_invite FOREIGN KEY (invite_id) REFERENCES store_invites(id);
```

**Registration semantics (ADR-0005 decision 3).** `POST /auth/register` **always** creates a new store and makes the registrant its `ADMIN` and `owner_user_id`; a matching `firm_name` is never joined automatically. Adding a colleague requires an ADMIN to issue an invite, which the recipient accepts — landing them in the existing store with the role the invite names. This closes `sprint_0003` Q8 and prevents a stranger joining a firm by guessing its name.

---

## 12. `otp_challenges` and `password_reset_tokens`

Both tables are **defined now and wired later.** `sprint_0003` §5 defers OTP login (blocked on Twilio India DLT registration, risk R4) and password reset (blocked on the email vendor). Defining them inside the frozen schema avoids a second migration when those sprints land.

```sql
CREATE TABLE otp_challenges (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID REFERENCES users(id) ON DELETE CASCADE,
    channel             otp_channel NOT NULL,
    purpose             otp_purpose NOT NULL,
    destination_hash    CHAR(64) NOT NULL,   -- SHA-256 of the phone/email
    code_hash           TEXT     NOT NULL,   -- Argon2id; never the plain code
    attempt_count       INTEGER  NOT NULL DEFAULT 0,
    max_attempts        INTEGER  NOT NULL DEFAULT 5,
    -- D33: SMS resend after 30s, email after 45s.
    resend_available_at TIMESTAMPTZ NOT NULL,
    expires_at          TIMESTAMPTZ NOT NULL,
    consumed_at         TIMESTAMPTZ,
    request_ip          INET,
    request_user_agent  TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_otp_lookup ON otp_challenges (destination_hash, purpose, created_at DESC)
    WHERE consumed_at IS NULL;
CREATE INDEX idx_otp_expiry ON otp_challenges (expires_at) WHERE consumed_at IS NULL;

CREATE TABLE password_reset_tokens (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash         CHAR(64) NOT NULL UNIQUE,   -- SHA-256 of the emailed token
    expires_at         TIMESTAMPTZ NOT NULL,
    consumed_at        TIMESTAMPTZ,
    request_ip         INET,
    request_user_agent TEXT,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_password_reset_user ON password_reset_tokens (user_id, created_at DESC);
```

`otp_challenges.user_id` is nullable so an OTP request for an unregistered number is still rate-limitable by `destination_hash`. Neither table stores the plain code or token — only a hash — so a database read cannot be replayed into an account takeover.

---

## 13. Entity relationship summary

```
stores 1 ──< users              (users.store_id)
stores 1 ──1 users              (stores.owner_user_id, deferred FK)
stores 1 ──< roles              (custom roles only; system roles have store_id NULL)
stores 1 ──< store_invites

users  1 ──< sessions      1 ──< auth_events
users  1 ──< user_devices
users  M >──< roles             (via user_roles)
roles  M >──< permissions       (via role_permissions)
users  1 ──< claim_access_grants >── 1 claims
users  1 ──< otp_challenges
users  1 ──< password_reset_tokens
users  1 ──< store_invites      (as inviter, and as acceptor)
```

---

## 14. Open items — flagged, not decided

| # | Item | Why it is not decided here |
| :-- | :-- | :-- |
| 1 | **`users.username` capture** — NULL at signup and set from Profile (assumed here), or add an optional input to signup Step 2? | The alternative changes `00_auth_signup.md` §4, a screen spec. Owner call. |
| 2 | **Keychain/Keystore wipe recovery** (`sprint_0004` Q7) | Forcing online re-auth is the obvious answer, but the local-data-loss warning shown to the surveyor is a UX decision with regulatory weight. |
| 3 | **RS256 signing-key custody and rotation** (`sprint_0001` task 9) | Deserves its own ADR; no schema impact. |
| 4 | **`auth_events` retention period** | No retention policy exists anywhere in the documentation. Unbounded growth without one. |
| 5 | **Multi-store membership** — one human employed by two firms | Out of MVP scope. Would become a `store_memberships` join table; §6.3 documents why global identifier uniqueness forces the question. |
| 6 | **SLA licence format** — `Requirement.MD` FR-0.2 / AC 0.2.2 say `SLA-[0-9]{4,8}`; `00_auth_signup.md` §4 says *"or alphanumeric"* | A pre-existing contradiction, surfaced here rather than silently resolved. The SRS is treated as authoritative pending your call. See §6.5. |

---

## 15. Traceability

| Requirement | Satisfied by |
| :-- | :-- |
| CR-A1 universal identifier + Remember Me | `users.email` / `mobile` / `username` global unique indexes §6.1; `sessions.remember_device` |
| CR-A2 Phone/Email OTP, 30 s / 45 s | `otp_challenges.channel`, `.resend_available_at` §12 |
| CR-A3 password recovery | `password_reset_tokens` §12 |
| CR-A5 registration fields | `users.full_name`/`email`/`mobile`, `stores.firm_name` |
| CR-A7 SLA optional at signup, required before FSR | nullable `sla_license_no`/`sla_category` + §6.4 |
| CR-A8 SLA category enum | `sla_category` type §4 |
| CR-A9 ToS consent | `users.terms_accepted_at`, `.terms_version` |
| CR-A10 default `SURVEYOR`, new firm ⇒ new store | `users.access_role_scope` default; §11 registration semantics |
| CR-A12 offline session, 15-min lock | `sessions.offline_grace_until`; idle lock is client-side |
| SRS §5.1 five common columns | §1 naming contract |
| SRS §5.1 insurer per-claim scoping | `claim_access_grants` §7.5 |
| SRS §6.2 immutable audit | `auth_events` §10 + `audit_log` (sprint_0001) |
| ADR-0003 dual token | `sessions.refresh_token_hash`, `.refresh_token_family_id` §8 |
| ADR-0004 schema rules | §2 conventions |
| `sprint_0004` AC "auth events append-only" | §10 trigger + REVOKE |

---
---

# Part B — Claim Workflow Schema

*`Requirement.MD` §5.2 entities 1–10 and 14–20, plus the child tables the 15-stage workflow requires. Produced by `sprint_0001` task 1.*

## 16. Scope, and what is an addition beyond the SRS entity list

`Requirement.MD` §5.2 calls its field lists **indicative** and defers "types, PK/FK, indexes, enum value lists, JSON shapes" to this document. Turning those lists into DDL exposed places where a single SRS entity cannot hold what the stage screens and functional requirements demand. Those cases are handled by adding a child table rather than by widening a JSONB blob, because the affected values are financial or evidentiary and must be individually queryable and individually auditable (`audit_log` records field-level before/after values — §35).

**Every table below that is not in the SRS §5.2 list is marked `[ADDITION]` and repeated in §38.** None of them should be treated as approved until the owner reviews §38.

| SRS entity | Table(s) here | Note |
| :-- | :-- | :-- |
| 1 `claims` | `claims` | Absorbs the full FR-1.2 appointment attribute set. |
| 2 `policy_details` | `policy_details` + **`policy_sections`** `[ADDITION]` | `sum_insured_heads` is `Array<Object>` in `03_policy_coverage_review.md` §4; underinsurance needs per-head SI as a first-class number (§30). |
| 3 `site_visits` | `site_visits` | Absorbs entity 17 — **Q2a**, §17. |
| 4 `cause_investigations` | `cause_investigations` + **`chronology_events`** `[ADDITION]` | `06_cause_investigation.md` §3 specifies a repeating `TimelineCardList`; AC 5.1.3 compares event timestamps pairwise. |
| 5 `damage_items` | `damage_items` | — |
| 6 `media_attachments` | `media_attachments` | Covers photos, video and the FR-6.2 voice notes. |
| 7 `documents` | `documents` + **`document_line_items`** `[ADDITION]` | FR-10.1 OCR line-item extraction; `11_document_verification_audit.md` §4 is a per-line-item audit grid. |
| 8 `assessment_line_items` | `assessment_line_items` + **`assessment_heads`** `[ADDITION]` | VAR and SI are per head (`12_loss_assessment_quantification.md` §2.2, §3.1), not per line. |
| 9 `salvage_records` | `salvage_records` | — |
| 10 `final_survey_reports` | `final_survey_reports` + **`preliminary_survey_reports`** `[ADDITION]` + **`pre_submission_audits`** `[ADDITION]` + **`report_dispatches`** `[ADDITION]` | FR-8.2 makes the PSR a separate deliverable; FR-15.1 is a re-runnable 7-gate audit; FR-15.2 requires a dispatch tracking **log**. |
| 14 `audit_log` | `audit_log` | — |
| 15 `sync_queue` | `sync_queue` | — |
| 16 `contact_logs` | `contact_logs` | — |
| 17 `follow_up_visits` | *folded into* `site_visits` | **Q2a**, §17. |
| 18 `coverage_opinions` | `coverage_opinions` | — |
| 19 `requisition_notices` | `requisition_notices` | — |
| 20 `preservation_notices` | `preservation_notices` | **Q2b**, §17 — kept as its own table. |
| — | **`discrepancy_flags`** `[ADDITION]` | The status codes `LOCATION_DISCREPANCY_DETECTED`, `DUPLICATE_CLAIM_ITEM` and `RATE_INFLATION_DETECTED` are named across FR-4.3, FR-10.2 and AC 10.1.x but have no home entity; FSR Section H and Stage 15 gate 6 both read them. |

---

## 17. Q2 resolution

`sprint_0001` §5 requires Q2 to be answered here. Both parts were put to the project owner on 2026-08-30 and answered.

### 17.1 Q2a — follow-up visits **extend `site_visits`**

**Decision: one `site_visits` table with a `visit_type` enum (`INITIAL` | `FOLLOW_UP`).** Entity 17 `follow_up_visits` is not created.

Reasons:
- The specs already assume one sequence. SRS entity 3 carries `visit_no`, and `10_followup_investigation.md` §4 defines `visit_number` as "Auto-incrementing ≥ 2" — which is only meaningful if visit 1 is the Stage 4 initial visit in the same series.
- `media_attachments` gets one parent column instead of two mutually exclusive nullable FKs. FR-9.2 requires the same watermarked photo pipeline on follow-up visits as Stage 6.
- `UNIQUE (claim_id, visit_no)` enforces the numbering in the database. Split across two tables, continuity would be enforceable only in application code.

Cost, accepted: the Stage 9 columns (`visit_purpose`, `persons_attended`, `detailed_findings`, `stock_reconciliation_json`) are nullable on an `INITIAL` row, and the Stage 4 columns (`gps_*`, `location_discrepancy_flag`, `occupancy_nature`) are nullable on a `FOLLOW_UP` row. Both directions are constrained by `CHECK`, so the nullability is not a licence to write incomplete rows (§23).

### 17.2 Q2b — `preservation_notices` **stays its own table**

**Decision: `preservation_notices` is a distinct table, sibling to `requisition_notices`.** It is not folded into `contact_logs` or `documents`, and it is not merged with `requisition_notices` under a shared `notices` type enum.

Reasons:
- FR-3.3 makes the notice a legal instruction to the insured (preserve debris, do not repair or dispose). Its evidentiary value rests on `template_version` and `dispatched_at`, neither of which a `contact_logs` row models.
- `04_insured_contact_schedule.md` §4 already tracks `preservation_notice_sent` as a field separate from `contact_log_notes` — the screen treats them as two things.
- Merging with `requisition_notices` would make `required_docs_json` and `due_date` (FR-8.1, requisition-only) and `custom_instructions` (FR-3.3, preservation-only) mutually nullable in one table for no gain: the two are dispatched at different stages, satisfy different requirements, and have different lifecycles.

The rendered `.docx` of either notice is stored as a `documents` row and linked back by `documents.source_notice_id`, so the file itself lives in one place.

---

## 18. Conventions specific to Part B

Part A §2 applies unchanged. In addition:

**Numeric types.** All rupee amounts are `NUMERIC(15,2)` — never `FLOAT`. `CLAUDE.md` §14 constraint 5 requires Section F to reconcile "to the rupee", and binary floating point cannot guarantee that. Percentages are `NUMERIC(5,2)`, quantities `NUMERIC(14,3)`, GPS coordinates `NUMERIC(9,6)`.

**The five common columns.** Every table in Part B is an operational table and carries all five (`store_id`, `client_id`, `assigned_surveyor_id`, `reviewer_id`, `access_role_scope`) per SRS §5.1 as amended by ADR-0005 D38 and `CLAUDE.md` §14 constraint 11. On child tables (`policy_sections`, `chronology_events`, `document_line_items`, `assessment_line_items`, …) they are denormalized from the owning `claims` row and written by the application. This is deliberate redundancy: it lets **every** repository method filter on `store_id` as its first scope argument without a join, which is what `identity-and-rbac.md` §3.2 requires.

The five columns are identical everywhere:

```sql
    store_id             UUID       NOT NULL REFERENCES stores(id),
    client_id            UUID       NOT NULL REFERENCES users(id),
    assigned_surveyor_id UUID       REFERENCES users(id),
    reviewer_id          UUID       REFERENCES users(id),
    access_role_scope    role_scope NOT NULL DEFAULT 'SURVEYOR',
```

Each table's DDL below expands them in full rather than referring back here, so that every block is directly usable by `sprint_0001` task 2.

**Soft deletes are broader than ADR-0004 §4.** ADR-0004 mandates `deleted_at` on claims and documents. Part B applies it to **every synced workflow table**. Reason: SRS §2.2 requires bi-directional sync, and a hard `DELETE` on one device is invisible to the server pull — the row simply reappears on the next push. A tombstone is the only way a deletion propagates. Evidence tables (`media_attachments`, `documents`) additionally must never lose rows outright, per `CLAUDE.md` §14 constraints 9 and 10. Append-only tables (`audit_log`) carry no `deleted_at`, per Part A §2.

**Sync columns.** Every synced table carries three columns:

```sql
    client_updated_at    TIMESTAMPTZ,                          -- device wall-clock at last local edit
    field_updated_at     JSONB NOT NULL DEFAULT '{}'::jsonb,   -- { "column_name": "ISO-8601 timestamp" }
    sync_revision        BIGINT NOT NULL DEFAULT 0,            -- server-assigned, monotonic per row
```

`field_updated_at` is what makes AC 16.1.3 field-level timestamp merging possible instead of last-write-wins (`CLAUDE.md` §14 constraint 8). **These three columns are provisional.** `sprint_0002` is the sync spike and owns the merge algorithm; if it settles on a different representation these change. Flagged in §38.

**Client-generated primary keys.** Rows are created offline, so `id` is a UUIDv4 generated on the device and adopted verbatim by the server. `DEFAULT gen_random_uuid()` exists for server-side creation only; it is never relied on for a synced insert. `TEMP-SS-XXXX` (FR-1.3) is a *display* reference held in `claims.temp_ref_no`, not a key.

**Enum casing.** Part A set the precedent with `sla_category` (`'Fellow'`, `'Associate'`, …). The rule, stated explicitly: an enum whose value strings are **quoted verbatim in a spec because they are rendered into a report or the UI** keeps that exact casing; every other enum is `UPPER_SNAKE`. This is why `insurable_interest_status`, `surveyor_recommendation`, `peril_admissibility` and `warranty_compliance_status` are Title Case while `claim_status` and `disposal_mode` are not.

---

## 19. Enumerated types (workflow)

Every value list below is traced to the spec line that fixes it. Where a spec says "etc." the list is closed here and the closure is flagged in §38.

```sql
---- Claim lifecycle ---------------------------------------------------------
-- 01_dashboard.md §6 (STATUS_DRAFT_OFFLINE), FR-1.3, 16_internal_review_submission.md §7
CREATE TYPE claim_status        AS ENUM ('DRAFT_OFFLINE','ACTIVE','ON_HOLD',
                                         'COMPLETED_SUBMITTED','CANCELLED');

---- Peril master (FR-2.1 policy classes, FR-1.2 reported nature of loss,
---- 06_cause_investigation.md §3 ReportedCauseSelect) -----------------------
CREATE TYPE peril_type          AS ENUM ('FIRE','LIGHTNING','EXPLOSION_IMPLOSION',
                                         'FLOOD_INUNDATION','STORM_CYCLONE','EARTHQUAKE',
                                         'BURGLARY_THEFT','RIOT_STRIKE_MALICIOUS_DAMAGE',
                                         'IMPACT_DAMAGE','MACHINERY_BREAKDOWN',
                                         'ELECTRONIC_EQUIPMENT_FAILURE','BURST_PIPE',
                                         'SPONTANEOUS_COMBUSTION','SHORT_CIRCUIT',
                                         'MARINE_TRANSIT','OTHER');

-- FR-2.1 policy type list
CREATE TYPE policy_type         AS ENUM ('STANDARD_FIRE_SPECIAL_PERILS','INDUSTRIAL_ALL_RISKS',
                                         'BURGLARY','MACHINERY_BREAKDOWN','ELECTRONIC_EQUIPMENT',
                                         'MARINE_CARGO','OTHER');

---- Asset heads ------------------------------------------------------------
-- FR-11.1 five heads. Also used by damage_items so Stage 6 maps 1:1 to Stage 11
-- (Stage 15 gate 6 cross-checks the two). See §38 item 4 re FR-6.1 "Electrical".
CREATE TYPE head_category       AS ENUM ('BUILDING_CIVIL','PLANT_MACHINERY',
                                         'FURNITURE_FIXTURES_FITTINGS','STOCKS',
                                         'OTHER_INSURED_PROPERTY');

-- FR-2.1 section-wise sums insured (finer than head_category; rolls up to it)
CREATE TYPE policy_section_head AS ENUM ('BUILDING','PLANT_MACHINERY','FURNITURE_FIXTURES',
                                         'RAW_MATERIALS','WORK_IN_PROGRESS','FINISHED_GOODS',
                                         'STOCK_IN_OPEN','OTHER');

---- Stage 3 ----------------------------------------------------------------
-- FR-3.1 contact attempt logs; SRS entity 16 outcome enum
CREATE TYPE contact_outcome     AS ENUM ('CONNECTED','NO_ANSWER','BUSY','UNREACHABLE',
                                         'WRONG_NUMBER','SITE_VISIT_CONFIRMED',
                                         'RESCHEDULE_REQUESTED','REFUSED');

-- FR-3.3 / FR-8.1 dispatch media; 16_internal_review_submission.md §4 submission_channel
CREATE TYPE dispatch_channel    AS ENUM ('WHATSAPP','EMAIL','SMS','PHONE','IN_PERSON',
                                         'COURIER','INSURER_PORTAL');
CREATE TYPE dispatch_status     AS ENUM ('PENDING','QUEUED','SENT','DELIVERED','FAILED');

---- Stage 4 / Stage 9 ------------------------------------------------------
CREATE TYPE visit_type          AS ENUM ('INITIAL','FOLLOW_UP');   -- Q2a, §17.1
-- FR-9.1 examples: dismantling, post-repair verification, salvage lifting
CREATE TYPE visit_purpose       AS ENUM ('INITIAL_SURVEY','DISMANTLING_INTERNAL_INSPECTION',
                                         'POST_REPAIR_VERIFICATION','SALVAGE_LIFTING',
                                         'STOCK_RECONCILIATION','JOINT_SURVEY',
                                         'DOCUMENT_COLLECTION','OTHER');

---- Stage 5 ----------------------------------------------------------------
-- 06_cause_investigation.md §3 EventTypeSelect — six values, verbatim
CREATE TYPE chronology_event_type AS ENUM ('PRE_INCIDENT_ACTIVITY','LOSS_OCCURRENCE',
                                           'LOSS_DISCOVERY','EMERGENCY_RESPONSE',
                                           'EXTINGUISHMENT_CONTAINMENT','POST_LOSS_ACTION');

---- Stage 6 ----------------------------------------------------------------
-- 07_damage_inspection_studio.md §4 damage_severity
CREATE TYPE damage_severity     AS ENUM ('TOTAL_LOSS','SEVERE','MODERATE','MINOR');
-- 07_damage_inspection_studio.md §4 recommendation
CREATE TYPE damage_recommendation AS ENUM ('REPAIRABLE','REPLACE','SALVAGE');
-- 07_damage_inspection_studio.md §4 "Nos, Kgs, Ltrs, Meters, SqFt, etc." — closed here
CREATE TYPE uom                 AS ENUM ('NOS','KGS','MT','LTRS','METERS','SQFT','SQM',
                                         'SETS','PAIRS','ROLLS','BAGS','LOT');

CREATE TYPE media_type          AS ENUM ('PHOTO','VIDEO','AUDIO');
-- FR-6.2 six mandatory categories, in spec order
CREATE TYPE photo_category      AS ENUM ('PANORAMIC_SITE_VIEW','AFFECTED_SECTION',
                                         'DAMAGED_ASSET','SERIAL_NAMEPLATE',
                                         'CLOSEUP_DAMAGE_DETAIL','ORIGIN_POINT');

---- Stage 7 / Stage 10 -----------------------------------------------------
-- FR-7.1, FR-10.1, FR-5.2 statutory evidence, plus generated notices
CREATE TYPE document_type       AS ENUM (
    'APPOINTMENT_LETTER','POLICY_SCHEDULE','CLAIM_INTIMATION',
    'PURCHASE_INVOICE','BILL_OF_ENTRY','DELIVERY_CHALLAN',
    'FIXED_ASSET_REGISTER','STOCK_LEDGER','STOCK_STATEMENT','PRODUCTION_LOG',
    'GST_RETURN','AUDITED_BALANCE_SHEET','HYPOTHECATION_LEASE_MORTGAGE',
    'FIR_POLICE_DIARY','FIRE_BRIGADE_REPORT','WEATHER_IMD_REPORT',
    'FACTORY_LOGBOOK','CCTV_NOTE','WITNESS_STATEMENT','FORENSIC_ENGINEER_REPORT',
    'CLAIM_BILL','REPAIR_ESTIMATE','OEM_QUOTATION','SALVAGE_OFFER',
    'SALVAGE_SALE_INVOICE','PAYMENT_PROOF',
    'PRESERVATION_NOTICE','REQUISITION_NOTICE','PSR_DOCX','FSR_DOCX',
    'SURVEYOR_SIGNATURE','OTHER');

CREATE TYPE ocr_status          AS ENUM ('NOT_APPLICABLE','PENDING','PROCESSING',
                                         'COMPLETED','FAILED');

-- D34 / 08_ownership_document_locker.md §4 — Title Case, rendered into the FSR
CREATE TYPE insurable_interest_status AS ENUM ('Established','Under Verification',
                                               'Incomplete Documentation','Disputed');

-- 11_document_verification_audit.md §4 audit_status; FR-10.2 flag vocabulary
CREATE TYPE audit_status        AS ENUM ('VERIFIED','RATE_INFLATED','DUPLICATE',
                                         'NOT_DAMAGED_IN_INCIDENT','OBSOLETE_ITEM',
                                         'BETTERMENT','PARTIALLY_ALLOWED','DISALLOWED',
                                         'PENDING_REVIEW');

---- Discrepancy flags (ADDITION — §16) -------------------------------------
CREATE TYPE discrepancy_code    AS ENUM (
    'LOCATION_DISCREPANCY_DETECTED',            -- FR-4.3
    'CHRONOLOGY_GAP_DETECTED',                  -- FR-5.3 / AC 5.1.3 (> 2 h)
    'DUPLICATE_CLAIM_ITEM',                     -- FR-10.2 / AC 10.1.x
    'RATE_INFLATION_DETECTED',                  -- FR-10.2 / AC 10.1.x (> 20 %)
    'ITEM_NOT_IN_DAMAGE_REGISTER',              -- FR-10.2
    'OBSOLETE_ITEM_CLAIMED',                    -- FR-10.2
    'BETTERMENT_DETECTED',                      -- FR-10.2
    'UNDERINSURANCE_DETECTED',                  -- FR-11.2 step 6
    'REPAIRABLE_VS_TOTAL_LOSS_CONTRADICTION',   -- FR-15.1 gate 6
    'METADATA_MISMATCH',                        -- FR-15.1 gate 2
    'ARITHMETIC_MISMATCH',                      -- FR-15.1 gate 1
    'MISSING_DEDUCTION_REMARK',                 -- FR-15.1 gate 3
    'PHOTO_ANNEXURE_INCOMPLETE',                -- FR-15.1 gate 4
    'MANDATORY_DOCUMENT_MISSING',               -- FR-15.1 gate 5
    'NARRATIVE_CONTRADICTION');                 -- FR-15.1 gate 6

-- Design System §12.3: green = verified, amber = warning, red = critical blocker. Nothing else.
CREATE TYPE discrepancy_severity AS ENUM ('INFO','WARNING','CRITICAL');
CREATE TYPE discrepancy_status   AS ENUM ('OPEN','RESOLVED','ACCEPTED','DISMISSED');
CREATE TYPE detected_by          AS ENUM ('SYSTEM_RULE','AI_ASSISTANT','SURVEYOR');

---- Stage 12 ---------------------------------------------------------------
-- FR-12.2 Modes A / B / C
CREATE TYPE disposal_mode       AS ENUM ('RETAINED_BY_INSURED','SOLD_TO_SCRAP_BUYER',
                                         'INSURER_TENDER');

---- Stage 13 ---------------------------------------------------------------
-- 14_coverage_liability_opinion.md §4 — Title Case, rendered into FSR Section I
CREATE TYPE peril_admissibility AS ENUM ('Admissible','Inadmissible','Disputed');
CREATE TYPE warranty_compliance_status AS ENUM ('All Complied','Material Breach');
-- FR-13.2 verbatim, four values
CREATE TYPE surveyor_recommendation AS ENUM (
    'Admissible as Assessed',
    'Subject to Insurer Liability Determination',
    'Non-Admissible',
    'Repudiation Recommended');

---- Stages 8 / 14 / 15 -----------------------------------------------------
CREATE TYPE report_status       AS ENUM ('DRAFT','AI_DRAFTED','UNDER_REVIEW','APPROVED',
                                         'GENERATED','SUBMITTED','SUPERSEDED');
-- FR-15.1 seven gates, in spec order (D36)
CREATE TYPE audit_gate_code     AS ENUM ('ARITHMETIC_CHECK','METADATA_CONSISTENCY',
                                         'DEDUCTION_REMARKS','PHOTO_ANNEXURE_COMPLIANCE',
                                         'DOCUMENT_COMPLETENESS','CONTRADICTION_SCANNER',
                                         'HUMAN_APPROVAL_AI_GATE');
CREATE TYPE audit_gate_result   AS ENUM ('PASS','FAIL','NOT_RUN');

---- Cross-cutting ----------------------------------------------------------
-- SRS entity 14 audit_log action; §5.1 governance rule 3 requires VIEW and DOWNLOAD
CREATE TYPE audit_action        AS ENUM ('CREATE','UPDATE','DELETE','VIEW','DOWNLOAD',
                                         'EXPORT','APPROVE','SUBMIT','SIGN_OFF','RESTORE');

-- SRS entity 15 sync_queue
CREATE TYPE sync_operation      AS ENUM ('CREATE','UPDATE','DELETE');
CREATE TYPE sync_status         AS ENUM ('PENDING','IN_FLIGHT','SYNCED','CONFLICT',
                                         'FAILED','ABANDONED');
```

---

## 20. `claims` — SRS entity 1 (Stage 1)

The SRS field list is the minimum; FR-1.2 names fifteen further mandatory appointment attributes. They live here rather than in a separate `appointments` table because MVP has exactly one appointment per claim and `02_appointment_claim_intake.md` renders them as one form.

```sql
CREATE TABLE claims (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    ---- Common five (§18) ----------------------------------------------
    store_id                    UUID       NOT NULL REFERENCES stores(id),
    client_id                   UUID       NOT NULL REFERENCES users(id),
    assigned_surveyor_id        UUID       REFERENCES users(id),
    reviewer_id                 UUID       REFERENCES users(id),
    access_role_scope           role_scope NOT NULL DEFAULT 'SURVEYOR',

    ---- Identity (FR-1.3) ----------------------------------------------
    claim_ref_no                VARCHAR(20),          -- SS-YYYY-XXXXX; NULL until first sync
    temp_ref_no                 VARCHAR(20),          -- TEMP-SS-XXXX; display only, offline
    ref_year                    SMALLINT,             -- YYYY component, for the per-store sequence
    ref_sequence                INTEGER,              -- XXXXX component

    ---- Appointment (FR-1.2) -------------------------------------------
    insurer_name                VARCHAR(200) NOT NULL,
    operating_office_division   VARCHAR(200),
    insurer_claim_ref_no        VARCHAR(50)  NOT NULL,
    appointment_date            DATE         NOT NULL,
    insurer_instructions        TEXT,                 -- joint survey, salvage guidance, deadlines

    ---- Policy & insured (FR-1.2) --------------------------------------
    policy_no                   VARCHAR(60)  NOT NULL,
    insured_name                VARCHAR(200) NOT NULL,
    insured_phone               VARCHAR(16)  NOT NULL,
    insured_email               CITEXT,
    representative_name         VARCHAR(150),
    representative_designation  VARCHAR(120),
    policy_risk_address         TEXT,

    ---- Loss (FR-1.2) ---------------------------------------------------
    loss_date                   DATE         NOT NULL,
    loss_time                   TIME,
    peril                       peril_type   NOT NULL,
    reported_nature_of_loss     TEXT,
    preliminary_loss_estimate   NUMERIC(15,2),

    ---- State machine (FR-1.3, CR-W1) ----------------------------------
    status                      claim_status NOT NULL DEFAULT 'ACTIVE',
    current_stage               SMALLINT     NOT NULL DEFAULT 1,
    stage_entered_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    ---- Sync (§18) ------------------------------------------------------
    client_updated_at           TIMESTAMPTZ,
    field_updated_at            JSONB        NOT NULL DEFAULT '{}'::jsonb,
    sync_revision               BIGINT       NOT NULL DEFAULT 0,

    created_at                  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    deleted_at                  TIMESTAMPTZ,

    ---- Validation (02_appointment_claim_intake.md §4, FR-1.3) ----------
    CONSTRAINT claims_stage_range     CHECK (current_stage BETWEEN 1 AND 15),
    CONSTRAINT claims_ref_format      CHECK (claim_ref_no IS NULL
                                             OR claim_ref_no ~ '^[A-Z]{2,8}-[0-9]{4}-[0-9]{5}$'),
    CONSTRAINT claims_temp_ref_format CHECK (temp_ref_no IS NULL
                                             OR temp_ref_no ~ '^TEMP-[A-Z]{2,8}-[0-9]{4}$'),
    CONSTRAINT claims_policy_len      CHECK (char_length(policy_no) >= 6),
    CONSTRAINT claims_insured_len     CHECK (char_length(insured_name) >= 3),
    CONSTRAINT claims_phone_format    CHECK (insured_phone ~ '^\+[1-9][0-9]{7,14}$'),
    CONSTRAINT claims_loss_before_appt CHECK (loss_date <= appointment_date),
    CONSTRAINT claims_estimate_nonneg CHECK (preliminary_loss_estimate IS NULL
                                             OR preliminary_loss_estimate >= 0),
    -- A synced claim must have a permanent reference; an unsynced one must have a temp reference.
    CONSTRAINT claims_has_a_reference CHECK (claim_ref_no IS NOT NULL OR temp_ref_no IS NOT NULL)
);

CREATE UNIQUE INDEX uq_claims_ref
    ON claims (store_id, claim_ref_no) WHERE deleted_at IS NULL AND claim_ref_no IS NOT NULL;
CREATE UNIQUE INDEX uq_claims_ref_sequence
    ON claims (store_id, ref_year, ref_sequence)
    WHERE deleted_at IS NULL AND ref_sequence IS NOT NULL;

CREATE INDEX idx_claims_store_stage   ON claims (store_id, current_stage) WHERE deleted_at IS NULL;
CREATE INDEX idx_claims_store_status  ON claims (store_id, status)        WHERE deleted_at IS NULL;
CREATE INDEX idx_claims_surveyor      ON claims (store_id, assigned_surveyor_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_claims_loss_date     ON claims (store_id, loss_date DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_claims_appt_date     ON claims (store_id, appointment_date DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_claims_insurer       ON claims (store_id, insurer_name)  WHERE deleted_at IS NULL;
-- 02_appointment_claim_intake.md §5: duplicate-claim warning on matching policy no + loss date.
-- Deliberately an INDEX, not a UNIQUE constraint: the spec says warn, not block.
CREATE INDEX idx_claims_duplicate_probe ON claims (store_id, policy_no, loss_date) WHERE deleted_at IS NULL;
-- 01_dashboard.md §4: search across claim ref, insured, insurer, policy no
CREATE INDEX idx_claims_search ON claims
    USING gin (to_tsvector('simple',
        coalesce(claim_ref_no,'') || ' ' || coalesce(temp_ref_no,'') || ' ' ||
        insured_name || ' ' || insurer_name || ' ' || policy_no));

CREATE TRIGGER trg_claims_updated_at
    BEFORE UPDATE ON claims FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

**`claim_ref_no` is allocated on the server, not the device.** FR-1.3 makes `SS-YYYY-XXXXX` a monotonic per-store sequence, and two offline devices cannot agree on the next number. The device writes `temp_ref_no` (`TEMP-SS-XXXX`, random suffix) and the server fills `claim_ref_no`, `ref_year` and `ref_sequence` on first sync. `uq_claims_ref_sequence` makes a duplicate allocation a database error rather than a silent collision.

**`current_stage` is a `SMALLINT`, not an enum.** It is compared with `<` and `>` throughout the pipeline UI (`01_dashboard.md` stage filter pills, the 15-stage tracker), and ordinal comparison on a PostgreSQL enum depends on declaration order, which is a fragile thing to rely on for a number the specs already write as 1–15.

---

## 21. `policy_details` (SRS entity 2) and `policy_sections` `[ADDITION]` (Stage 2)

```sql
CREATE TABLE policy_details (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id             UUID       NOT NULL REFERENCES claims(id) ON DELETE CASCADE,

    store_id             UUID       NOT NULL REFERENCES stores(id),
    client_id            UUID       NOT NULL REFERENCES users(id),
    assigned_surveyor_id UUID       REFERENCES users(id),
    reviewer_id          UUID       REFERENCES users(id),
    access_role_scope    role_scope NOT NULL DEFAULT 'SURVEYOR',

    policy_type          policy_type   NOT NULL,
    inception_date       DATE          NOT NULL,
    expiry_date          DATE          NOT NULL,
    sum_insured_total    NUMERIC(15,2) NOT NULL DEFAULT 0,   -- derived; see below

    ---- FR-2.1 -----------------------------------------------------------
    perils_covered       JSONB         NOT NULL DEFAULT '[]'::jsonb,
    special_clauses      JSONB         NOT NULL DEFAULT '[]'::jsonb,
    warranties_json      JSONB         NOT NULL DEFAULT '[]'::jsonb,
    excess_clause        TEXT          NOT NULL,
    excess_schedule_json JSONB         NOT NULL DEFAULT '{}'::jsonb,

    ---- FR-2.2 -----------------------------------------------------------
    intimation_received_at   TIMESTAMPTZ,
    insured_initial_estimate NUMERIC(15,2),

    client_updated_at    TIMESTAMPTZ,
    field_updated_at     JSONB       NOT NULL DEFAULT '{}'::jsonb,
    sync_revision        BIGINT      NOT NULL DEFAULT 0,

    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at           TIMESTAMPTZ,

    -- 03_policy_coverage_review.md §4
    CONSTRAINT policy_period_order  CHECK (expiry_date >= inception_date),
    CONSTRAINT policy_excess_len    CHECK (char_length(excess_clause) >= 5),
    CONSTRAINT policy_si_nonneg     CHECK (sum_insured_total >= 0)
);

CREATE UNIQUE INDEX uq_policy_details_claim ON policy_details (claim_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_policy_details_store ON policy_details (store_id) WHERE deleted_at IS NULL;

CREATE TRIGGER trg_policy_details_updated_at
    BEFORE UPDATE ON policy_details FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

**The loss-date-in-period rule is not a `CHECK`.** `03_policy_coverage_review.md` §4 defines `date_of_loss_check` as a computed field that *flags an error*, and §11.5 of `CLAUDE.md` states the rule. It spans two tables (`claims.loss_date` and `policy_details`), which a row-level `CHECK` cannot see. It is enforced in the Stage 2 service and, on failure, written as a `discrepancy_flags` row so the FSR Section H narrative can pick it up. Making it a hard constraint would also make a genuine out-of-period loss — which is exactly the finding a surveyor must report — impossible to record.

**JSONB payload shapes.**

```jsonc
// perils_covered — FR-2.1, matched against claims.peril by AI-3 (FR-2.3)
[ { "peril": "FLOOD_INUNDATION", "policy_reference": "SFSP Item VI", "covered": true } ]

// warranties_json — FR-2.1; consumed by Stage 13 coverage_opinions.warranty_compliance_json
[ { "code": "FEA_WARRANTY", "title": "Fire Extinguishing Appliances Warranty",
    "text": "...", "applies_to_sections": ["BUILDING","PLANT_MACHINERY"] } ]

// special_clauses — FR-2.1 (Designation of Property, Escalation, Reinstatement Value)
[ { "code": "REINSTATEMENT_VALUE", "title": "Reinstatement Value Clause", "text": "..." } ]

// excess_schedule_json — FR-2.1 "per section / percentage of claim subject to minimum"
{ "default": { "percent_of_claim": 5.0, "minimum_amount": 25000.00 },
  "by_section": { "STOCKS": { "percent_of_claim": 5.0, "minimum_amount": 100000.00 } } }
```

### 21.1 `policy_sections` `[ADDITION]`

`03_policy_coverage_review.md` §4 types `sum_insured_heads` as `Array<Object>`, and FR-2.1 lists seven named sections. A JSONB array would work for display, but FR-11.2 step 6 divides by the sum insured to compute the underinsurance deduction — a number that reduces a surveyor's recommendation and that `audit_log` must be able to record a before/after value for. That makes it a column, not a JSON key.

```sql
CREATE TABLE policy_sections (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_details_id    UUID       NOT NULL REFERENCES policy_details(id) ON DELETE CASCADE,
    claim_id             UUID       NOT NULL REFERENCES claims(id) ON DELETE CASCADE,

    store_id             UUID       NOT NULL REFERENCES stores(id),
    client_id            UUID       NOT NULL REFERENCES users(id),
    assigned_surveyor_id UUID       REFERENCES users(id),
    reviewer_id          UUID       REFERENCES users(id),
    access_role_scope    role_scope NOT NULL DEFAULT 'SURVEYOR',

    section_head         policy_section_head NOT NULL,   -- FR-2.1, seven values
    head_category        head_category       NOT NULL,   -- FR-11.1 roll-up, for underinsurance
    section_label        VARCHAR(160),                   -- verbatim wording on the policy schedule
    sum_insured          NUMERIC(15,2)       NOT NULL,
    display_order        SMALLINT            NOT NULL DEFAULT 0,

    client_updated_at    TIMESTAMPTZ,
    field_updated_at     JSONB       NOT NULL DEFAULT '{}'::jsonb,
    sync_revision        BIGINT      NOT NULL DEFAULT 0,

    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at           TIMESTAMPTZ,

    CONSTRAINT policy_sections_si_nonneg CHECK (sum_insured >= 0)
);

CREATE UNIQUE INDEX uq_policy_sections_head
    ON policy_sections (policy_details_id, section_head) WHERE deleted_at IS NULL;
CREATE INDEX idx_policy_sections_claim ON policy_sections (store_id, claim_id) WHERE deleted_at IS NULL;

CREATE TRIGGER trg_policy_sections_updated_at
    BEFORE UPDATE ON policy_sections FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

`head_category` is stored, not inferred, because the seven policy sections roll up to the five FR-11.1 assessment heads many-to-one (`RAW_MATERIALS`, `WORK_IN_PROGRESS`, `FINISHED_GOODS` and `STOCK_IN_OPEN` all map to `STOCKS`) and a policy schedule may name a section the mapping table does not anticipate. `policy_details.sum_insured_total` is maintained by the application as the sum of its sections; the "at least one head with SI > 0" rule (`03_policy_coverage_review.md` §4) is a Stage 2 service check, since no row-level constraint can assert the existence of a sibling row.

---

## 22. `contact_logs` (SRS entity 16) and `preservation_notices` (SRS entity 20) — Stage 3

```sql
CREATE TABLE contact_logs (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id             UUID       NOT NULL REFERENCES claims(id) ON DELETE CASCADE,

    store_id             UUID       NOT NULL REFERENCES stores(id),
    client_id            UUID       NOT NULL REFERENCES users(id),
    assigned_surveyor_id UUID       REFERENCES users(id),
    reviewer_id          UUID       REFERENCES users(id),
    access_role_scope    role_scope NOT NULL DEFAULT 'SURVEYOR',

    ---- FR-3.1 ----------------------------------------------------------
    contacted_at         TIMESTAMPTZ NOT NULL,
    contact_person       VARCHAR(150) NOT NULL,
    phone                VARCHAR(16),
    channel              dispatch_channel NOT NULL,
    outcome              contact_outcome  NOT NULL,
    site_available       BOOLEAN,
    notes                TEXT         NOT NULL,

    ---- FR-3.2 (scheduling lives on the claim's Stage 3 record) ----------
    scheduled_visit_at   TIMESTAMPTZ,
    calendar_event_uid   VARCHAR(255),          -- native device calendar / .ics UID

    client_updated_at    TIMESTAMPTZ,
    field_updated_at     JSONB       NOT NULL DEFAULT '{}'::jsonb,
    sync_revision        BIGINT      NOT NULL DEFAULT 0,

    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at           TIMESTAMPTZ,

    -- 04_insured_contact_schedule.md §4
    CONSTRAINT contact_logs_person_len CHECK (char_length(contact_person) >= 3),
    CONSTRAINT contact_logs_notes_len  CHECK (char_length(notes) >= 10),
    CONSTRAINT contact_logs_phone_fmt  CHECK (phone IS NULL OR phone ~ '^\+[1-9][0-9]{7,14}$')
);

CREATE INDEX idx_contact_logs_claim ON contact_logs (store_id, claim_id, contacted_at DESC)
    WHERE deleted_at IS NULL;

CREATE TRIGGER trg_contact_logs_updated_at
    BEFORE UPDATE ON contact_logs FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

`scheduled_visit_at` is nullable and set on the log entry where the visit was agreed, which is what `04_insured_contact_schedule.md` §4 describes (`scheduled_visit_date` + `scheduled_visit_time` captured alongside the conversation). The "cannot be in past" rule from that spec is a client/service validation, not a `CHECK` — a `CHECK` against `NOW()` is non-deterministic and would make the row un-updatable the moment the date passes.

```sql
CREATE TABLE preservation_notices (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id             UUID       NOT NULL REFERENCES claims(id) ON DELETE CASCADE,

    store_id             UUID       NOT NULL REFERENCES stores(id),
    client_id            UUID       NOT NULL REFERENCES users(id),
    assigned_surveyor_id UUID       REFERENCES users(id),
    reviewer_id          UUID       REFERENCES users(id),
    access_role_scope    role_scope NOT NULL DEFAULT 'SURVEYOR',

    ---- FR-3.3 ----------------------------------------------------------
    template_version     VARCHAR(16)      NOT NULL,
    custom_instructions  TEXT,
    rendered_body        TEXT             NOT NULL,   -- exact text dispatched; evidentiary
    dispatch_channel     dispatch_channel NOT NULL,
    recipient_name       VARCHAR(150),
    recipient_phone      VARCHAR(16),
    recipient_email      CITEXT,
    dispatch_status      dispatch_status  NOT NULL DEFAULT 'PENDING',
    dispatched_at        TIMESTAMPTZ,
    delivery_reference   VARCHAR(255),               -- provider message id (NotificationService)
    failure_reason       TEXT,

    client_updated_at    TIMESTAMPTZ,
    field_updated_at     JSONB       NOT NULL DEFAULT '{}'::jsonb,
    sync_revision        BIGINT      NOT NULL DEFAULT 0,

    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at           TIMESTAMPTZ,

    CONSTRAINT preservation_dispatched_when_sent
        CHECK (dispatch_status NOT IN ('SENT','DELIVERED') OR dispatched_at IS NOT NULL)
);

CREATE INDEX idx_preservation_claim  ON preservation_notices (store_id, claim_id)
    WHERE deleted_at IS NULL;
CREATE INDEX idx_preservation_status ON preservation_notices (store_id, dispatch_status)
    WHERE deleted_at IS NULL AND dispatch_status IN ('PENDING','QUEUED','FAILED');

CREATE TRIGGER trg_preservation_updated_at
    BEFORE UPDATE ON preservation_notices FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

`rendered_body` stores the exact text that was dispatched, not a reference to the template. A template revised later must not retroactively change what a surveyor can prove they sent — the notice is the instrument that establishes the insured's preservation duty under FR-3.3.

---

## 23. `site_visits` — SRS entity 3, absorbing entity 17 (Stages 4 and 9)

Per **Q2a** (§17.1) this is one table for both the Stage 4 initial visit and every Stage 9 follow-up.

```sql
CREATE TABLE site_visits (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id             UUID       NOT NULL REFERENCES claims(id) ON DELETE CASCADE,

    store_id             UUID       NOT NULL REFERENCES stores(id),
    client_id            UUID       NOT NULL REFERENCES users(id),
    assigned_surveyor_id UUID       REFERENCES users(id),
    reviewer_id          UUID       REFERENCES users(id),
    access_role_scope    role_scope NOT NULL DEFAULT 'SURVEYOR',

    visit_type           visit_type NOT NULL,
    visit_no             INTEGER    NOT NULL,          -- 1 = INITIAL; follow-ups continue from 2
    visit_date           DATE       NOT NULL,
    visit_started_at     TIMESTAMPTZ,
    visit_ended_at       TIMESTAMPTZ,

    ---- Stage 4 / FR-4.1 — GPS capture ----------------------------------
    gps_lat              NUMERIC(9,6),
    gps_lng              NUMERIC(9,6),
    gps_accuracy_meters  NUMERIC(7,2),
    gps_altitude_meters  NUMERIC(8,2),
    gps_captured_at      TIMESTAMPTZ,

    ---- Stage 4 / FR-4.2, FR-4.3 ----------------------------------------
    actual_location_address  TEXT,
    occupancy_nature         VARCHAR(200),
    business_activities      TEXT,
    premises_ownership       VARCHAR(120),
    distance_from_policy_address_meters NUMERIC(10,2),
    location_discrepancy_flag BOOLEAN   NOT NULL DEFAULT FALSE,
    discrepancy_remarks       TEXT,

    ---- Stage 9 / FR-9.1, FR-9.2 (NULL on an INITIAL visit) --------------
    visit_purpose             visit_purpose,
    visit_purpose_other       VARCHAR(200),
    persons_attended          TEXT,
    detailed_findings         TEXT,
    contractor_discussion     TEXT,
    stock_reconciliation_json JSONB,

    client_updated_at    TIMESTAMPTZ,
    field_updated_at     JSONB       NOT NULL DEFAULT '{}'::jsonb,
    sync_revision        BIGINT      NOT NULL DEFAULT 0,

    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at           TIMESTAMPTZ,

    ---- Numbering (Q2a) --------------------------------------------------
    CONSTRAINT site_visits_no_positive  CHECK (visit_no >= 1),
    CONSTRAINT site_visits_type_numbering
        CHECK ((visit_type = 'INITIAL'   AND visit_no  = 1)
            OR (visit_type = 'FOLLOW_UP' AND visit_no >= 2)),

    ---- Stage 4 completeness (FR-4.1, FR-4.2) ---------------------------
    CONSTRAINT site_visits_initial_complete
        CHECK (visit_type <> 'INITIAL' OR (
                   gps_lat IS NOT NULL AND gps_lng IS NOT NULL
               AND gps_accuracy_meters IS NOT NULL
               AND actual_location_address IS NOT NULL
               AND occupancy_nature IS NOT NULL)),

    ---- Stage 9 completeness (10_followup_investigation.md §4) -----------
    CONSTRAINT site_visits_followup_complete
        CHECK (visit_type <> 'FOLLOW_UP' OR (
                   visit_purpose IS NOT NULL
               AND persons_attended  IS NOT NULL
               AND detailed_findings IS NOT NULL)),

    ---- Field ranges (05_risk_location_verification.md §4) ---------------
    CONSTRAINT site_visits_lat_range  CHECK (gps_lat IS NULL OR gps_lat BETWEEN -90  AND  90),
    CONSTRAINT site_visits_lng_range  CHECK (gps_lng IS NULL OR gps_lng BETWEEN -180 AND 180),
    -- D28: 50 m is the hard limit; a reading worse than this cannot be saved at all.
    CONSTRAINT site_visits_gps_hard_limit
        CHECK (gps_accuracy_meters IS NULL OR gps_accuracy_meters <= 50),
    CONSTRAINT site_visits_address_len
        CHECK (actual_location_address IS NULL OR char_length(actual_location_address) >= 15),
    CONSTRAINT site_visits_occupancy_len
        CHECK (occupancy_nature IS NULL OR char_length(occupancy_nature) >= 5),
    -- §11.3: discrepancy_remarks mandatory when location_discrepancy = true
    CONSTRAINT site_visits_discrepancy_remarks
        CHECK (location_discrepancy_flag = FALSE
               OR (discrepancy_remarks IS NOT NULL AND char_length(discrepancy_remarks) > 0)),
    CONSTRAINT site_visits_findings_len
        CHECK (detailed_findings IS NULL OR char_length(detailed_findings) >= 30),
    CONSTRAINT site_visits_persons_len
        CHECK (persons_attended IS NULL OR char_length(persons_attended) >= 3),
    CONSTRAINT site_visits_time_order
        CHECK (visit_ended_at IS NULL OR visit_started_at IS NULL
               OR visit_ended_at >= visit_started_at)
);

CREATE UNIQUE INDEX uq_site_visits_no
    ON site_visits (claim_id, visit_no) WHERE deleted_at IS NULL;
-- At most one INITIAL visit per claim, independent of the visit_no rule above.
CREATE UNIQUE INDEX uq_site_visits_initial
    ON site_visits (claim_id) WHERE deleted_at IS NULL AND visit_type = 'INITIAL';

CREATE INDEX idx_site_visits_claim ON site_visits (store_id, claim_id, visit_no)
    WHERE deleted_at IS NULL;
CREATE INDEX idx_site_visits_discrepancy ON site_visits (store_id, claim_id)
    WHERE deleted_at IS NULL AND location_discrepancy_flag = TRUE;

CREATE TRIGGER trg_site_visits_updated_at
    BEFORE UPDATE ON site_visits FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

**Only the 50 m hard limit is a `CHECK`; the 10 m target is not.** D28 and FR-4.1 define two thresholds with different consequences: above 10 m *warn and prompt a re-capture*, above 50 m *block the save*. Encoding the 10 m target as a constraint would turn a warning into a rejection and make the surveyor unable to record a legitimately imprecise reading — indoors, in a basement, under a metal roof. The warn threshold belongs in the Stage 4 client and service.

**`stock_reconciliation_json`** (FR-9.2, `10_followup_investigation.md`):

```jsonc
{ "as_of_date": "2026-03-14",
  "opening_stock_value": 4820000.00,
  "purchases_since": 610000.00,
  "sales_since": 380000.00,
  "book_stock_value": 5050000.00,
  "physical_stock_value": 1240000.00,
  "shortage_value": 3810000.00,
  "basis": "Monthly stock statement submitted to Bank of Baroda, Feb 2026",
  "source_document_ids": ["…uuid…"] }
```

---

## 24. `cause_investigations` (SRS entity 4) and `chronology_events` `[ADDITION]` — Stage 5

```sql
CREATE TABLE cause_investigations (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id             UUID       NOT NULL REFERENCES claims(id) ON DELETE CASCADE,

    store_id             UUID       NOT NULL REFERENCES stores(id),
    client_id            UUID       NOT NULL REFERENCES users(id),
    assigned_surveyor_id UUID       REFERENCES users(id),
    reviewer_id          UUID       REFERENCES users(id),
    access_role_scope    role_scope NOT NULL DEFAULT 'SURVEYOR',

    ---- FR-5.1 / 06_cause_investigation.md §4 ---------------------------
    incident_datetime    TIMESTAMPTZ NOT NULL,
    discovery_datetime   TIMESTAMPTZ NOT NULL,
    notification_datetime TIMESTAMPTZ,
    reported_cause       peril_type  NOT NULL,
    reported_cause_other VARCHAR(200),
    point_of_origin      VARCHAR(300) NOT NULL,
    sequence_of_events   TEXT         NOT NULL,
    mitigation_steps     TEXT         NOT NULL,

    ---- FR-5.2 statutory evidence ---------------------------------------
    fir_details          JSONB       NOT NULL DEFAULT '{}'::jsonb,
    fire_report_details  JSONB       NOT NULL DEFAULT '{}'::jsonb,
    third_party_reports  JSONB       NOT NULL DEFAULT '[]'::jsonb,
    -- Promoted out of fire_report_details because AC 5.1.3 compares it numerically
    -- and 06_cause_investigation.md §4 makes it conditionally mandatory for Fire claims.
    fire_brigade_call_time TIMESTAMPTZ,

    client_updated_at    TIMESTAMPTZ,
    field_updated_at     JSONB       NOT NULL DEFAULT '{}'::jsonb,
    sync_revision        BIGINT      NOT NULL DEFAULT 0,

    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at           TIMESTAMPTZ,

    -- §11.4
    CONSTRAINT cause_discovery_after_incident CHECK (discovery_datetime >= incident_datetime),
    CONSTRAINT cause_notification_after_discovery
        CHECK (notification_datetime IS NULL OR notification_datetime >= discovery_datetime),
    CONSTRAINT cause_origin_len       CHECK (char_length(point_of_origin)    >= 5),
    CONSTRAINT cause_sequence_len     CHECK (char_length(sequence_of_events) >= 50),
    CONSTRAINT cause_mitigation_len   CHECK (char_length(mitigation_steps)   >= 20)
);

CREATE UNIQUE INDEX uq_cause_investigations_claim
    ON cause_investigations (claim_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_cause_investigations_store ON cause_investigations (store_id)
    WHERE deleted_at IS NULL;

CREATE TRIGGER trg_cause_investigations_updated_at
    BEFORE UPDATE ON cause_investigations FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

**`fire_brigade_call_time` is mandatory for Fire claims — but not by a `CHECK`.** The rule in `06_cause_investigation.md` §4 depends on `claims.peril`, in another table. It is a Stage 5 service validation. The column is promoted out of `fire_report_details` because AC 5.1.3 subtracts it from `discovery_datetime` to raise `CHRONOLOGY_GAP_DETECTED` above two hours, and arithmetic on a JSONB key is both slower and untypeable.

**JSONB payload shapes** (FR-5.2):

```jsonc
// fir_details
{ "fir_number": "112/2026", "fir_date": "2026-03-02",
  "police_station": "Vatva Industrial PS, Ahmedabad", "gist": "...",
  "document_id": "…uuid of the documents row…" }

// fire_report_details
{ "fire_station": "Narol Fire Station", "call_time": "2026-03-02T02:14:00+05:30",
  "arrival_time": "2026-03-02T02:31:00+05:30", "containment_time": "2026-03-02T04:05:00+05:30",
  "fire_officer_name": "...", "stated_cause": "Electrical short circuit — LT panel",
  "document_id": "…uuid…" }

// third_party_reports — IMD weather, factory logbook, CCTV notes, forensic engineer
[ { "kind": "WEATHER_IMD_REPORT", "summary": "...", "document_id": "…uuid…" } ]
```

### 24.1 `chronology_events` `[ADDITION]`

`06_cause_investigation.md` §3 specifies a `TimelineCardList` of repeating cards, each with a timestamp, a type drawn from six values, a description and a witness. AC 5.1.3 then compares consecutive event timestamps to warn on gaps over two hours. Neither is expressible over the single `sequence_of_events` narrative text field.

```sql
CREATE TABLE chronology_events (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cause_investigation_id UUID       NOT NULL REFERENCES cause_investigations(id) ON DELETE CASCADE,
    claim_id               UUID       NOT NULL REFERENCES claims(id) ON DELETE CASCADE,

    store_id             UUID       NOT NULL REFERENCES stores(id),
    client_id            UUID       NOT NULL REFERENCES users(id),
    assigned_surveyor_id UUID       REFERENCES users(id),
    reviewer_id          UUID       REFERENCES users(id),
    access_role_scope    role_scope NOT NULL DEFAULT 'SURVEYOR',

    event_timestamp      TIMESTAMPTZ           NOT NULL,
    event_type           chronology_event_type NOT NULL,
    description          TEXT                  NOT NULL,
    witness_person       VARCHAR(150),
    source_document_id   UUID,                  -- FK added after documents (§27)
    display_order        SMALLINT              NOT NULL DEFAULT 0,

    client_updated_at    TIMESTAMPTZ,
    field_updated_at     JSONB       NOT NULL DEFAULT '{}'::jsonb,
    sync_revision        BIGINT      NOT NULL DEFAULT 0,

    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at           TIMESTAMPTZ,

    CONSTRAINT chronology_description_len CHECK (char_length(description) >= 5)
);

CREATE INDEX idx_chronology_claim
    ON chronology_events (store_id, claim_id, event_timestamp) WHERE deleted_at IS NULL;

CREATE TRIGGER trg_chronology_updated_at
    BEFORE UPDATE ON chronology_events FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

The two-hour gap rule is **not** a constraint. A real chronology can legitimately contain a long gap — an overnight fire discovered at shift start — and AC 5.1.3 asks the system to *warn*, not to refuse. The check runs in the Stage 5 service and writes a `CHRONOLOGY_GAP_DETECTED` row into `discrepancy_flags` (§29).

---

## 25. `damage_items` — SRS entity 5 (Stage 6)

```sql
CREATE TABLE damage_items (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id             UUID       NOT NULL REFERENCES claims(id) ON DELETE CASCADE,

    store_id             UUID       NOT NULL REFERENCES stores(id),
    client_id            UUID       NOT NULL REFERENCES users(id),
    assigned_surveyor_id UUID       REFERENCES users(id),
    reviewer_id          UUID       REFERENCES users(id),
    access_role_scope    role_scope NOT NULL DEFAULT 'SURVEYOR',

    site_visit_id        UUID       REFERENCES site_visits(id),   -- visit the item was recorded on
    item_no              INTEGER    NOT NULL,                     -- surveyor-visible Sr. No.

    ---- FR-6.1 / 07_damage_inspection_studio.md §4 ----------------------
    head_category        head_category NOT NULL,
    description          TEXT          NOT NULL,
    make_model           VARCHAR(200),
    capacity             VARCHAR(120),
    serial_number        VARCHAR(120),
    qty                  NUMERIC(14,3) NOT NULL,
    uom                  uom           NOT NULL,
    damage_extent        TEXT          NOT NULL,   -- narrative: "Severe submersion", "Smoke contamination"
    damage_severity      damage_severity NOT NULL,
    repair_or_replace    damage_recommendation NOT NULL,
    pre_existing_damage  TEXT,                     -- prior wear & tear / deterioration notes

    client_updated_at    TIMESTAMPTZ,
    field_updated_at     JSONB       NOT NULL DEFAULT '{}'::jsonb,
    sync_revision        BIGINT      NOT NULL DEFAULT 0,

    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at           TIMESTAMPTZ,

    CONSTRAINT damage_items_desc_len CHECK (char_length(description) >= 3),
    CONSTRAINT damage_items_qty_pos  CHECK (qty > 0),
    CONSTRAINT damage_items_no_pos   CHECK (item_no >= 1)
);

CREATE UNIQUE INDEX uq_damage_items_no
    ON damage_items (claim_id, item_no) WHERE deleted_at IS NULL;
CREATE INDEX idx_damage_items_claim ON damage_items (store_id, claim_id, head_category)
    WHERE deleted_at IS NULL;
CREATE INDEX idx_damage_items_serial ON damage_items (store_id, serial_number)
    WHERE deleted_at IS NULL AND serial_number IS NOT NULL;

CREATE TRIGGER trg_damage_items_updated_at
    BEFORE UPDATE ON damage_items FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

Two rules from `07_damage_inspection_studio.md` §4 are deliberately **not** constraints:

- **`serial_number` mandatory for Machinery/Electronics.** The spec words the trigger as an item *category*, but `head_category` groups `PLANT_MACHINERY` with items that legitimately have no serial (fabricated structures, cabling runs). A hard `CHECK` would block a truthful record. Enforced as a Stage 6 service validation that the surveyor can override with a note.
- **At least one photo per damaged item** (`CLAUDE.md` §14 constraint 9). This asserts the existence of a row in another table, which no row-level `CHECK` can do. It is a Stage 6 save-gate and again at Stage 15 gate 4 (`PHOTO_ANNEXURE_INCOMPLETE`).

`head_category` uses the same five-value FR-11.1 enum as `assessment_line_items`, so Stage 15 gate 6 can compare a Stage 6 item against its Stage 11 quantification directly. FR-6.1 additionally names "Electrical" as a Stage 6 head — see §38 item 4.

---

## 26. `media_attachments` — SRS entity 6 (Stages 6, 9)

```sql
CREATE TABLE media_attachments (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id             UUID       NOT NULL REFERENCES claims(id) ON DELETE CASCADE,
    damage_item_id       UUID       REFERENCES damage_items(id),
    site_visit_id        UUID       REFERENCES site_visits(id),   -- Stage 4/6 or Stage 9 follow-up
    document_id          UUID,                                    -- FK added after documents (§27)

    store_id             UUID       NOT NULL REFERENCES stores(id),
    client_id            UUID       NOT NULL REFERENCES users(id),
    assigned_surveyor_id UUID       REFERENCES users(id),
    reviewer_id          UUID       REFERENCES users(id),
    access_role_scope    role_scope NOT NULL DEFAULT 'SURVEYOR',

    media_type           media_type NOT NULL,
    category_tag         photo_category,               -- FR-6.2, mandatory for PHOTO
    file_uri             TEXT       NOT NULL,          -- local device URI or object-store key
    thumbnail_uri        TEXT,
    original_filename    VARCHAR(255),
    mime_type            VARCHAR(100),
    byte_size            BIGINT,
    width_px             INTEGER,
    height_px            INTEGER,
    duration_seconds     NUMERIC(9,2),                 -- VIDEO / AUDIO
    sha256               CHAR(64),                     -- integrity; also de-duplication

    ---- FR-6.2 watermark provenance -------------------------------------
    gps_lat              NUMERIC(9,6),
    gps_lng              NUMERIC(9,6),
    gps_accuracy_meters  NUMERIC(7,2),
    captured_at          TIMESTAMPTZ NOT NULL,
    watermark_applied    BOOLEAN     NOT NULL DEFAULT FALSE,
    watermark_text       TEXT,                          -- exact overlay burnt into the image
    exif_json            JSONB       NOT NULL DEFAULT '{}'::jsonb,
    caption              TEXT,

    ---- Transcription (AI-1, FR-6.2 voice notes) ------------------------
    transcript_text      TEXT,
    transcript_provider  VARCHAR(40),                   -- e.g. 'local-whisper', 'cloud'

    ---- Upload pipeline (§6.1 chunked upload, exponential backoff) -------
    upload_status        sync_status NOT NULL DEFAULT 'PENDING',
    upload_attempts      INTEGER     NOT NULL DEFAULT 0,
    uploaded_at          TIMESTAMPTZ,
    remote_uri           TEXT,

    client_updated_at    TIMESTAMPTZ,
    field_updated_at     JSONB       NOT NULL DEFAULT '{}'::jsonb,
    sync_revision        BIGINT      NOT NULL DEFAULT 0,

    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at           TIMESTAMPTZ,

    -- FR-6.2: the six-category tag is mandatory on a photo, meaningless on audio.
    CONSTRAINT media_photo_category
        CHECK (media_type <> 'PHOTO' OR category_tag IS NOT NULL),
    CONSTRAINT media_lat_range CHECK (gps_lat IS NULL OR gps_lat BETWEEN -90  AND  90),
    CONSTRAINT media_lng_range CHECK (gps_lng IS NULL OR gps_lng BETWEEN -180 AND 180),
    CONSTRAINT media_sha256_hex CHECK (sha256 IS NULL OR sha256 ~ '^[0-9a-f]{64}$'),
    CONSTRAINT media_size_pos   CHECK (byte_size IS NULL OR byte_size > 0)
);

CREATE INDEX idx_media_claim  ON media_attachments (store_id, claim_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_media_item   ON media_attachments (store_id, damage_item_id)
    WHERE deleted_at IS NULL AND damage_item_id IS NOT NULL;
CREATE INDEX idx_media_visit  ON media_attachments (store_id, site_visit_id)
    WHERE deleted_at IS NULL AND site_visit_id IS NOT NULL;
CREATE INDEX idx_media_upload ON media_attachments (store_id, upload_status)
    WHERE deleted_at IS NULL AND upload_status <> 'SYNCED';
CREATE UNIQUE INDEX uq_media_sha256_per_claim
    ON media_attachments (claim_id, sha256) WHERE deleted_at IS NULL AND sha256 IS NOT NULL;

CREATE TRIGGER trg_media_updated_at
    BEFORE UPDATE ON media_attachments FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

**`watermark_text` records the overlay, it does not produce it.** `CLAUDE.md` §14 constraint 9 requires the watermark to be *indelible* — burnt into the JPEG pixels at capture time on the device, before compression to 1600×1200 @ 85% (§6.1). This column stores the same string for the report annexure caption and for Stage 15 gate 4, so the audit does not have to OCR the image to prove the photo was tagged. `watermark_applied = FALSE` on a photo is itself an audit failure.

**`sha256` is unique per claim.** The same physical photograph attached twice to one claim inflates the annexure and is almost always an accidental re-upload after a failed sync. Across claims it is not unique, because the same nameplate photo can legitimately appear in two claims for the same insured.

---

## 27. `documents` (SRS entity 7) and `document_line_items` `[ADDITION]` — Stages 7, 10

```sql
CREATE TABLE documents (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id             UUID       NOT NULL REFERENCES claims(id) ON DELETE CASCADE,

    store_id             UUID       NOT NULL REFERENCES stores(id),
    client_id            UUID       NOT NULL REFERENCES users(id),
    assigned_surveyor_id UUID       REFERENCES users(id),
    reviewer_id          UUID       REFERENCES users(id),
    access_role_scope    role_scope NOT NULL DEFAULT 'SURVEYOR',

    doc_type             document_type NOT NULL,
    file_name            VARCHAR(255)  NOT NULL,
    file_uri             TEXT          NOT NULL,
    mime_type            VARCHAR(100),
    byte_size            BIGINT,
    page_count           INTEGER,
    sha256               CHAR(64),

    ---- Ownership / insurable interest (FR-7.1, 08_ownership_document_locker.md §4)
    invoice_number       VARCHAR(80),
    invoice_date         DATE,
    vendor_name          VARCHAR(200),
    invoice_amount       NUMERIC(15,2),
    insurable_interest_status insurable_interest_status,
    hypothecation_details     VARCHAR(200),

    ---- OCR pipeline (AI-2, FR-10.1) -------------------------------------
    ocr_status           ocr_status  NOT NULL DEFAULT 'NOT_APPLICABLE',
    ocr_data_json        JSONB       NOT NULL DEFAULT '{}'::jsonb,
    ocr_confidence       NUMERIC(5,2),
    ocr_provider         VARCHAR(40),
    ocr_completed_at     TIMESTAMPTZ,

    ---- Verification ------------------------------------------------------
    verified_flag        BOOLEAN     NOT NULL DEFAULT FALSE,
    verified_by_user_id  UUID        REFERENCES users(id),
    verified_at          TIMESTAMPTZ,
    surveyor_remarks     TEXT,

    ---- Provenance for generated documents (§22, §28, §33) ---------------
    source_notice_id     UUID,        -- preservation_notices.id or requisition_notices.id
    is_system_generated  BOOLEAN     NOT NULL DEFAULT FALSE,

    upload_status        sync_status NOT NULL DEFAULT 'PENDING',
    remote_uri           TEXT,

    client_updated_at    TIMESTAMPTZ,
    field_updated_at     JSONB       NOT NULL DEFAULT '{}'::jsonb,
    sync_revision        BIGINT      NOT NULL DEFAULT 0,

    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at           TIMESTAMPTZ,

    CONSTRAINT documents_sha256_hex CHECK (sha256 IS NULL OR sha256 ~ '^[0-9a-f]{64}$'),
    CONSTRAINT documents_vendor_len CHECK (vendor_name IS NULL OR char_length(vendor_name) >= 3),
    CONSTRAINT documents_amount_nonneg
        CHECK (invoice_amount IS NULL OR invoice_amount >= 0),
    CONSTRAINT documents_verified_consistency
        CHECK (verified_flag = FALSE OR (verified_by_user_id IS NOT NULL AND verified_at IS NOT NULL))
);

CREATE INDEX idx_documents_claim   ON documents (store_id, claim_id, doc_type) WHERE deleted_at IS NULL;
CREATE INDEX idx_documents_ocr     ON documents (store_id, ocr_status)
    WHERE deleted_at IS NULL AND ocr_status IN ('PENDING','PROCESSING','FAILED');
CREATE INDEX idx_documents_invoice ON documents (store_id, invoice_number)
    WHERE deleted_at IS NULL AND invoice_number IS NOT NULL;
CREATE INDEX idx_documents_notice  ON documents (source_notice_id) WHERE source_notice_id IS NOT NULL;

CREATE TRIGGER trg_documents_updated_at
    BEFORE UPDATE ON documents FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Deferred FKs, added once the referenced tables exist (§24.1, §26)
ALTER TABLE chronology_events
    ADD CONSTRAINT fk_chronology_document
    FOREIGN KEY (source_document_id) REFERENCES documents(id);
ALTER TABLE media_attachments
    ADD CONSTRAINT fk_media_document
    FOREIGN KEY (document_id) REFERENCES documents(id);
```

**`invoice_date` cannot be later than the date of loss** (`08_ownership_document_locker.md` §4) is a Stage 7 service check, not a `CHECK`: `claims.loss_date` is in another table.

**The document ↔ damage-item link is many-to-many.** `08_ownership_document_locker.md` §4 types `linked_damage_item_ids` as `Array<UUID>` and requires at least one. One invoice covers several damaged items and one item may be evidenced by an invoice plus a FAR extract, so this is a join table rather than a column on either side:

```sql
CREATE TABLE document_damage_links (
    document_id     UUID NOT NULL REFERENCES documents(id)    ON DELETE CASCADE,
    damage_item_id  UUID NOT NULL REFERENCES damage_items(id) ON DELETE CASCADE,
    claim_id        UUID NOT NULL REFERENCES claims(id)       ON DELETE CASCADE,
    store_id        UUID NOT NULL REFERENCES stores(id),
    client_id       UUID NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (document_id, damage_item_id)
);

CREATE INDEX idx_doc_damage_item ON document_damage_links (store_id, damage_item_id);
```

`document_damage_links` is a pure join table: it carries `store_id` and `client_id` for isolation but not `assigned_surveyor_id` / `reviewer_id` / `access_role_scope`, which have no meaning on an edge and would sit permanently NULL — the same rule Part A §1 applies to identity tables.

### 27.1 `document_line_items` `[ADDITION]`

FR-10.1 requires OCR extraction of "Item name, Qty, Unit Rate, GST/Taxes, Total", and `11_document_verification_audit.md` §4 is a per-line audit grid with its own status, variance percentage and mandatory deduction reason. `ocr_data_json` holds the raw extraction; this table holds the surveyor's audited version of it, because AC 10.1.x findings and FSR Section H are written against individual lines.

```sql
CREATE TABLE document_line_items (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id          UUID       NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    claim_id             UUID       NOT NULL REFERENCES claims(id)    ON DELETE CASCADE,
    damage_item_id       UUID       REFERENCES damage_items(id),      -- matched item, if any

    store_id             UUID       NOT NULL REFERENCES stores(id),
    client_id            UUID       NOT NULL REFERENCES users(id),
    assigned_surveyor_id UUID       REFERENCES users(id),
    reviewer_id          UUID       REFERENCES users(id),
    access_role_scope    role_scope NOT NULL DEFAULT 'SURVEYOR',

    line_no              INTEGER       NOT NULL,
    claim_item_description TEXT        NOT NULL,
    claimed_quantity     NUMERIC(14,3) NOT NULL,
    uom                  uom,
    claimed_unit_rate    NUMERIC(15,2) NOT NULL,
    tax_amount           NUMERIC(15,2) NOT NULL DEFAULT 0,
    claimed_total        NUMERIC(15,2) NOT NULL,

    ---- Cross-check against the original purchase invoice (AC 10.1.x) ----
    reference_document_id UUID         REFERENCES documents(id),
    original_unit_rate    NUMERIC(15,2),
    rate_variance_pct     NUMERIC(7,2),          -- computed: (claimed - original) / original * 100

    ---- Surveyor's forensic finding --------------------------------------
    audit_status         audit_status  NOT NULL DEFAULT 'PENDING_REVIEW',
    betterment_flag      BOOLEAN       NOT NULL DEFAULT FALSE,
    audit_deduction_reason TEXT,

    ---- OCR provenance ----------------------------------------------------
    extracted_by         detected_by   NOT NULL DEFAULT 'AI_ASSISTANT',
    extraction_confidence NUMERIC(5,2),
    surveyor_edited      BOOLEAN       NOT NULL DEFAULT FALSE,

    client_updated_at    TIMESTAMPTZ,
    field_updated_at     JSONB       NOT NULL DEFAULT '{}'::jsonb,
    sync_revision        BIGINT      NOT NULL DEFAULT 0,

    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at           TIMESTAMPTZ,

    -- 11_document_verification_audit.md §4
    CONSTRAINT dli_description_len CHECK (char_length(claim_item_description) >= 3),
    CONSTRAINT dli_qty_pos         CHECK (claimed_quantity > 0),
    CONSTRAINT dli_rate_nonneg     CHECK (claimed_unit_rate >= 0),
    CONSTRAINT dli_total_nonneg    CHECK (claimed_total >= 0),
    -- §11.2: audit_deduction_reason mandatory when audit_status != VERIFIED.
    -- PENDING_REVIEW is excluded: a line not yet audited has nothing to justify.
    CONSTRAINT dli_deduction_reason_required
        CHECK (audit_status IN ('VERIFIED','PENDING_REVIEW')
               OR (audit_deduction_reason IS NOT NULL
                   AND char_length(audit_deduction_reason) > 0))
);

CREATE UNIQUE INDEX uq_dli_line ON document_line_items (document_id, line_no) WHERE deleted_at IS NULL;
CREATE INDEX idx_dli_claim  ON document_line_items (store_id, claim_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_dli_status ON document_line_items (store_id, claim_id, audit_status)
    WHERE deleted_at IS NULL;
CREATE INDEX idx_dli_item   ON document_line_items (store_id, damage_item_id)
    WHERE deleted_at IS NULL AND damage_item_id IS NOT NULL;

CREATE TRIGGER trg_dli_updated_at
    BEFORE UPDATE ON document_line_items FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

The 20% rate-inflation threshold (AC 10.1.x) is **not** in the schema. `rate_variance_pct` is stored as a plain number and the threshold that turns it into `RATE_INFLATION_DETECTED` lives in the Stage 10 audit service, so a business rule that may be tuned per insurer never requires a migration.

---

## 28. `requisition_notices` (SRS entity 19) and `preliminary_survey_reports` `[ADDITION]` — Stage 8

```sql
CREATE TABLE requisition_notices (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id             UUID       NOT NULL REFERENCES claims(id) ON DELETE CASCADE,

    store_id             UUID       NOT NULL REFERENCES stores(id),
    client_id            UUID       NOT NULL REFERENCES users(id),
    assigned_surveyor_id UUID       REFERENCES users(id),
    reviewer_id          UUID       REFERENCES users(id),
    access_role_scope    role_scope NOT NULL DEFAULT 'SURVEYOR',

    ---- FR-8.1 ----------------------------------------------------------
    notice_no            SMALLINT         NOT NULL DEFAULT 1,   -- reminders are new notices
    peril_preset         peril_type       NOT NULL,
    required_docs_json   JSONB            NOT NULL,
    custom_requirements  TEXT,
    due_date             DATE             NOT NULL,
    dispatch_channel     dispatch_channel NOT NULL,
    recipient_name       VARCHAR(150),
    recipient_email      CITEXT,
    recipient_phone      VARCHAR(16),
    dispatch_status      dispatch_status  NOT NULL DEFAULT 'PENDING',
    dispatched_at        TIMESTAMPTZ,
    delivery_reference   VARCHAR(255),
    docx_document_id     UUID REFERENCES documents(id),   -- the generated .docx

    client_updated_at    TIMESTAMPTZ,
    field_updated_at     JSONB       NOT NULL DEFAULT '{}'::jsonb,
    sync_revision        BIGINT      NOT NULL DEFAULT 0,

    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at           TIMESTAMPTZ,

    -- 09_preliminary_survey_report_psr.md §4: at least 3 documents selected
    CONSTRAINT requisition_min_docs
        CHECK (jsonb_array_length(required_docs_json) >= 3),
    CONSTRAINT requisition_dispatched_when_sent
        CHECK (dispatch_status NOT IN ('SENT','DELIVERED') OR dispatched_at IS NOT NULL)
);

CREATE UNIQUE INDEX uq_requisition_no
    ON requisition_notices (claim_id, notice_no) WHERE deleted_at IS NULL;
CREATE INDEX idx_requisition_claim ON requisition_notices (store_id, claim_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_requisition_due   ON requisition_notices (store_id, due_date)
    WHERE deleted_at IS NULL AND dispatch_status IN ('SENT','DELIVERED');

CREATE TRIGGER trg_requisition_updated_at
    BEFORE UPDATE ON requisition_notices FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

**`required_docs_json`** — the peril-driven checklist from FR-8.1, with per-item receipt tracking so the Stage 10 locker and Stage 15 gate 5 can both read it:

```jsonc
[ { "doc_type": "CLAIM_BILL", "label": "Final claim bill with itemised annexure",
    "mandatory": true, "received": false, "received_document_id": null },
  { "doc_type": "FIR_POLICE_DIARY", "label": "Copy of FIR / Police station diary entry",
    "mandatory": true, "received": true, "received_document_id": "…uuid…" } ]
```

`jsonb_array_length` is safe as a `CHECK` here because the column is `NOT NULL` and always a JSON array; the constraint would raise on a non-array value, which is the intended behaviour.

### 28.1 `preliminary_survey_reports` `[ADDITION]`

FR-8.2 makes the PSR a distinct deliverable with its own `.docx` export and its own approval gate (`CLAUDE.md` §14 constraint 4 covers *"any PSR/FSR"*). Overloading `final_survey_reports` with a type discriminator would put the FSR's nine section columns permanently NULL on every PSR row and vice versa.

```sql
CREATE TABLE preliminary_survey_reports (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id             UUID       NOT NULL REFERENCES claims(id) ON DELETE CASCADE,

    store_id             UUID       NOT NULL REFERENCES stores(id),
    client_id            UUID       NOT NULL REFERENCES users(id),
    assigned_surveyor_id UUID       REFERENCES users(id),
    reviewer_id          UUID       REFERENCES users(id),
    access_role_scope    role_scope NOT NULL DEFAULT 'SURVEYOR',

    version_no           SMALLINT      NOT NULL DEFAULT 1,
    status               report_status NOT NULL DEFAULT 'DRAFT',

    ---- 09_preliminary_survey_report_psr.md §4 --------------------------
    psr_date_of_survey        DATE          NOT NULL,
    nature_and_cause_summary  TEXT,
    preliminary_observations  TEXT,
    preliminary_loss_reserve  NUMERIC(15,2) NOT NULL,
    psr_next_steps            TEXT          NOT NULL,
    pending_documents_json    JSONB         NOT NULL DEFAULT '[]'::jsonb,

    ---- FR-14.4 4-point Human Approval Gate (applies to PSR export too) --
    approval_reviewed_ai_at        TIMESTAMPTZ,
    approval_factual_accuracy_at   TIMESTAMPTZ,
    approval_calculations_at       TIMESTAMPTZ,
    approval_responsibility_at     TIMESTAMPTZ,
    approved_by_user_id            UUID REFERENCES users(id),

    ---- Export -----------------------------------------------------------
    docx_document_id     UUID REFERENCES documents(id),
    docx_sha256          CHAR(64),
    generated_at         TIMESTAMPTZ,
    generated_by_engine  VARCHAR(16),          -- 'client' | 'server' (D22 dual engine)

    client_updated_at    TIMESTAMPTZ,
    field_updated_at     JSONB       NOT NULL DEFAULT '{}'::jsonb,
    sync_revision        BIGINT      NOT NULL DEFAULT 0,

    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at           TIMESTAMPTZ,

    CONSTRAINT psr_reserve_positive   CHECK (preliminary_loss_reserve > 0),
    CONSTRAINT psr_next_steps_len     CHECK (char_length(psr_next_steps) >= 20),
    CONSTRAINT psr_engine_value       CHECK (generated_by_engine IS NULL
                                             OR generated_by_engine IN ('client','server')),
    CONSTRAINT psr_sha256_hex         CHECK (docx_sha256 IS NULL OR docx_sha256 ~ '^[0-9a-f]{64}$'),
    -- CLAUDE.md §14 constraint 4: no export without all four gate points.
    CONSTRAINT psr_gate_before_export
        CHECK (docx_document_id IS NULL OR (
                   approval_reviewed_ai_at      IS NOT NULL
               AND approval_factual_accuracy_at IS NOT NULL
               AND approval_calculations_at     IS NOT NULL
               AND approval_responsibility_at   IS NOT NULL
               AND approved_by_user_id          IS NOT NULL))
);

CREATE UNIQUE INDEX uq_psr_version ON preliminary_survey_reports (claim_id, version_no)
    WHERE deleted_at IS NULL;
CREATE INDEX idx_psr_claim ON preliminary_survey_reports (store_id, claim_id) WHERE deleted_at IS NULL;

CREATE TRIGGER trg_psr_updated_at
    BEFORE UPDATE ON preliminary_survey_reports FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

**`preliminary_loss_reserve` is `NOT NULL` and surveyor-entered.** FR-8.2 and `CLAUDE.md` §3 CR-W11 are explicit that AI never generates this figure. There is no AI-provenance column on it by design.

**The approval gate is four timestamps, not four booleans.** FR-14.4 requires the acceptance to be *timestamped and recorded in the immutable audit log* (FR-15.1 gate 7); a boolean cannot satisfy that, and the `CHECK` above makes an export physically impossible until all four are set.

---

## 29. `discrepancy_flags` `[ADDITION]` — cross-stage

The specs name discrepancy codes in six places (FR-4.3, FR-5.3, FR-10.2, FR-11.2, FR-15.1, AC 10.1.x) and then consume them in two more: FSR Section H is drafted from them (FR-14.2) and Stage 15 gate 6 scans them. They have no home entity in SRS §5.2.

```sql
CREATE TABLE discrepancy_flags (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id             UUID       NOT NULL REFERENCES claims(id) ON DELETE CASCADE,

    store_id             UUID       NOT NULL REFERENCES stores(id),
    client_id            UUID       NOT NULL REFERENCES users(id),
    assigned_surveyor_id UUID       REFERENCES users(id),
    reviewer_id          UUID       REFERENCES users(id),
    access_role_scope    role_scope NOT NULL DEFAULT 'SURVEYOR',

    code                 discrepancy_code     NOT NULL,
    severity             discrepancy_severity NOT NULL,
    status               discrepancy_status   NOT NULL DEFAULT 'OPEN',
    stage_raised         SMALLINT             NOT NULL,

    ---- What it points at (exactly one target, or none for claim-level) ---
    subject_entity       VARCHAR(40),          -- e.g. 'document_line_items'
    subject_id           UUID,

    title                VARCHAR(200) NOT NULL,
    detail               TEXT         NOT NULL,
    evidence_json        JSONB        NOT NULL DEFAULT '{}'::jsonb,
    detected_by          detected_by  NOT NULL,

    ---- Resolution --------------------------------------------------------
    resolution_remarks   TEXT,
    resolved_by_user_id  UUID        REFERENCES users(id),
    resolved_at          TIMESTAMPTZ,
    include_in_section_h BOOLEAN     NOT NULL DEFAULT TRUE,

    client_updated_at    TIMESTAMPTZ,
    field_updated_at     JSONB       NOT NULL DEFAULT '{}'::jsonb,
    sync_revision        BIGINT      NOT NULL DEFAULT 0,

    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at           TIMESTAMPTZ,

    CONSTRAINT discrepancy_stage_range CHECK (stage_raised BETWEEN 1 AND 15),
    CONSTRAINT discrepancy_subject_pair
        CHECK ((subject_entity IS NULL) = (subject_id IS NULL)),
    -- A flag may not be closed without a reason on the record.
    CONSTRAINT discrepancy_resolution_required
        CHECK (status = 'OPEN'
               OR (resolution_remarks IS NOT NULL AND char_length(resolution_remarks) > 0
                   AND resolved_by_user_id IS NOT NULL AND resolved_at IS NOT NULL))
);

CREATE INDEX idx_discrepancy_claim ON discrepancy_flags (store_id, claim_id, status)
    WHERE deleted_at IS NULL;
CREATE INDEX idx_discrepancy_open  ON discrepancy_flags (store_id, claim_id)
    WHERE deleted_at IS NULL AND status = 'OPEN' AND severity = 'CRITICAL';
CREATE INDEX idx_discrepancy_subject ON discrepancy_flags (subject_entity, subject_id)
    WHERE deleted_at IS NULL AND subject_id IS NOT NULL;

CREATE TRIGGER trg_discrepancy_updated_at
    BEFORE UPDATE ON discrepancy_flags FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

`subject_entity` / `subject_id` is a deliberately loose polymorphic reference with no foreign key: a flag can point at a line item, a damage item, a site visit or a whole claim, and a real FK per target would mean fifteen nullable columns. The pair is kept consistent by `discrepancy_subject_pair`, and orphan targets are tolerable because a flag remains meaningful as a historical finding even after its subject row is tombstoned.

**`detected_by = 'AI_ASSISTANT'` never closes a flag.** `CLAUDE.md` §14 constraint 2 requires an affirmative human action on every AI suggestion, so `resolved_by_user_id` is a `users` FK with no system-actor sentinel.

---

## 30. `assessment_heads` `[ADDITION]` and `assessment_line_items` (SRS entity 8) — Stage 11

This is the highest-risk correctness surface in the product (`CLAUDE.md` §17 recommendation 6). The schema is built so that the deterministic engine's inputs and outputs are all columns, and every one of them is auditable.

### 30.1 `assessment_heads` `[ADDITION]`

`12_loss_assessment_quantification.md` §2.2 organises the workspace as head-wise tabs and §3.1 places `ValueAtRiskInput` and `SumInsuredDisplay` at head level, above the grid. FR-11.2 step 6 then divides by SI per head. Storing VAR and SI on each line item would let two lines in the same head disagree about the sum insured, which is arithmetically impossible and would silently produce two different underinsurance factors.

```sql
CREATE TABLE assessment_heads (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id             UUID       NOT NULL REFERENCES claims(id) ON DELETE CASCADE,

    store_id             UUID       NOT NULL REFERENCES stores(id),
    client_id            UUID       NOT NULL REFERENCES users(id),
    assigned_surveyor_id UUID       REFERENCES users(id),
    reviewer_id          UUID       REFERENCES users(id),
    access_role_scope    role_scope NOT NULL DEFAULT 'SURVEYOR',

    head_category        head_category NOT NULL,

    ---- Underinsurance inputs (FR-11.2 step 6) --------------------------
    sum_insured          NUMERIC(15,2) NOT NULL,   -- rolled up from policy_sections (§21.1)
    value_at_risk        NUMERIC(15,2),            -- surveyor-entered sound value at loss
    underinsurance_applies BOOLEAN     NOT NULL DEFAULT FALSE,
    underinsurance_factor  NUMERIC(9,6),           -- 1 - SI/VAR, when VAR > SI
    underinsurance_basis   TEXT,                   -- how VAR was arrived at

    ---- Head subtotals (derived; stored so Section F is reproducible) -----
    total_claimed        NUMERIC(15,2) NOT NULL DEFAULT 0,
    total_gross_assessed NUMERIC(15,2) NOT NULL DEFAULT 0,
    total_depreciation   NUMERIC(15,2) NOT NULL DEFAULT 0,
    total_betterment     NUMERIC(15,2) NOT NULL DEFAULT 0,
    total_underinsurance NUMERIC(15,2) NOT NULL DEFAULT 0,
    total_salvage        NUMERIC(15,2) NOT NULL DEFAULT 0,
    total_excess         NUMERIC(15,2) NOT NULL DEFAULT 0,
    total_net_recommended NUMERIC(15,2) NOT NULL DEFAULT 0,

    client_updated_at    TIMESTAMPTZ,
    field_updated_at     JSONB       NOT NULL DEFAULT '{}'::jsonb,
    sync_revision        BIGINT      NOT NULL DEFAULT 0,

    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at           TIMESTAMPTZ,

    CONSTRAINT ah_si_nonneg   CHECK (sum_insured >= 0),
    CONSTRAINT ah_var_nonneg  CHECK (value_at_risk IS NULL OR value_at_risk >= 0),
    CONSTRAINT ah_factor_range
        CHECK (underinsurance_factor IS NULL OR underinsurance_factor BETWEEN 0 AND 1),
    -- FR-11.2 step 6: the deduction applies only when VAR > SI.
    CONSTRAINT ah_underinsurance_consistency
        CHECK (underinsurance_applies = FALSE
               OR (value_at_risk IS NOT NULL AND value_at_risk > sum_insured
                   AND underinsurance_factor IS NOT NULL))
);

CREATE UNIQUE INDEX uq_assessment_heads ON assessment_heads (claim_id, head_category)
    WHERE deleted_at IS NULL;
CREATE INDEX idx_assessment_heads_claim ON assessment_heads (store_id, claim_id)
    WHERE deleted_at IS NULL;

CREATE TRIGGER trg_assessment_heads_updated_at
    BEFORE UPDATE ON assessment_heads FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

Head subtotals are **stored, not computed on read**. FR-15.1 gate 1 requires Section F to reconcile to the rupee, and a report generated today must still reconcile when reopened after a line item is corrected — the audit compares the stored subtotal against a fresh sum and reports a mismatch rather than silently agreeing with itself.

### 30.2 `assessment_line_items`

```sql
CREATE TABLE assessment_line_items (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id             UUID       NOT NULL REFERENCES claims(id) ON DELETE CASCADE,
    assessment_head_id   UUID       NOT NULL REFERENCES assessment_heads(id) ON DELETE CASCADE,
    damage_item_id       UUID       REFERENCES damage_items(id),
    document_line_item_id UUID      REFERENCES document_line_items(id),

    store_id             UUID       NOT NULL REFERENCES stores(id),
    client_id            UUID       NOT NULL REFERENCES users(id),
    assigned_surveyor_id UUID       REFERENCES users(id),
    reviewer_id          UUID       REFERENCES users(id),
    access_role_scope    role_scope NOT NULL DEFAULT 'SURVEYOR',

    line_no              INTEGER       NOT NULL,     -- Sr. No. in the Section F table
    head_category        head_category NOT NULL,     -- denormalised from the head, for Section F
    description          TEXT          NOT NULL,

    ---- Inputs (FR-11.2 steps 1-4, 8, 9) ---------------------------------
    claimed_amount       NUMERIC(15,2) NOT NULL DEFAULT 0,
    assessed_quantity    NUMERIC(14,3),
    verified_unit_rate   NUMERIC(15,2),
    uom                  uom,
    depreciation_pct     NUMERIC(5,2)  NOT NULL DEFAULT 0,
    depreciation_basis   TEXT,                       -- age / asset class / scale used
    betterment_amount    NUMERIC(15,2) NOT NULL DEFAULT 0,
    salvage_amount       NUMERIC(15,2) NOT NULL DEFAULT 0,   -- fed from salvage_records (§31)
    excess_deduction     NUMERIC(15,2) NOT NULL DEFAULT 0,

    ---- Derived, in FR-11.2 order (stored, never recomputed on read) ------
    assessed_gross           NUMERIC(15,2) NOT NULL DEFAULT 0,  -- 2. qty x rate
    depreciation_amount      NUMERIC(15,2) NOT NULL DEFAULT 0,  -- 3. gross x pct/100
    net_of_depreciation      NUMERIC(15,2) NOT NULL DEFAULT 0,  -- 5. gross - depr - betterment
    underinsurance_deduction NUMERIC(15,2) NOT NULL DEFAULT 0,  -- 6. netOfDepr x factor
    after_underinsurance     NUMERIC(15,2) NOT NULL DEFAULT 0,  -- 7.
    net_recommended          NUMERIC(15,2) NOT NULL DEFAULT 0,  -- 10.

    justification_remarks TEXT,

    client_updated_at    TIMESTAMPTZ,
    field_updated_at     JSONB       NOT NULL DEFAULT '{}'::jsonb,
    sync_revision        BIGINT      NOT NULL DEFAULT 0,

    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at           TIMESTAMPTZ,

    ---- Field validations (12_loss_assessment_quantification.md §5) -------
    CONSTRAINT ali_desc_len        CHECK (char_length(description) >= 3),
    CONSTRAINT ali_claimed_nonneg  CHECK (claimed_amount    >= 0),
    CONSTRAINT ali_gross_nonneg    CHECK (assessed_gross    >= 0),
    CONSTRAINT ali_gross_le_claimed CHECK (assessed_gross <= claimed_amount),
    CONSTRAINT ali_depr_pct_range  CHECK (depreciation_pct BETWEEN 0 AND 90),
    CONSTRAINT ali_betterment_nonneg CHECK (betterment_amount        >= 0),
    CONSTRAINT ali_salvage_nonneg    CHECK (salvage_amount           >= 0),
    CONSTRAINT ali_excess_nonneg     CHECK (excess_deduction         >= 0),
    CONSTRAINT ali_underins_nonneg   CHECK (underinsurance_deduction >= 0),
    CONSTRAINT ali_qty_pos           CHECK (assessed_quantity  IS NULL OR assessed_quantity  > 0),
    CONSTRAINT ali_rate_nonneg       CHECK (verified_unit_rate IS NULL OR verified_unit_rate >= 0),

    ---- The FR-11.2 chain, asserted in the database (§14 constraint 5) ----
    CONSTRAINT ali_math_gross
        CHECK (assessed_quantity IS NULL OR verified_unit_rate IS NULL
               OR assessed_gross = ROUND(assessed_quantity * verified_unit_rate, 2)),
    CONSTRAINT ali_math_depreciation
        CHECK (depreciation_amount = ROUND(assessed_gross * depreciation_pct / 100, 2)),
    CONSTRAINT ali_math_net_of_depreciation
        CHECK (net_of_depreciation = assessed_gross - depreciation_amount - betterment_amount),
    CONSTRAINT ali_math_after_underinsurance
        CHECK (after_underinsurance = net_of_depreciation - underinsurance_deduction),
    CONSTRAINT ali_math_net_recommended
        CHECK (net_recommended = after_underinsurance - salvage_amount - excess_deduction),

    ---- §11.1 / AC 11.1.5: mandatory justification on any deduction -------
    CONSTRAINT ali_justification_required
        CHECK ((assessed_gross >= claimed_amount
                AND depreciation_amount = 0 AND betterment_amount = 0
                AND underinsurance_deduction = 0 AND salvage_amount = 0
                AND excess_deduction = 0)
               OR (justification_remarks IS NOT NULL
                   AND char_length(justification_remarks) > 0))
);

CREATE UNIQUE INDEX uq_ali_line ON assessment_line_items (claim_id, line_no) WHERE deleted_at IS NULL;
CREATE INDEX idx_ali_head  ON assessment_line_items (store_id, assessment_head_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_ali_claim ON assessment_line_items (store_id, claim_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_ali_item  ON assessment_line_items (store_id, damage_item_id)
    WHERE deleted_at IS NULL AND damage_item_id IS NOT NULL;

CREATE TRIGGER trg_ali_updated_at
    BEFORE UPDATE ON assessment_line_items FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

**The arithmetic chain is enforced by `CHECK` constraints, not just by the Go engine.** `CLAUDE.md` §14 constraint 5 makes this the one place where duplication is worth it: the same formula is implemented in the mobile TypeScript engine (offline), the Go service (online) and the `.docx` generator, and the database is the only component all three write through. A row that violates the chain is rejected regardless of which engine produced it. `ROUND(…, 2)` is applied inside the constraint so the rule matches what `NUMERIC(15,2)` storage will hold, and the resulting value is what Section F prints — this is the "reconciles to the rupee" guarantee.

`underinsurance_deduction` is **not** in a `CHECK` against `assessment_heads.underinsurance_factor`, because a row-level constraint cannot read the parent row. It is asserted by the Stage 11 service and re-verified by Stage 15 gate 1.

**`ali_justification_required` fires on any deduction, not only a rate cut.** `12_loss_assessment_quantification.md` §5 words the trigger narrowly as `gross_assessed < claimed`, but FR-11.3 and AC 11.1.5 require a remark for "every rate reduction, depreciation rate, betterment, salvage figure, or disallowed claim item". The constraint follows the SRS, which is the wider and authoritative rule.

**Policy excess is stored per line item.** SRS entity 8 (`excess_deduction`), FR-11.2 step 9 and `12_loss_assessment_quantification.md` §5 (`policy_excess`) all place it on the line; only the screen's §3 component list shows a single claim-level `PolicyExcessDeductionInput`. Three sources against one, so it is a line-level column and the claim-level input is a distribution UI over it. Flagged in §38 item 5 for confirmation.

---

## 31. `salvage_records` — SRS entity 9 (Stage 12)

```sql
CREATE TABLE salvage_records (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id             UUID       NOT NULL REFERENCES claims(id) ON DELETE CASCADE,
    damage_item_id       UUID       REFERENCES damage_items(id),
    assessment_line_item_id UUID    REFERENCES assessment_line_items(id),  -- FR-12.3 feed

    store_id             UUID       NOT NULL REFERENCES stores(id),
    client_id            UUID       NOT NULL REFERENCES users(id),
    assigned_surveyor_id UUID       REFERENCES users(id),
    reviewer_id          UUID       REFERENCES users(id),
    access_role_scope    role_scope NOT NULL DEFAULT 'SURVEYOR',

    ---- FR-12.1 ----------------------------------------------------------
    description          TEXT          NOT NULL,
    qty_weight           NUMERIC(14,3) NOT NULL,
    uom                  uom           NOT NULL,
    condition_notes      TEXT,
    storage_location     VARCHAR(200),
    head_category        head_category NOT NULL,

    ---- FR-12.2 modes A / B / C (D29) ------------------------------------
    disposal_mode        disposal_mode NOT NULL,

    -- Mode A: retained by insured
    agreed_value         NUMERIC(15,2),
    insured_consent_at   TIMESTAMPTZ,
    insured_consent_document_id UUID REFERENCES documents(id),

    -- Mode B: sold to scrap buyer
    buyer_name           VARCHAR(200),
    buyer_contact        VARCHAR(160),
    buyer_gstin          VARCHAR(20),
    quote_amount         NUMERIC(15,2),
    sale_invoice_document_id UUID REFERENCES documents(id),
    delivery_confirmed_at    TIMESTAMPTZ,

    -- Mode C: tender floated by insurer
    tender_reference     VARCHAR(80),
    tender_bids_json     JSONB,
    highest_bidder_name  VARCHAR(200),

    -- Modes B and C
    payment_proof_document_id UUID REFERENCES documents(id),
    payment_received_at       TIMESTAMPTZ,

    ---- Outcome -----------------------------------------------------------
    realized_amount      NUMERIC(15,2) NOT NULL DEFAULT 0,
    surveyor_remarks     TEXT,

    client_updated_at    TIMESTAMPTZ,
    field_updated_at     JSONB       NOT NULL DEFAULT '{}'::jsonb,
    sync_revision        BIGINT      NOT NULL DEFAULT 0,

    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at           TIMESTAMPTZ,

    -- 13_salvage_disposal_manager.md §4
    CONSTRAINT salvage_desc_len       CHECK (char_length(description) >= 5),
    CONSTRAINT salvage_qty_pos        CHECK (qty_weight > 0),
    CONSTRAINT salvage_realized_nonneg CHECK (realized_amount >= 0),
    CONSTRAINT salvage_agreed_nonneg   CHECK (agreed_value IS NULL OR agreed_value >= 0),
    CONSTRAINT salvage_quote_nonneg    CHECK (quote_amount IS NULL OR quote_amount >= 0),

    -- Mode A requires the insured's agreed value and recorded consent (FR-12.2 A)
    CONSTRAINT salvage_mode_a_complete
        CHECK (disposal_mode <> 'RETAINED_BY_INSURED'
               OR (agreed_value IS NOT NULL AND insured_consent_at IS NOT NULL)),
    -- Mode B requires buyer identity and payment proof (FR-12.2 B, screen §4)
    CONSTRAINT salvage_mode_b_complete
        CHECK (disposal_mode <> 'SOLD_TO_SCRAP_BUYER'
               OR (buyer_name IS NOT NULL AND char_length(buyer_name) >= 3
                   AND payment_proof_document_id IS NOT NULL)),
    -- Mode C requires the tender record, the winning bidder and payment proof (FR-12.2 C)
    CONSTRAINT salvage_mode_c_complete
        CHECK (disposal_mode <> 'INSURER_TENDER'
               OR (tender_reference IS NOT NULL AND highest_bidder_name IS NOT NULL
                   AND payment_proof_document_id IS NOT NULL))
);

CREATE INDEX idx_salvage_claim ON salvage_records (store_id, claim_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_salvage_line  ON salvage_records (store_id, assessment_line_item_id)
    WHERE deleted_at IS NULL AND assessment_line_item_id IS NOT NULL;

CREATE TRIGGER trg_salvage_updated_at
    BEFORE UPDATE ON salvage_records FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

**`tender_bids_json`** (FR-12.2 Mode C):

```jsonc
[ { "bidder_name": "Shree Metal Traders", "bid_amount": 412000.00,
    "bid_date": "2026-04-11", "contact": "+919812345678", "selected": true } ]
```

**Modes B and C are enforced structurally; the `.docx` of the proof is not.** The three `salvage_mode_*_complete` constraints make an incomplete disposal record impossible to save, which is what `13_salvage_disposal_manager.md` §4 asks for. What the constraint cannot check is that the referenced `documents` row is actually a payment receipt rather than a blank page — that remains a surveyor judgement, as it should.

FR-12.3 feeds `realized_amount` into `assessment_line_items.salvage_amount`. The link is `assessment_line_item_id`; where several salvage records attach to one line, the Stage 12 service writes their sum. It is a service-side aggregation rather than a generated column because a salvage record can be created before its assessment line exists.

---

## 32. `coverage_opinions` — SRS entity 18 (Stage 13)

```sql
CREATE TABLE coverage_opinions (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id             UUID       NOT NULL REFERENCES claims(id) ON DELETE CASCADE,

    store_id             UUID       NOT NULL REFERENCES stores(id),
    client_id            UUID       NOT NULL REFERENCES users(id),
    assigned_surveyor_id UUID       REFERENCES users(id),
    reviewer_id          UUID       REFERENCES users(id),
    access_role_scope    role_scope NOT NULL DEFAULT 'SURVEYOR',

    ---- FR-13.1 -----------------------------------------------------------
    operative_peril            peril_type          NOT NULL,
    operative_peril_status     peril_admissibility NOT NULL,
    peril_justification        TEXT                NOT NULL,
    warranty_compliance_status warranty_compliance_status NOT NULL,
    warranty_compliance_json   JSONB   NOT NULL DEFAULT '[]'::jsonb,
    breach_details             TEXT,
    exclusions_json            JSONB   NOT NULL DEFAULT '[]'::jsonb,
    material_facts             TEXT,

    ---- FR-13.2 -----------------------------------------------------------
    surveyor_recommendation surveyor_recommendation NOT NULL,
    surveyor_opinion_text   TEXT                    NOT NULL,
    -- FR-13.2 requires this exact notice on every coverage remark. Stored per row,
    -- with its version, so a wording change never rewrites what was signed off.
    decision_support_notice TEXT NOT NULL DEFAULT
        'Decision-support analysis for surveyor review. Final liability determination remains with the insurer.',
    notice_version          VARCHAR(16) NOT NULL DEFAULT 'v1',
    without_prejudice_declaration TEXT NOT NULL,

    client_updated_at    TIMESTAMPTZ,
    field_updated_at     JSONB       NOT NULL DEFAULT '{}'::jsonb,
    sync_revision        BIGINT      NOT NULL DEFAULT 0,

    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at           TIMESTAMPTZ,

    -- 14_coverage_liability_opinion.md §4
    CONSTRAINT coverage_peril_just_len  CHECK (char_length(peril_justification)  >= 30),
    CONSTRAINT coverage_opinion_len     CHECK (char_length(surveyor_opinion_text) >= 50),
    CONSTRAINT coverage_breach_required
        CHECK (warranty_compliance_status <> 'Material Breach'
               OR (breach_details IS NOT NULL AND char_length(breach_details) > 0)),
    -- CLAUDE.md §14 constraint 14: the notice may not be blanked out.
    CONSTRAINT coverage_notice_present   CHECK (char_length(decision_support_notice) > 0),
    CONSTRAINT coverage_wp_present       CHECK (char_length(without_prejudice_declaration) > 0)
);

CREATE UNIQUE INDEX uq_coverage_claim ON coverage_opinions (claim_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_coverage_store ON coverage_opinions (store_id, claim_id) WHERE deleted_at IS NULL;

CREATE TRIGGER trg_coverage_updated_at
    BEFORE UPDATE ON coverage_opinions FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

**JSONB payload shapes:**

```jsonc
// warranty_compliance_json — one entry per warranty in policy_details.warranties_json
[ { "code": "FEA_WARRANTY", "title": "Fire Extinguishing Appliances Warranty",
    "status": "Complied", "evidence": "Six 9 kg ABC extinguishers, serviced 2026-01-18",
    "evidence_document_ids": ["…uuid…"] } ]

// exclusions_json — FR-13.1
[ { "clause_reference": "Exclusion 4(b)", "title": "Wear, tear and gradual deterioration",
    "applies": false, "reasoning": "..." } ]
```

**Three columns exist purely to satisfy §14 constraint 14.** `decision_support_notice`, `notice_version` and `without_prejudice_declaration` are stored on the row rather than injected at render time, so that a future edit to the standard wording cannot retroactively change the text a surveyor signed. `NOT NULL` plus a non-empty `CHECK` makes removal a database error, not a template oversight.

**There is no AI-authored column here.** FR-13.1 forbids autonomous coverage determination, so `surveyor_recommendation` has no AI-provenance field and no confidence score — an AI draft of the *narrative* lives in the FSR Section I workflow (§33), where it is explicitly marked as a draft awaiting human acceptance.

---

## 33. `final_survey_reports` — SRS entity 10 (Stage 14, signed off at Stage 15)

```sql
CREATE TABLE final_survey_reports (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id             UUID       NOT NULL REFERENCES claims(id) ON DELETE CASCADE,

    store_id             UUID       NOT NULL REFERENCES stores(id),
    client_id            UUID       NOT NULL REFERENCES users(id),
    assigned_surveyor_id UUID       REFERENCES users(id),
    reviewer_id          UUID       REFERENCES users(id),
    access_role_scope    role_scope NOT NULL DEFAULT 'SURVEYOR',

    version_no           SMALLINT      NOT NULL DEFAULT 1,
    status               report_status NOT NULL DEFAULT 'DRAFT',

    ---- FR-14.1 nine sections. Identity and order are fixed (§14 constraint 12).
    section_a_json       JSONB NOT NULL DEFAULT '{}'::jsonb,  -- Basic claim & appointment info
    section_b_json       JSONB NOT NULL DEFAULT '{}'::jsonb,  -- Risk, premises, business activity
    section_c_json       JSONB NOT NULL DEFAULT '{}'::jsonb,  -- Cause & circumstances   [AI-4]
    section_d_json       JSONB NOT NULL DEFAULT '{}'::jsonb,  -- Physical survey findings [AI-4]
    section_e_json       JSONB NOT NULL DEFAULT '{}'::jsonb,  -- Documents considered
    section_f_json       JSONB NOT NULL DEFAULT '{}'::jsonb,  -- Loss assessment statement
    section_g_json       JSONB NOT NULL DEFAULT '{}'::jsonb,  -- Policy terms & warranties
    section_h_json       JSONB NOT NULL DEFAULT '{}'::jsonb,  -- Discrepancies            [AI-4]
    section_i_json       JSONB NOT NULL DEFAULT '{}'::jsonb,  -- Opinion & recommendation [AI-4]
    annexure_json        JSONB NOT NULL DEFAULT '{}'::jsonb,  -- Photo plates

    ---- Headline figures, denormalised for the dashboard and the audit ----
    total_claimed        NUMERIC(15,2),
    total_gross_assessed NUMERIC(15,2),
    total_deductions     NUMERIC(15,2),
    net_recommended      NUMERIC(15,2),

    ---- FR-14.4 4-point Human Approval Gate -------------------------------
    approval_reviewed_ai_at      TIMESTAMPTZ,
    approval_factual_accuracy_at TIMESTAMPTZ,
    approval_calculations_at     TIMESTAMPTZ,
    approval_responsibility_at   TIMESTAMPTZ,
    approved_by_user_id          UUID REFERENCES users(id),

    ---- FR-14.3 export ----------------------------------------------------
    docx_document_id     UUID REFERENCES documents(id),
    docx_file_uri        TEXT,
    docx_sha256          CHAR(64),
    generated_at         TIMESTAMPTZ,
    generated_by_engine  VARCHAR(16),          -- 'client' | 'server' (D22)

    ---- FR-15.2 sign-off and immutable snapshot ---------------------------
    audit_passed          BOOLEAN     NOT NULL DEFAULT FALSE,
    surveyor_signature_media_id UUID  REFERENCES media_attachments(id),
    declaration_accepted_at TIMESTAMPTZ,
    signed_off_by_user_id UUID        REFERENCES users(id),
    signed_off_at         TIMESTAMPTZ,
    -- SLA fields copied at sign-off: D35 requires them present on the FSR block,
    -- and the report must not change if the user later edits their profile.
    signoff_sla_license_no VARCHAR(32),
    signoff_sla_category   sla_category,
    snapshot_sha256        CHAR(64),
    snapshot_taken_at      TIMESTAMPTZ,

    client_updated_at    TIMESTAMPTZ,
    field_updated_at     JSONB       NOT NULL DEFAULT '{}'::jsonb,
    sync_revision        BIGINT      NOT NULL DEFAULT 0,

    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at           TIMESTAMPTZ,

    CONSTRAINT fsr_engine_value CHECK (generated_by_engine IS NULL
                                       OR generated_by_engine IN ('client','server')),
    CONSTRAINT fsr_docx_sha_hex CHECK (docx_sha256 IS NULL OR docx_sha256 ~ '^[0-9a-f]{64}$'),
    CONSTRAINT fsr_snap_sha_hex CHECK (snapshot_sha256 IS NULL OR snapshot_sha256 ~ '^[0-9a-f]{64}$'),

    -- CLAUDE.md §14 constraint 4 / FR-14.4: no .docx without all four gate points.
    CONSTRAINT fsr_gate_before_export
        CHECK (docx_document_id IS NULL OR (
                   approval_reviewed_ai_at      IS NOT NULL
               AND approval_factual_accuracy_at IS NOT NULL
               AND approval_calculations_at     IS NOT NULL
               AND approval_responsibility_at   IS NOT NULL
               AND approved_by_user_id          IS NOT NULL)),

    -- FR-15.1 / FR-15.2: submission requires a passed audit, a signature, the
    -- declaration, the licence block (D35) and the immutable hash.
    CONSTRAINT fsr_signoff_complete
        CHECK (status <> 'SUBMITTED' OR (
                   audit_passed = TRUE
               AND surveyor_signature_media_id IS NOT NULL
               AND declaration_accepted_at IS NOT NULL
               AND signed_off_by_user_id   IS NOT NULL
               AND signed_off_at           IS NOT NULL
               AND signoff_sla_license_no  IS NOT NULL
               AND signoff_sla_category    IS NOT NULL
               AND snapshot_sha256         IS NOT NULL))
);

CREATE UNIQUE INDEX uq_fsr_version ON final_survey_reports (claim_id, version_no)
    WHERE deleted_at IS NULL;
CREATE INDEX idx_fsr_claim  ON final_survey_reports (store_id, claim_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_fsr_status ON final_survey_reports (store_id, status)   WHERE deleted_at IS NULL;

CREATE TRIGGER trg_fsr_updated_at
    BEFORE UPDATE ON final_survey_reports FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

**`fsr_signoff_complete` is where D35 becomes enforceable.** The FSR licence gate ("optional at signup, required before FSR") could not be a `NOT NULL` on `users` (Part A §6.4). Here it can be: the licence number and category are copied onto the report at sign-off and a `SUBMITTED` row without them is a database error. Copying rather than joining also means a later profile edit cannot alter a submitted report.

**Section JSONB shape.** Every section shares one envelope so the `.docx` engines (client and server, D22) consume a single structure — this is the shared template contract of `CLAUDE.md` §14 constraint 16:

```jsonc
{
  "title": "Cause and Circumstances of Loss",
  "blocks": [
    { "type": "paragraph",
      "text": "During our physical inspection on site on 03 March 2026, ...",
      "source": "AI_DRAFT",              // AI_DRAFT | SURVEYOR | SYSTEM
      "accepted_by_user_id": "…uuid…",   // required before export when source = AI_DRAFT
      "accepted_at": "2026-04-02T11:20:31+05:30",
      "edited": true,
      "placeholders": []                 // e.g. ["[SURVEYOR TO VERIFY]"]
    },
    { "type": "table", "table_id": "section_f_headwise", "rows": [ /* … */ ] }
  ],
  "generated_at": "2026-04-02T10:55:00+05:30",
  "ai_module": "AI-4"
}
```

`source`, `accepted_by_user_id` and `placeholders` are what make `CLAUDE.md` §14 constraints 2 and 3 checkable: Stage 15 gate 7 rejects a report containing an `AI_DRAFT` block with no `accepted_by_user_id`, and gate 6 reports any block whose `placeholders` array still contains `[SURVEYOR TO VERIFY]`. AI drafting is confined to sections C, D, H and I (FR-14.2); a block with `"source": "AI_DRAFT"` in any other section is itself an audit failure.

---

## 34. `pre_submission_audits` and `report_dispatches` `[ADDITION]` — Stage 15

FR-15.1 defines seven gates that must all pass before submission is enabled, and the surveyor re-runs them after each fix. That is a run with results, not a boolean — `16_internal_review_submission.md` §4's `audit_pass_status` is the *outcome* of the latest run, held on `final_survey_reports.audit_passed`.

```sql
CREATE TABLE pre_submission_audits (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id             UUID       NOT NULL REFERENCES claims(id) ON DELETE CASCADE,
    final_survey_report_id UUID     NOT NULL REFERENCES final_survey_reports(id) ON DELETE CASCADE,

    store_id             UUID       NOT NULL REFERENCES stores(id),
    client_id            UUID       NOT NULL REFERENCES users(id),
    assigned_surveyor_id UUID       REFERENCES users(id),
    reviewer_id          UUID       REFERENCES users(id),
    access_role_scope    role_scope NOT NULL DEFAULT 'SURVEYOR',

    run_no               INTEGER     NOT NULL,
    run_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    run_by_user_id       UUID        NOT NULL REFERENCES users(id),
    overall_result       audit_gate_result NOT NULL,
    gates_json           JSONB       NOT NULL,
    duration_ms          INTEGER,

    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- D36 / FR-15.1: exactly seven gates, never six.
    CONSTRAINT audit_seven_gates CHECK (jsonb_array_length(gates_json) = 7),
    CONSTRAINT audit_run_no_pos  CHECK (run_no >= 1)
);

CREATE UNIQUE INDEX uq_audit_run ON pre_submission_audits (final_survey_report_id, run_no);
CREATE INDEX idx_audit_claim ON pre_submission_audits (store_id, claim_id, run_at DESC);
```

`pre_submission_audits` is append-only by construction: it carries `created_at` but neither `updated_at` nor `deleted_at`, and has no trigger. A superseded run stays on the record — the history of what failed and when is part of the evidence that the gates were actually applied.

**`gates_json`** — one entry per gate, in the FR-15.1 order fixed by `audit_gate_code`:

```jsonc
[ { "code": "ARITHMETIC_CHECK", "result": "PASS", "detail": null, "flag_ids": [] },
  { "code": "METADATA_CONSISTENCY", "result": "FAIL",
    "detail": "Date of loss in Section C (02-03-2026) differs from Section A (03-03-2026).",
    "flag_ids": ["…discrepancy_flags uuid…"] },
  { "code": "DEDUCTION_REMARKS",           "result": "PASS", "detail": null, "flag_ids": [] },
  { "code": "PHOTO_ANNEXURE_COMPLIANCE",   "result": "PASS", "detail": null, "flag_ids": [] },
  { "code": "DOCUMENT_COMPLETENESS",       "result": "PASS", "detail": null, "flag_ids": [] },
  { "code": "CONTRADICTION_SCANNER",       "result": "PASS", "detail": null, "flag_ids": [] },
  { "code": "HUMAN_APPROVAL_AI_GATE",      "result": "PASS", "detail": null, "flag_ids": [] } ]
```

```sql
CREATE TABLE report_dispatches (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    claim_id             UUID       NOT NULL REFERENCES claims(id) ON DELETE CASCADE,
    final_survey_report_id UUID     NOT NULL REFERENCES final_survey_reports(id),

    store_id             UUID       NOT NULL REFERENCES stores(id),
    client_id            UUID       NOT NULL REFERENCES users(id),
    assigned_surveyor_id UUID       REFERENCES users(id),
    reviewer_id          UUID       REFERENCES users(id),
    access_role_scope    role_scope NOT NULL DEFAULT 'SURVEYOR',

    ---- 16_internal_review_submission.md §4 ------------------------------
    submission_date      DATE             NOT NULL DEFAULT CURRENT_DATE,
    submission_channel   dispatch_channel NOT NULL,
    recipient_email      CITEXT,
    recipient_name       VARCHAR(200),
    portal_reference     VARCHAR(120),
    courier_awb          VARCHAR(80),
    cover_note           TEXT,                  -- AI-4 dispatch email draft, surveyor-edited
    dispatch_status      dispatch_status  NOT NULL DEFAULT 'PENDING',
    dispatched_at        TIMESTAMPTZ,
    delivery_reference   VARCHAR(255),
    failure_reason       TEXT,
    acknowledged_at      TIMESTAMPTZ,

    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT dispatch_email_recipient
        CHECK (submission_channel <> 'EMAIL' OR recipient_email IS NOT NULL),
    CONSTRAINT dispatch_portal_reference
        CHECK (submission_channel <> 'INSURER_PORTAL' OR portal_reference IS NOT NULL),
    CONSTRAINT dispatch_sent_timestamp
        CHECK (dispatch_status NOT IN ('SENT','DELIVERED') OR dispatched_at IS NOT NULL)
);

CREATE INDEX idx_dispatch_report ON report_dispatches (store_id, final_survey_report_id);
CREATE INDEX idx_dispatch_claim  ON report_dispatches (store_id, claim_id, submission_date DESC);

CREATE TRIGGER trg_dispatch_updated_at
    BEFORE UPDATE ON report_dispatches FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

`report_dispatches` is a log with many rows per report — FR-15.2 requires *dispatch tracking*, and a report is routinely emailed to the claims desk and then uploaded to the insurer portal. It is not synced (submission happens online), so it carries no sync columns and no `deleted_at`.

---

## 35. `audit_log` — SRS entity 14

Immutable, append-only, and deliberately **separate from `auth_events`** (Part A §10.1): different shape, different cardinality, different audience. `auth_events` answers "who signed in"; `audit_log` answers "who changed this figure, and from what".

```sql
CREATE TABLE audit_log (
    id                  BIGSERIAL PRIMARY KEY,

    store_id            UUID         NOT NULL REFERENCES stores(id),
    claim_id            UUID         REFERENCES claims(id),
    actor_user_id       UUID         REFERENCES users(id),
    actor_role_scope    role_scope,
    session_id          UUID         REFERENCES sessions(id),

    entity              VARCHAR(64)  NOT NULL,     -- table name
    entity_id           UUID         NOT NULL,
    field               VARCHAR(64),               -- NULL for whole-row CREATE / VIEW / DOWNLOAD
    old_value           TEXT,
    new_value           TEXT,
    action              audit_action NOT NULL,

    ---- Context ----------------------------------------------------------
    stage               SMALLINT,
    reason              TEXT,                      -- e.g. the justification remark supplied
    ip_address          INET,
    user_agent          TEXT,
    device_id           VARCHAR(128),
    request_id          VARCHAR(64),               -- correlates with the RequestID middleware
    is_offline_origin   BOOLEAN      NOT NULL DEFAULT FALSE,
    client_occurred_at  TIMESTAMPTZ,               -- device clock, when the edit was made offline
    occurred_at         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT audit_log_stage_range CHECK (stage IS NULL OR stage BETWEEN 1 AND 15)
);

CREATE INDEX idx_audit_log_claim   ON audit_log (store_id, claim_id, occurred_at DESC);
CREATE INDEX idx_audit_log_entity  ON audit_log (entity, entity_id, occurred_at DESC);
CREATE INDEX idx_audit_log_actor   ON audit_log (store_id, actor_user_id, occurred_at DESC);
-- SRS §5.1 governance rule 3: every insurer view/download must be retrievable.
CREATE INDEX idx_audit_log_access  ON audit_log (store_id, claim_id, occurred_at DESC)
    WHERE action IN ('VIEW','DOWNLOAD','EXPORT');

-- Immutability, by trigger AND by privilege — the same belt-and-braces as auth_events.
CREATE TRIGGER trg_audit_log_append_only
    BEFORE UPDATE OR DELETE ON audit_log
    FOR EACH ROW EXECUTE FUNCTION reject_mutation();

REVOKE UPDATE, DELETE, TRUNCATE ON audit_log FROM PUBLIC;
-- The application role receives INSERT and SELECT only:
-- GRANT INSERT, SELECT ON audit_log TO survscribe_app;
```

**Scope of what must be logged** (`CLAUDE.md` §14 constraint 10, SRS §5.1 rule 3, SRS §6.2):

| Trigger | `entity` / `action` |
| :-- | :-- |
| Any change to a loss-assessment figure | `assessment_line_items` / `assessment_heads`, `UPDATE`, with `field`, `old_value`, `new_value` |
| Any insurer view or download of a claim file | `claims` / `documents` / `final_survey_reports`, `VIEW` / `DOWNLOAD` |
| The four approval-gate acceptances | `final_survey_reports`, `APPROVE` (FR-15.1 gate 7) |
| Stage 15 sign-off and dispatch | `final_survey_reports`, `SIGN_OFF` / `SUBMIT` |
| Salvage realisation, depreciation percentage, excess | the owning table, `UPDATE` |

`old_value` / `new_value` are `TEXT` rather than typed columns because the log spans every table; the reader casts using `entity` + `field`. `is_offline_origin` and `client_occurred_at` exist because an edit made in the field is logged on the device and replayed at sync — without them, every offline edit would appear to have happened at the moment of reconnection.

---

## 36. `sync_queue` — SRS entity 15

The device-side outbox. It is the one table that is **not** itself synced.

```sql
CREATE TABLE sync_queue (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    store_id            UUID           NOT NULL REFERENCES stores(id),
    client_id           UUID           NOT NULL REFERENCES users(id),
    device_id           VARCHAR(128)   NOT NULL,

    entity              VARCHAR(64)    NOT NULL,
    entity_local_id     UUID           NOT NULL,   -- the client-generated UUIDv4 (§18)
    claim_id            UUID,                      -- no FK: the claim may not exist server-side yet
    operation           sync_operation NOT NULL,
    payload_json        JSONB          NOT NULL,
    field_updated_at    JSONB          NOT NULL DEFAULT '{}'::jsonb,
    media_refs          JSONB          NOT NULL DEFAULT '[]'::jsonb,
    base_sync_revision  BIGINT,                    -- revision the edit was made against

    ---- Delivery (§6.1 exponential backoff) ------------------------------
    status              sync_status    NOT NULL DEFAULT 'PENDING',
    attempt_count       INTEGER        NOT NULL DEFAULT 0,
    next_retry_at       TIMESTAMPTZ,
    last_attempt_at     TIMESTAMPTZ,
    last_error          TEXT,

    ---- Conflict (AC 16.1.3) ---------------------------------------------
    conflict_flag       BOOLEAN        NOT NULL DEFAULT FALSE,
    conflict_fields     JSONB,                     -- per-field local vs server values
    conflict_resolved_at    TIMESTAMPTZ,
    conflict_resolved_by_user_id UUID REFERENCES users(id),

    enqueued_at         TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    completed_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ    NOT NULL DEFAULT NOW(),

    CONSTRAINT sync_attempts_nonneg CHECK (attempt_count >= 0),
    -- A conflict is not cleared without a recorded human decision (AC 16.1.3).
    CONSTRAINT sync_conflict_resolution
        CHECK (conflict_flag = FALSE OR conflict_resolved_at IS NULL
               OR conflict_resolved_by_user_id IS NOT NULL)
);

CREATE INDEX idx_sync_queue_pending  ON sync_queue (store_id, device_id, next_retry_at)
    WHERE status IN ('PENDING','FAILED');
CREATE INDEX idx_sync_queue_conflict ON sync_queue (store_id, client_id)
    WHERE conflict_flag = TRUE AND conflict_resolved_at IS NULL;
CREATE INDEX idx_sync_queue_entity   ON sync_queue (entity, entity_local_id);

CREATE TRIGGER trg_sync_queue_updated_at
    BEFORE UPDATE ON sync_queue FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

**`conflict_fields`** — the payload behind AC 16.1.3's "surveyor confirmation on concurrent edits". It is field-level, not row-level, which is the whole point of `CLAUDE.md` §14 constraint 8:

```jsonc
{ "depreciation_pct": { "local": 25.00, "server": 20.00,
                        "local_at": "2026-04-02T09:12:00+05:30",
                        "server_at": "2026-04-02T09:40:11+05:30" } }
```

**This table is a mirror, not the source of truth.** The authoritative outbox is the WatermelonDB/SQLCipher copy on the device (D20); the server-side table exists so a support engineer can see what a device is stuck on and so `sprint_0005` has somewhere to record conflicts that the surveyor has not yet resolved. **The whole table is provisional** — `sprint_0002` owns the sync protocol and may reshape it. Flagged in §38 item 1.

---

## 37. Entity relationship summary (Part B)

```
claims 1 ──1 policy_details 1 ──< policy_sections
claims 1 ──< contact_logs
claims 1 ──< preservation_notices
claims 1 ──< site_visits              (visit_type INITIAL | FOLLOW_UP — Q2a)
claims 1 ──1 cause_investigations 1 ──< chronology_events
claims 1 ──< damage_items         1 ──< media_attachments
claims 1 ──< site_visits          1 ──< media_attachments
claims 1 ──< documents            1 ──< document_line_items
documents M >──< damage_items          (via document_damage_links)
claims 1 ──< requisition_notices  1 ──1 documents          (generated .docx)
claims 1 ──< preliminary_survey_reports
claims 1 ──< discrepancy_flags         (polymorphic subject_entity / subject_id)
claims 1 ──< assessment_heads     1 ──< assessment_line_items
assessment_line_items 1 ──< salvage_records
damage_items          1 ──< salvage_records
claims 1 ──1 coverage_opinions
claims 1 ──< final_survey_reports 1 ──< pre_submission_audits
final_survey_reports  1 ──< report_dispatches
claims 1 ──< audit_log
users  1 ──< sync_queue
stores 1 ──< everything above          (store_id on every table — §18)
```

---

## 38. Open items — Part B (flagged, not decided)

Continues the Part A §14 list. Numbering restarts; refer to these as "Part B item N".

| # | Item | Why it is not decided here |
| :-- | :-- | :-- |
| 1 | **The three sync columns** (`client_updated_at`, `field_updated_at`, `sync_revision`) and the whole of `sync_queue` (§36) | `sprint_0002` is the sync spike and owns the merge algorithm. These are a working shape for it to confirm or replace, not a decision. Every table in Part B is affected if it changes, so this is the single largest churn risk in the document. |
| 2 | **`policy_sections` `[ADDITION]`** (§21.1) | Promotes `sum_insured_heads` from `Array<Object>` to a table. Needs owner confirmation because it changes what `03_policy_coverage_review.md` §4 describes. |
| 3 | **`assessment_heads` `[ADDITION]`** (§30.1) | Same question for VAR / SI. The alternative — VAR and SI on every line item — is rejected here for the reason given, but it is the owner's call. |
| 4 | **FR-6.1 names "Electrical" as a Stage 6 asset head**, FR-11.1's five heads do not | Both are used by `head_category` here so Stage 6 maps 1:1 to Stage 11. If Stage 6 genuinely needs a sixth head, the enum needs a sixth value and the Stage 15 gate-6 mapping needs a rule. A pre-existing spec divergence, surfaced rather than silently resolved. |
| 5 | **Policy excess: per line item or per claim?** (§30.2) | SRS entity 8, FR-11.2 step 9 and `12_loss_assessment_quantification.md` §5 put it on the line; the same screen's §3 component list shows one claim-level input. Stored per line here; confirm the UI is a distribution over that. |
| 6 | **Insurer and peril masters** | `02_appointment_claim_intake.md` §4 says `insurer_name` "must match insurer list or custom" and `reported_peril` is "selected from standard peril master". `peril_type` is closed as an enum here; `insurer_name` is free text. If a real insurer master table is wanted (with codes, dispatch emails, portal URLs), it is a new entity. |
| 7 | **Depreciation scales** (`CLAUDE.md` §4 item 1, §16 Q6) | `depreciation_pct` and `depreciation_basis` are columns; the *source* of the standard scale tables is still unknown, so no scale entity is modelled. If scales become data rather than surveyor judgement, they need their own table. |
| 8 | **`uom` enum closure** (§19) | `07_damage_inspection_studio.md` §4 ends its list with "etc.". Twelve values are fixed here. Adding a value later is a migration, so it is worth a domain-expert pass now. |
| 9 | **`document_type` enum closure** (§19) | Thirty-two values assembled from FR-5.2, FR-7.1 and FR-10.1. Same migration cost as item 8. |
| 10 | **Retention for `audit_log`** | Part A §14 item 4 raises the same question for `auth_events`. `audit_log` is worse: it is evidentiary, and a retention policy that deletes it may conflict with the surveyor's professional record-keeping obligations. Needs a legal answer, not an engineering one. |
| 11 | **`report_dispatches.acknowledged_at`** | There is no specified mechanism by which an insurer acknowledgement is received. The column is provided; how it is populated is undefined. |

---

## 39. Traceability (Part B)

| Requirement | Satisfied by |
| :-- | :-- |
| FR-1.2 appointment attributes | `claims` §20 — all fifteen attributes as columns |
| FR-1.3 `SS-YYYY-XXXXX` + `TEMP-SS-XXXX` | `claims.claim_ref_no` / `.temp_ref_no` + `uq_claims_ref_sequence` §20 |
| CR-W1 15-stage state machine | `claims.current_stage` + `claims_stage_range` §20 |
| FR-2.1 section-wise sums insured, warranties, excess | `policy_details` + `policy_sections` §21 |
| §11.5 loss date within policy period | Stage 2 service + `discrepancy_flags` §21, §29 |
| FR-3.1 contact attempt log | `contact_logs` §22 |
| FR-3.3 Evidence & Loss Preservation Notice | `preservation_notices` §22 (Q2b) |
| FR-4.1 GPS capture, D28 10 m / 50 m | `site_visits.gps_*` + `site_visits_gps_hard_limit` §23 |
| FR-4.3 `LOCATION_DISCREPANCY_DETECTED` + mandatory justification | `site_visits_discrepancy_remarks` §23; `discrepancy_flags` §29 |
| FR-5.1 chronology builder | `chronology_events` §24.1 |
| FR-5.2 statutory evidence | `cause_investigations.fir_details` / `.fire_report_details` / `.third_party_reports` §24 |
| AC 5.1.3 two-hour chronology gap | Stage 5 service → `CHRONOLOGY_GAP_DETECTED` §29 |
| FR-6.1 itemised damage register | `damage_items` §25 |
| FR-6.2 watermark + six categories + voice notes | `media_attachments` §26 (`photo_category`, `watermark_*`, `media_type = AUDIO`) |
| FR-7.1 ownership documents, D34 four-state enum | `documents` + `insurable_interest_status` §27 |
| FR-7.1 link proof to damage item | `document_damage_links` §27 |
| FR-8.1 requisition notice | `requisition_notices` + `requisition_min_docs` §28 |
| FR-8.2 PSR engine | `preliminary_survey_reports` §28.1 |
| FR-9.1 multiple follow-up visits, `visit_number ≥ 2` | `site_visits` + `site_visits_type_numbering` §23 (Q2a) |
| FR-10.1 OCR line items | `documents.ocr_data_json` + `document_line_items` §27.1 |
| FR-10.2 / AC 10.1.x duplicate, rate inflation, betterment | `document_line_items.audit_status` + `discrepancy_flags` §27.1, §29 |
| §11.2 mandatory `audit_deduction_reason` | `dli_deduction_reason_required` §27.1 |
| FR-11.1 five asset heads | `head_category` §19; `assessment_heads` §30.1 |
| FR-11.2 strict deduction order | `ali_math_*` constraints §30.2 |
| FR-11.2 step 6 underinsurance on net-of-depreciation | `assessment_heads.underinsurance_factor` + `ali_math_after_underinsurance` §30 |
| FR-11.3 / AC 11.1.5 mandatory justification | `ali_justification_required` §30.2 |
| FR-12.1 salvage inventory | `salvage_records` §31 |
| FR-12.2 three disposal modes (D29) | `disposal_mode` + `salvage_mode_a/b/c_complete` §31 |
| FR-12.3 salvage feeds the head-wise sheet | `salvage_records.assessment_line_item_id` → `assessment_line_items.salvage_amount` §31 |
| FR-13.1 decision-support only | `coverage_opinions` §32 — no AI-authored column |
| FR-13.2 recommendation enum + mandatory notice | `surveyor_recommendation`; `coverage_notice_present` §32 |
| FR-14.1 nine-section FSR (§14 constraint 12) | `section_a_json` … `section_i_json` + `annexure_json` §33 |
| FR-14.2 AI drafts C, D, H, I only | section block `source` / `ai_module` envelope §33 |
| FR-14.4 4-point Human Approval Gate (§14 constraint 4) | `fsr_gate_before_export`, `psr_gate_before_export` §33, §28.1 |
| §14 constraint 3 `[SURVEYOR TO VERIFY]` | section block `placeholders` array §33 |
| FR-15.1 seven gates (D36) | `pre_submission_audits` + `audit_seven_gates` §34 |
| FR-15.2 sign-off, SHA-256 snapshot, dispatch log | `fsr_signoff_complete`, `snapshot_sha256`, `report_dispatches` §33, §34 |
| D35 licence required before FSR | `fsr_signoff_complete` (`signoff_sla_license_no`, `signoff_sla_category`) §33 |
| SRS §5.1 five common columns on operational tables | §18 — present on every Part B table |
| SRS §5.1 rule 3 immutable insurer access trail | `audit_log` `VIEW` / `DOWNLOAD` + `idx_audit_log_access` §35 |
| SRS §6.2 immutable audit of loss figures (§14 constraint 10) | `audit_log` + append-only trigger + `REVOKE` §35 |
| SRS §2.2 / AC 16.1.3 field-level conflict resolution (§14 constraint 8) | `field_updated_at` §18; `sync_queue.conflict_fields` §36 |
| ADR-0004 §4 schema standards | §18 conventions |
| `sprint_0001` Q2 | §17 |
