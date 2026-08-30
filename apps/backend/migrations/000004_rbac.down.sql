-- SurvScribe migration 000004 (down) -- rbac
-- permissions, roles, role_permissions, user_roles, claim_access_grants (section 7).
--
-- Source of truth: documentation/architecture/physical-schema.md
-- Emitted for sprint_0001 task 2. Migrations are NEVER executed automatically;
-- see apps/backend/migrations/README.md for the runbook.

DROP TABLE IF EXISTS claim_access_grants CASCADE;
DROP TABLE IF EXISTS user_roles          CASCADE;
DROP TABLE IF EXISTS role_permissions    CASCADE;
DROP TABLE IF EXISTS roles               CASCADE;
DROP TABLE IF EXISTS permissions         CASCADE;
