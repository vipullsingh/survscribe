-- SurvScribe migration 000010 (down) -- audit_log_and_sync_queue
-- audit_log (append-only) and sync_queue (sections 35, 36).
--
-- Source of truth: documentation/architecture/physical-schema.md
-- Emitted for sprint_0001 task 2. Migrations are NEVER executed automatically;
-- see apps/backend/migrations/README.md for the runbook.

DROP TABLE IF EXISTS sync_queue CASCADE;
-- audit_log is append-only and evidentiary. Dropping it destroys the record of every
-- loss-figure change and every insurer file access. Down-migrating past 000010 in any
-- environment holding real survey data requires an explicit archival step first.
DROP TABLE IF EXISTS audit_log  CASCADE;
