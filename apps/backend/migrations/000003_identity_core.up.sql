-- SurvScribe migration 000003 (up) -- identity_core
-- stores and users (sections 5, 6), then the deferred stores.owner_user_id FK.
--
-- Source of truth: documentation/architecture/physical-schema.md
-- Emitted for sprint_0001 task 2. Migrations are NEVER executed automatically;
-- see apps/backend/migrations/README.md for the runbook.

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

ALTER TABLE stores
    ADD CONSTRAINT fk_stores_owner_user
    FOREIGN KEY (owner_user_id) REFERENCES users(id)
    DEFERRABLE INITIALLY DEFERRED;
