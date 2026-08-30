-- SurvScribe migration 000012 (down) -- seed_permissions_and_roles
-- Removes only the seeded system roles and the code-defined permission catalogue.
-- Store custom roles (store_id IS NOT NULL) are user data and are left untouched.
--
-- Source of truth: documentation/architecture/physical-schema.md
-- Emitted for sprint_0001 task 2. Migrations are NEVER executed automatically;
-- see apps/backend/migrations/README.md for the runbook.

DELETE FROM role_permissions
 WHERE role_id IN (SELECT id FROM roles WHERE is_system = TRUE AND store_id IS NULL);

DELETE FROM roles WHERE is_system = TRUE AND store_id IS NULL;

-- role_permissions references permissions with ON DELETE RESTRICT, so any custom role
-- still holding a catalogue permission will (correctly) block this delete.
DELETE FROM permissions;
