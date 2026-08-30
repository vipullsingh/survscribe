-- SurvScribe migration 000005 (down) -- sessions_devices_and_auth_telemetry
-- sessions, user_devices, auth_events, store_invites, otp_challenges, password_reset_tokens (sections 8-12).
--
-- Source of truth: documentation/architecture/physical-schema.md
-- Emitted for sprint_0001 task 2. Migrations are NEVER executed automatically;
-- see apps/backend/migrations/README.md for the runbook.

ALTER TABLE users DROP CONSTRAINT IF EXISTS fk_users_invite;
DROP TABLE IF EXISTS password_reset_tokens CASCADE;
DROP TABLE IF EXISTS otp_challenges        CASCADE;
DROP TABLE IF EXISTS store_invites         CASCADE;
DROP TABLE IF EXISTS auth_events           CASCADE;
DROP TABLE IF EXISTS user_devices          CASCADE;
DROP TABLE IF EXISTS sessions              CASCADE;
