-- SurvScribe migration 000007 (up) -- field_survey
-- contact_logs, preservation_notices, site_visits, cause_investigations, chronology_events (sections 22-24).
--
-- Source of truth: documentation/architecture/physical-schema.md
-- Emitted for sprint_0001 task 2. Migrations are NEVER executed automatically;
-- see apps/backend/migrations/README.md for the runbook.

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
