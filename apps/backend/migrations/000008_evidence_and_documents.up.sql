-- SurvScribe migration 000008 (up) -- evidence_and_documents
-- damage_items, media_attachments, documents, document_damage_links, document_line_items (sections 25-27).
--
-- Source of truth: documentation/architecture/physical-schema.md
-- Emitted for sprint_0001 task 2. Migrations are NEVER executed automatically;
-- see apps/backend/migrations/README.md for the runbook.

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
