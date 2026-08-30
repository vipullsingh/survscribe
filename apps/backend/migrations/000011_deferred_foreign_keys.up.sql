-- SurvScribe migration 000011 (up) -- deferred_foreign_keys
-- Foreign keys whose target table is created in a later migration than the
-- referencing table. physical-schema.md section 7.5 marks this one explicitly.
--
-- Source of truth: documentation/architecture/physical-schema.md
-- Emitted for sprint_0001 task 2. Migrations are NEVER executed automatically;
-- see apps/backend/migrations/README.md for the runbook.

-- claim_access_grants is created in 000004 (identity slice) but scopes access to a
-- claim, and claims is not created until 000006. The column is declared without a
-- REFERENCES clause there and constrained here.
ALTER TABLE claim_access_grants
    ADD CONSTRAINT fk_claim_access_grants_claim
    FOREIGN KEY (claim_id) REFERENCES claims(id);

CREATE INDEX IF NOT EXISTS idx_claim_grants_claim
    ON claim_access_grants (store_id, claim_id) WHERE revoked_at IS NULL;
