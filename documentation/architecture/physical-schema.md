# Physical Schema — Identity, Tenancy, RBAC & Auth Telemetry

> **Document type:** Finalized PostgreSQL physical schema (identity slice).
> **Version:** 1.0.0 · **Created:** 2026-08-30 · **Status:** Draft — awaiting project-owner approval per `sprints/sprint_0001` R8.
> **Scope:** The identity, tenancy, RBAC, session and auth-telemetry entities. The ten claim-workflow entities of `Requirement.MD` §5.2 (1–10) and workflow entities 16–20 are **not** covered here; they are produced by `sprint_0001` task 1 into this same file.
> **Governing decisions:** ADR-0003 (tokens/auth), ADR-0004 (schema rules), **ADR-0005** (identity model — `store`/`client` naming, DB-driven RBAC, invite-only join, auth telemetry), ADR-0006 (geo-IP provider).
>
> **No migration is generated from this document yet.** `sprint_0001` task 2 emits the first migration set covering all entities at once, and per its runbook migrations are never executed automatically.

---

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
