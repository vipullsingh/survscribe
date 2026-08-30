-- SurvScribe migration 000007 (down) -- field_survey
-- contact_logs, preservation_notices, site_visits, cause_investigations, chronology_events (sections 22-24).
--
-- Source of truth: documentation/architecture/physical-schema.md
-- Emitted for sprint_0001 task 2. Migrations are NEVER executed automatically;
-- see apps/backend/migrations/README.md for the runbook.

DROP TABLE IF EXISTS chronology_events    CASCADE;
DROP TABLE IF EXISTS cause_investigations CASCADE;
DROP TABLE IF EXISTS site_visits          CASCADE;
DROP TABLE IF EXISTS preservation_notices CASCADE;
DROP TABLE IF EXISTS contact_logs         CASCADE;
