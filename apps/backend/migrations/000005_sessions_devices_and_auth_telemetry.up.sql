-- SurvScribe migration 000005 (up) -- sessions_devices_and_auth_telemetry
-- sessions, user_devices, auth_events, store_invites, otp_challenges, password_reset_tokens (sections 8-12).
--
-- Source of truth: documentation/architecture/physical-schema.md
-- Emitted for sprint_0001 task 2. Migrations are NEVER executed automatically;
-- see apps/backend/migrations/README.md for the runbook.

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

REVOKE UPDATE, DELETE, TRUNCATE ON auth_events FROM survscribe_app;
GRANT  INSERT, SELECT              ON auth_events TO   survscribe_app;

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
