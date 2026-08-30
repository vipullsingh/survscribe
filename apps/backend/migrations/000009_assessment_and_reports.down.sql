-- SurvScribe migration 000009 (down) -- assessment_and_reports
-- requisition_notices, preliminary_survey_reports, discrepancy_flags, assessment_heads, assessment_line_items, salvage_records, coverage_opinions, final_survey_reports, pre_submission_audits, report_dispatches (sections 28-34).
--
-- Source of truth: documentation/architecture/physical-schema.md
-- Emitted for sprint_0001 task 2. Migrations are NEVER executed automatically;
-- see apps/backend/migrations/README.md for the runbook.

DROP TABLE IF EXISTS report_dispatches          CASCADE;
DROP TABLE IF EXISTS pre_submission_audits      CASCADE;
DROP TABLE IF EXISTS final_survey_reports       CASCADE;
DROP TABLE IF EXISTS coverage_opinions          CASCADE;
DROP TABLE IF EXISTS salvage_records            CASCADE;
DROP TABLE IF EXISTS assessment_line_items      CASCADE;
DROP TABLE IF EXISTS assessment_heads           CASCADE;
DROP TABLE IF EXISTS discrepancy_flags          CASCADE;
DROP TABLE IF EXISTS preliminary_survey_reports CASCADE;
DROP TABLE IF EXISTS requisition_notices        CASCADE;
