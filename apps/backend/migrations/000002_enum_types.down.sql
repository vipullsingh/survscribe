-- SurvScribe migration 000002 (down) -- enum_types
-- All PostgreSQL ENUM types (Part A section 4, Part B section 19).
--
-- Source of truth: documentation/architecture/physical-schema.md
-- Emitted for sprint_0001 task 2. Migrations are NEVER executed automatically;
-- see apps/backend/migrations/README.md for the runbook.

DROP TYPE IF EXISTS sync_status;
DROP TYPE IF EXISTS sync_operation;
DROP TYPE IF EXISTS audit_action;
DROP TYPE IF EXISTS audit_gate_result;
DROP TYPE IF EXISTS audit_gate_code;
DROP TYPE IF EXISTS report_status;
DROP TYPE IF EXISTS surveyor_recommendation;
DROP TYPE IF EXISTS warranty_compliance_status;
DROP TYPE IF EXISTS peril_admissibility;
DROP TYPE IF EXISTS disposal_mode;
DROP TYPE IF EXISTS detected_by;
DROP TYPE IF EXISTS discrepancy_status;
DROP TYPE IF EXISTS discrepancy_severity;
DROP TYPE IF EXISTS discrepancy_code;
DROP TYPE IF EXISTS audit_status;
DROP TYPE IF EXISTS insurable_interest_status;
DROP TYPE IF EXISTS ocr_status;
DROP TYPE IF EXISTS document_type;
DROP TYPE IF EXISTS photo_category;
DROP TYPE IF EXISTS media_type;
DROP TYPE IF EXISTS uom;
DROP TYPE IF EXISTS damage_recommendation;
DROP TYPE IF EXISTS damage_severity;
DROP TYPE IF EXISTS chronology_event_type;
DROP TYPE IF EXISTS visit_purpose;
DROP TYPE IF EXISTS visit_type;
DROP TYPE IF EXISTS dispatch_status;
DROP TYPE IF EXISTS dispatch_channel;
DROP TYPE IF EXISTS contact_outcome;
DROP TYPE IF EXISTS policy_section_head;
DROP TYPE IF EXISTS head_category;
DROP TYPE IF EXISTS policy_type;
DROP TYPE IF EXISTS peril_type;
DROP TYPE IF EXISTS claim_status;
DROP TYPE IF EXISTS grant_scope;
DROP TYPE IF EXISTS otp_purpose;
DROP TYPE IF EXISTS otp_channel;
DROP TYPE IF EXISTS invite_status;
DROP TYPE IF EXISTS auth_event_type;
DROP TYPE IF EXISTS auth_method;
DROP TYPE IF EXISTS auth_outcome;
DROP TYPE IF EXISTS session_status;
DROP TYPE IF EXISTS device_platform;
DROP TYPE IF EXISTS logout_reason;
DROP TYPE IF EXISTS signup_source;
DROP TYPE IF EXISTS role_scope;
DROP TYPE IF EXISTS sla_category;
DROP TYPE IF EXISTS user_status;
DROP TYPE IF EXISTS store_status;
DROP TYPE IF EXISTS firm_type;
