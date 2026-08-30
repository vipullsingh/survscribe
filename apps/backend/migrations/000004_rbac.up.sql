-- SurvScribe migration 000004 (up) -- rbac
-- permissions, roles, role_permissions, user_roles, claim_access_grants (section 7).
--
-- Source of truth: documentation/architecture/physical-schema.md
-- Emitted for sprint_0001 task 2. Migrations are NEVER executed automatically;
-- see apps/backend/migrations/README.md for the runbook.

CREATE TABLE permissions (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code          VARCHAR(96) NOT NULL UNIQUE,   -- 'claim:read'
    resource      VARCHAR(48) NOT NULL,          -- 'claim'
    action        VARCHAR(48) NOT NULL,          -- 'read'
    description   TEXT        NOT NULL,
    is_assignable BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT permissions_code_shape CHECK (code = resource || ':' || action)
);

CREATE TABLE roles (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id    UUID REFERENCES stores(id),   -- NULL => immutable system role
    code        VARCHAR(64)  NOT NULL,
    name        VARCHAR(120) NOT NULL,
    description TEXT,
    is_system   BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ,

    CONSTRAINT roles_system_is_global CHECK (
        (is_system = TRUE  AND store_id IS NULL) OR
        (is_system = FALSE AND store_id IS NOT NULL))
);

-- A system role code is globally unique; a custom role code is unique per store.
CREATE UNIQUE INDEX uq_roles_system ON roles (code)
    WHERE store_id IS NULL AND deleted_at IS NULL;
CREATE UNIQUE INDEX uq_roles_store  ON roles (store_id, code)
    WHERE store_id IS NOT NULL AND deleted_at IS NULL;

CREATE TRIGGER trg_roles_updated_at
    BEFORE UPDATE ON roles FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE role_permissions (
    role_id       UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE RESTRICT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (role_id, permission_id)
);
CREATE INDEX idx_role_permissions_permission ON role_permissions (permission_id);

CREATE TABLE user_roles (
    user_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id            UUID NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
    store_id           UUID NOT NULL REFERENCES stores(id),
    granted_by_user_id UUID REFERENCES users(id),
    granted_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at         TIMESTAMPTZ,
    revoked_at         TIMESTAMPTZ,
    revoke_reason      TEXT,
    PRIMARY KEY (user_id, role_id)
);

CREATE INDEX idx_user_roles_active ON user_roles (user_id)
    WHERE revoked_at IS NULL;
CREATE INDEX idx_user_roles_role   ON user_roles (role_id);
CREATE INDEX idx_user_roles_store  ON user_roles (store_id);

CREATE TABLE claim_access_grants (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id           UUID NOT NULL REFERENCES stores(id),
    claim_id           UUID NOT NULL,               -- FK added with the claims table
    grantee_user_id    UUID NOT NULL REFERENCES users(id),
    granted_by_user_id UUID NOT NULL REFERENCES users(id),
    scope              grant_scope NOT NULL DEFAULT 'READ_ONLY',
    granted_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at         TIMESTAMPTZ,
    revoked_at         TIMESTAMPTZ,
    revoked_by_user_id UUID REFERENCES users(id),
    revoke_reason      TEXT,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX uq_claim_grant_active
    ON claim_access_grants (claim_id, grantee_user_id) WHERE revoked_at IS NULL;
CREATE INDEX idx_claim_grants_grantee ON claim_access_grants (grantee_user_id)
    WHERE revoked_at IS NULL;

CREATE TRIGGER trg_claim_grants_updated_at
    BEFORE UPDATE ON claim_access_grants FOR EACH ROW EXECUTE FUNCTION set_updated_at();
