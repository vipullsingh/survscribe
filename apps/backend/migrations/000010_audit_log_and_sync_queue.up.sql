-- SurvScribe migration 000010 (up) -- audit_log_and_sync_queue
-- audit_log (append-only) and sync_queue (sections 35, 36).
--
-- Source of truth: documentation/architecture/physical-schema.md
-- Emitted for sprint_0001 task 2. Migrations are NEVER executed automatically;
-- see apps/backend/migrations/README.md for the runbook.

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
