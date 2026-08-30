-- SurvScribe migration 000006 (down) -- claims_and_policy
-- claims, policy_details, policy_sections (sections 20, 21).
--
-- Source of truth: documentation/architecture/physical-schema.md
-- Emitted for sprint_0001 task 2. Migrations are NEVER executed automatically;
-- see apps/backend/migrations/README.md for the runbook.

DROP TABLE IF EXISTS policy_sections CASCADE;
DROP TABLE IF EXISTS policy_details  CASCADE;
DROP TABLE IF EXISTS claims          CASCADE;
