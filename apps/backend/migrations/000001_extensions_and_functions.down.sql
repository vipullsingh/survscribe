-- SurvScribe migration 000001 (down) -- extensions_and_functions
-- Extensions and shared trigger functions (physical-schema.md section 3).
--
-- Source of truth: documentation/architecture/physical-schema.md
-- Emitted for sprint_0001 task 2. Migrations are NEVER executed automatically;
-- see apps/backend/migrations/README.md for the runbook.

DROP FUNCTION IF EXISTS reject_mutation();
DROP FUNCTION IF EXISTS set_updated_at();
-- Extensions are intentionally NOT dropped: other databases in the cluster may rely on them.
