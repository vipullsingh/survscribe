-- SurvScribe migration 000006 (up) -- claims_and_policy
-- claims, policy_details, policy_sections (sections 20, 21).
--
-- Source of truth: documentation/architecture/physical-schema.md
-- Emitted for sprint_0001 task 2. Migrations are NEVER executed automatically;
-- see apps/backend/migrations/README.md for the runbook.

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
