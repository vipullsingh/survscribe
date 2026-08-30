-- SurvScribe migration 000011 (down) -- deferred_foreign_keys
--
-- Source of truth: documentation/architecture/physical-schema.md
-- Emitted for sprint_0001 task 2. Migrations are NEVER executed automatically;
-- see apps/backend/migrations/README.md for the runbook.

DROP INDEX IF EXISTS idx_claim_grants_claim;

ALTER TABLE claim_access_grants
    DROP CONSTRAINT IF EXISTS fk_claim_access_grants_claim;
