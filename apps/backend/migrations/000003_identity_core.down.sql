-- SurvScribe migration 000003 (down) -- identity_core
-- stores and users (sections 5, 6), then the deferred stores.owner_user_id FK.
--
-- Source of truth: documentation/architecture/physical-schema.md
-- Emitted for sprint_0001 task 2. Migrations are NEVER executed automatically;
-- see apps/backend/migrations/README.md for the runbook.

DROP TABLE IF EXISTS users  CASCADE;
DROP TABLE IF EXISTS stores CASCADE;
