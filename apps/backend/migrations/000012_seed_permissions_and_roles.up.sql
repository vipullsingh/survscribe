-- SurvScribe migration 000012 (up) -- seed_permissions_and_roles
-- The code-defined permission catalogue (physical-schema.md section 7.6) and the four
-- immutable system roles with their permission matrices (section 7.7).
--
-- This is reference data, not user data. The catalogue is seeded from a versioned Go
-- constant and never written at runtime: a store may compose custom roles, but may not
-- invent a permission, because a store-authored permission would name a capability no
-- handler enforces.
--
-- Source of truth: documentation/architecture/physical-schema.md
-- Emitted for sprint_0001 task 2. Migrations are NEVER executed automatically;
-- see apps/backend/migrations/README.md for the runbook.
--
-- NOTE for reviewers -- two asymmetries below are transcribed verbatim from the section
-- 7.7 matrix rather than "corrected", and are worth an explicit confirmation:
--   * assessment:approve is held by REVIEWER only. ADMIN is defined as "everything in
--     SURVEYOR plus store/user/role administration", and SURVEYOR has no approve right,
--     so ADMIN cannot approve an assessment. That reads as deliberate separation of
--     duties; if it is not, section 7.7 needs amending, not this file.
--   * report:submit is held by SURVEYOR and ADMIN but not REVIEWER.

---- Permission catalogue --------------------------------------------------
INSERT INTO permissions (code, resource, action, description) VALUES
    ('store:read', 'store', 'read', 'View the store profile and branding'),
    ('store:update', 'store', 'update', 'Edit the store profile'),
    ('store:branding:update', 'store:branding', 'update', 'Edit letterhead and report branding'),
    ('user:read', 'user', 'read', 'View users in the store'),
    ('user:invite', 'user', 'invite', 'Issue a store invite'),
    ('user:update', 'user', 'update', 'Edit a user profile'),
    ('user:deactivate', 'user', 'deactivate', 'Deactivate a user'),
    ('user:role:assign', 'user:role', 'assign', 'Grant or revoke a role on a user'),
    ('role:read', 'role', 'read', 'View roles and their permissions'),
    ('role:create', 'role', 'create', 'Create a store custom role'),
    ('role:update', 'role', 'update', 'Edit a store custom role'),
    ('role:delete', 'role', 'delete', 'Delete a store custom role'),
    ('claim:create', 'claim', 'create', 'Create a survey claim file'),
    ('claim:read', 'claim', 'read', 'View a survey claim file'),
    ('claim:update', 'claim', 'update', 'Edit a survey claim file'),
    ('claim:delete', 'claim', 'delete', 'Soft-delete a survey claim file'),
    ('claim:assign', 'claim', 'assign', 'Assign a surveyor or reviewer to a claim'),
    ('claim:stage:advance', 'claim:stage', 'advance', 'Advance a claim through the 15-stage state machine'),
    ('evidence:capture', 'evidence', 'capture', 'Capture photos, video and voice notes'),
    ('evidence:read', 'evidence', 'read', 'View captured evidence'),
    ('evidence:delete', 'evidence', 'delete', 'Soft-delete captured evidence'),
    ('document:upload', 'document', 'upload', 'Upload a claim document'),
    ('document:read', 'document', 'read', 'View a claim document'),
    ('document:verify', 'document', 'verify', 'Mark a document or line item verified'),
    ('assessment:read', 'assessment', 'read', 'View the loss assessment matrix'),
    ('assessment:write', 'assessment', 'write', 'Edit loss assessment line items and deductions'),
    ('assessment:approve', 'assessment', 'approve', 'Approve a loss assessment as reviewer'),
    ('salvage:read', 'salvage', 'read', 'View salvage records'),
    ('salvage:write', 'salvage', 'write', 'Create and edit salvage records'),
    ('coverage-opinion:read', 'coverage-opinion', 'read', 'View the coverage and liability opinion'),
    ('coverage-opinion:write', 'coverage-opinion', 'write', 'Author the coverage and liability opinion'),
    ('report:psr:generate', 'report:psr', 'generate', 'Generate a Preliminary Survey Report'),
    ('report:fsr:generate', 'report:fsr', 'generate', 'Generate a Final Survey Report'),
    ('report:export', 'report', 'export', 'Export a report to .docx'),
    ('report:submit', 'report', 'submit', 'Submit a Final Survey Report to the insurer'),
    ('audit:read', 'audit', 'read', 'Read the immutable audit log'),
    ('ai:invoke', 'ai', 'invoke', 'Invoke an AI assistant module'),
    ('insurer:claim:read', 'insurer:claim', 'read', 'Read a claim file granted to an insurer viewer')
ON CONFLICT (code) DO NOTHING;

---- System roles ----------------------------------------------------------
INSERT INTO roles (store_id, code, name, description, is_system) VALUES
    (NULL, 'SURVEYOR', 'Surveyor', 'Licensed field surveyor. Owns the claim file end to end.', TRUE),
    (NULL, 'REVIEWER', 'Reviewer', 'Senior surveyor or partner. Reviews and approves, does not submit.', TRUE),
    (NULL, 'ADMIN', 'Administrator', 'Store owner or administrator. Full surveyor rights plus store and user administration.', TRUE),
    (NULL, 'INSURER_VIEWER', 'Insurer Viewer', 'Read-only insurer access, valid only where a live claim_access_grants row exists.', TRUE)
ON CONFLICT DO NOTHING;

---- Role to permission matrix (section 7.7) -------------------------------
-- SURVEYOR: 26 permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p ON p.code IN (
        'claim:create',
        'claim:read',
        'claim:update',
        'claim:delete',
        'claim:assign',
        'claim:stage:advance',
        'evidence:capture',
        'evidence:read',
        'evidence:delete',
        'document:upload',
        'document:read',
        'document:verify',
        'assessment:read',
        'assessment:write',
        'salvage:read',
        'salvage:write',
        'coverage-opinion:read',
        'coverage-opinion:write',
        'report:psr:generate',
        'report:fsr:generate',
        'report:export',
        'report:submit',
        'ai:invoke',
        'audit:read',
        'store:read',
        'user:read'
    ) WHERE r.code = 'SURVEYOR' AND r.store_id IS NULL
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- REVIEWER: 13 permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p ON p.code IN (
        'claim:read',
        'evidence:read',
        'document:read',
        'assessment:read',
        'assessment:approve',
        'salvage:read',
        'coverage-opinion:read',
        'report:psr:generate',
        'report:fsr:generate',
        'report:export',
        'audit:read',
        'store:read',
        'user:read'
    ) WHERE r.code = 'REVIEWER' AND r.store_id IS NULL
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- ADMIN: 36 permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p ON p.code IN (
        'claim:create',
        'claim:read',
        'claim:update',
        'claim:delete',
        'claim:assign',
        'claim:stage:advance',
        'evidence:capture',
        'evidence:read',
        'evidence:delete',
        'document:upload',
        'document:read',
        'document:verify',
        'assessment:read',
        'assessment:write',
        'salvage:read',
        'salvage:write',
        'coverage-opinion:read',
        'coverage-opinion:write',
        'report:psr:generate',
        'report:fsr:generate',
        'report:export',
        'report:submit',
        'ai:invoke',
        'audit:read',
        'store:read',
        'user:read',
        'store:update',
        'store:branding:update',
        'user:invite',
        'user:update',
        'user:deactivate',
        'user:role:assign',
        'role:read',
        'role:create',
        'role:update',
        'role:delete'
    ) WHERE r.code = 'ADMIN' AND r.store_id IS NULL
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- INSURER_VIEWER: 1 permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r JOIN permissions p ON p.code IN (
        'insurer:claim:read'
    ) WHERE r.code = 'INSURER_VIEWER' AND r.store_id IS NULL
ON CONFLICT (role_id, permission_id) DO NOTHING;
