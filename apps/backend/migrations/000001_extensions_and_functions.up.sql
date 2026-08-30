-- SurvScribe migration 000001 (up) -- extensions_and_functions
-- Extensions and shared trigger functions (physical-schema.md section 3).
--
-- Source of truth: documentation/architecture/physical-schema.md
-- Emitted for sprint_0001 task 2. Migrations are NEVER executed automatically;
-- see apps/backend/migrations/README.md for the runbook.

CREATE EXTENSION IF NOT EXISTS citext;    -- case-insensitive email / username
CREATE EXTENSION IF NOT EXISTS pgcrypto;  -- gen_random_uuid()

-- Maintains updated_at on every UPDATE. Attached to all mutable tables.
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Blocks mutation of append-only tables. Attached to auth_events.
CREATE OR REPLACE FUNCTION reject_mutation() RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'Table % is append-only; % is not permitted',
        TG_TABLE_NAME, TG_OP;
END;
$$ LANGUAGE plpgsql;
