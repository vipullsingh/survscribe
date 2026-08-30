-- SurvScribe migration 000009 (up) -- assessment_and_reports
-- requisition_notices, preliminary_survey_reports, discrepancy_flags, assessment_heads, assessment_line_items, salvage_records, coverage_opinions, final_survey_reports, pre_submission_audits, report_dispatches (sections 28-34).
--
-- Source of truth: documentation/architecture/physical-schema.md
-- Emitted for sprint_0001 task 2. Migrations are NEVER executed automatically;
-- see apps/backend/migrations/README.md for the runbook.

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
