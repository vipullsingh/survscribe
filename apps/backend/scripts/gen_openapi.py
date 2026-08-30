#!/usr/bin/env python3
"""Generate documentation/architecture/api-contract/openapi.yaml from the migration DDL.

The contract and the database schema are derived from one source, so they cannot
silently drift. Run from the repository root.
"""
import io, os, re, sys, collections, yaml

MIG = "apps/backend/migrations"
OUT = "documentation/architecture/api-contract/openapi.yaml"

RAW = "\n".join(io.open(os.path.join(MIG, f), encoding="utf-8").read()
                for f in sorted(os.listdir(MIG)) if f.endswith(".up.sql"))

# ------------------------------------------------------------------ parse DDL
ENUMS = {}
for m in re.finditer(r"(?is)CREATE TYPE\s+(\w+)\s+AS ENUM\s*\((.*?)\);", RAW):
    ENUMS[m.group(1)] = [v.replace("''", "'")
                         for v in re.findall(r"'((?:[^']|'')*)'", m.group(2))]

TABLES = collections.OrderedDict()
for m in re.finditer(r"(?is)CREATE TABLE\s+(\w+)\s*\((.*?)\n\);", RAW):
    tname, body, cols, depth = m.group(1), m.group(2), [], 0
    for line in body.split("\n"):
        at_top = depth == 0
        depth += line.count("(") - line.count(")")
        s = re.sub(r"\s+--.*$", "", line.strip().rstrip(","))
        if not at_top or not s or s.startswith("--"):
            continue
        if s.upper().startswith(("CONSTRAINT", "PRIMARY KEY", "UNIQUE", "CHECK", "FOREIGN KEY")):
            continue
        parts = s.split()
        if len(parts) < 2:
            continue
        rest = " ".join(parts[1:])
        mt = re.match(r"([A-Za-z_]+)(\(([^)]*)\))?", rest)
        cols.append({
            "name": parts[0], "type": mt.group(1).lower(), "args": mt.group(3) or "",
            "notnull": bool(re.search(r"(?i)NOT NULL", rest)),
            "ref": (re.search(r"(?i)REFERENCES\s+(\w+)", rest).group(1)
                    if re.search(r"(?i)REFERENCES\s+(\w+)", rest) else None),
            "default": bool(re.search(r"(?i)DEFAULT", rest)),
        })
    TABLES[tname] = cols


def pascal(s):
    return "".join(p[:1].upper() + p[1:].lower() for p in re.split(r"[_\-]", s))


def singular(t):
    # English plurals, only as far as this schema actually needs. "report_dispatches"
    # must yield ReportDispatch, not ReportDispatche.
    if t.endswith("ies"):
        return t[:-3] + "y"
    for suffix in ("ches", "shes", "sses", "xes", "zes"):
        if t.endswith(suffix):
            return t[:-2]
    return t[:-1] if t.endswith("s") else t


def model(t):
    return pascal(singular(t))


DEC = {"type": "string", "format": "decimal", "pattern": r"^-?[0-9]+(\.[0-9]+)?$"}

# OAS 3.0 requires `type` alongside `nullable`. An always-null envelope slot is still
# typed, otherwise Redocly (correctly) rejects the document.
def nullslot():
    return {"type": "object", "nullable": True, "example": None}

# Enums used in a nullable position get a generated companion schema, because
# {"allOf": [$ref], "nullable": true} is not valid OAS 3.0 -- it has no `type`.
NULLABLE_ENUMS = set()


def col_schema(c):
    n, ty, args = c["name"], c["type"], c["args"]
    if ty in ENUMS:
        if c["notnull"]:
            return {"$ref": "#/components/schemas/" + pascal(ty)}
        NULLABLE_ENUMS.add(ty)
        return {"$ref": "#/components/schemas/" + pascal(ty) + "OrNull"}
    if ty == "uuid":
        d = {"type": "string", "format": "uuid"}
    elif ty == "timestamptz":
        d = {"type": "string", "format": "date-time"}
    elif ty == "date":
        d = {"type": "string", "format": "date"}
    elif ty == "time":
        d = {"type": "string", "example": "14:30:00"}
    elif ty in ("boolean", "bool"):
        d = {"type": "boolean"}
    elif ty in ("smallint", "integer", "int"):
        d = {"type": "integer", "format": "int32"}
    elif ty in ("bigint", "bigserial"):
        d = {"type": "integer", "format": "int64"}
    elif ty == "numeric":
        d = dict(DEC)
        if args:
            d["description"] = "Decimal string, NUMERIC(%s) in the database." % args
    elif ty in ("jsonb", "json"):
        d = {"type": "object", "additionalProperties": True}
    elif ty == "inet":
        d = {"type": "string", "description": "IP address."}
    elif ty == "citext":
        d = {"type": "string"}
        if "email" in n:
            d["format"] = "email"
    else:
        d = {"type": "string"}
        if args and args.isdigit():
            d["maxLength"] = int(args)
            if ty == "char":
                d["minLength"] = int(args)
    if c["ref"]:
        d["description"] = (d.get("description", "") +
                            (" " if d.get("description") else "") +
                            "References %s.id." % c["ref"]).strip()
    if not c["notnull"]:
        d["nullable"] = True
    return d


SERVER_OWNED = {"id", "store_id", "client_id", "created_at", "updated_at", "deleted_at",
                "sync_revision", "access_role_scope"}

DERIVED = {
    "assessment_line_items": {"assessed_gross", "depreciation_amount", "net_of_depreciation",
                              "underinsurance_deduction", "after_underinsurance", "net_recommended"},
    "assessment_heads": {"total_claimed", "total_gross_assessed", "total_depreciation",
                         "total_betterment", "total_underinsurance", "total_salvage",
                         "total_excess", "total_net_recommended", "underinsurance_factor",
                         "underinsurance_applies", "sum_insured"},
    "claims": {"claim_ref_no", "ref_year", "ref_sequence", "stage_entered_at",
               "current_stage", "status"},
    "policy_details": {"sum_insured_total"},
    "document_line_items": {"rate_variance_pct"},
    "final_survey_reports": {"snapshot_sha256", "snapshot_taken_at", "docx_sha256",
                             "audit_passed", "signoff_sla_license_no", "signoff_sla_category",
                             "docx_document_id", "docx_file_uri", "generated_at",
                             "approval_reviewed_ai_at", "approval_factual_accuracy_at",
                             "approval_calculations_at", "approval_responsibility_at",
                             "approved_by_user_id", "signed_off_by_user_id", "signed_off_at",
                             "status"},
    "preliminary_survey_reports": {"docx_sha256", "docx_document_id", "generated_at", "status",
                                   "approval_reviewed_ai_at", "approval_factual_accuracy_at",
                                   "approval_calculations_at", "approval_responsibility_at",
                                   "approved_by_user_id"},
    "media_attachments": {"remote_uri", "uploaded_at", "upload_attempts", "sha256",
                          "upload_status", "transcript_text", "transcript_provider"},
    "documents": {"remote_uri", "ocr_status", "ocr_data_json", "ocr_confidence",
                  "ocr_provider", "ocr_completed_at", "upload_status"},
    "salvage_records": {},
    "discrepancy_flags": {"resolved_by_user_id", "resolved_at"},
    "preservation_notices": {"dispatch_status", "dispatched_at", "delivery_reference",
                             "failure_reason", "rendered_body"},
    "requisition_notices": {"dispatch_status", "dispatched_at", "delivery_reference",
                            "docx_document_id"},
    "report_dispatches": {"dispatch_status", "dispatched_at", "delivery_reference",
                          "failure_reason", "acknowledged_at"},
    "pre_submission_audits": {"run_no", "run_at", "run_by_user_id", "overall_result",
                              "gates_json", "duration_ms"},
}

RESOURCES = [
    ("policy_details",             "policy",                True,  2,  "Policy schedule and coverage review"),
    ("policy_sections",            "policy/sections",       False, 2,  "Section-wise sums insured"),
    ("contact_logs",               "contact-logs",          False, 3,  "Insured contact attempt log"),
    ("preservation_notices",       "preservation-notices",  False, 3,  "Evidence and loss preservation notices"),
    ("site_visits",                "site-visits",           False, 4,  "Site visits, initial and follow-up"),
    ("cause_investigations",       "cause-investigation",   True,  5,  "Cause and circumstances of loss"),
    ("chronology_events",          "chronology-events",     False, 5,  "Incident chronology timeline"),
    ("damage_items",               "damage-items",          False, 6,  "Damaged property itemised register"),
    ("media_attachments",          "media",                 False, 6,  "Photos, video and voice notes"),
    ("documents",                  "documents",             False, 7,  "Document locker"),
    ("document_damage_links",      "document-damage-links", False, 7,  "Document to damage-item links"),
    ("document_line_items",        "document-line-items",   False, 10, "OCR line items and forensic audit"),
    ("requisition_notices",        "requisition-notices",   False, 8,  "Document requisition notices"),
    ("preliminary_survey_reports", "preliminary-reports",   False, 8,  "Preliminary Survey Report"),
    ("discrepancy_flags",          "discrepancy-flags",     False, 0,  "Cross-stage discrepancy flags"),
    ("assessment_heads",           "assessment-heads",      False, 11, "Head-wise assessment and underinsurance"),
    ("assessment_line_items",      "assessment-line-items", False, 11, "Loss quantification line items"),
    ("salvage_records",            "salvage-records",       False, 12, "Salvage inventory and disposal"),
    ("coverage_opinions",          "coverage-opinion",      True,  13, "Coverage and liability opinion"),
    ("final_survey_reports",       "final-reports",         False, 14, "Final Survey Report"),
    ("pre_submission_audits",      "pre-submission-audits", False, 15, "Seven-gate pre-submission audit"),
    ("report_dispatches",          "dispatches",            False, 15, "Report dispatch tracking"),
]
NO_UPDATE = {"pre_submission_audits", "document_damage_links"}
NO_DELETE = {"pre_submission_audits", "final_survey_reports"}

# ------------------------------------------------------------------ schemas
schemas = collections.OrderedDict()

for name, vals in sorted(ENUMS.items()):
    schemas[pascal(name)] = {"type": "string", "enum": vals,
                             "description": "PostgreSQL enum `%s`." % name}

schemas["Meta"] = {
    "type": "object", "description": "Pagination metadata (ADR-0004 section 2).",
    "properties": {"page": {"type": "integer", "minimum": 1, "example": 1},
                   "limit": {"type": "integer", "minimum": 1, "maximum": 200, "example": 20},
                   "total": {"type": "integer", "minimum": 0, "example": 142}},
    "required": ["page", "limit", "total"]}
schemas["ErrorDetail"] = {
    "type": "object",
    "properties": {"field": {"type": "string", "example": "license_number"},
                   "issue": {"type": "string", "example": "Must match regex SLA-[0-9]{4,8}"}},
    "required": ["field", "issue"]}
schemas["ApiError"] = {
    "type": "object",
    "properties": {"code": {"$ref": "#/components/schemas/ErrorCode"},
                   "message": {"type": "string"},
                   "details": {"type": "array", "items": {"$ref": "#/components/schemas/ErrorDetail"},
                               "nullable": True}},
    "required": ["code", "message"]}
schemas["ErrorCode"] = {
    "type": "string",
    "description": "Stable machine-readable error code. Clients branch on this, never on `message`.",
    "enum": ["VALIDATION_FAILED", "UNAUTHENTICATED", "TOKEN_EXPIRED", "TOKEN_REUSE_DETECTED",
             "PERMISSION_DENIED", "STORE_SCOPE_VIOLATION", "CLAIM_GRANT_REQUIRED",
             "NOT_FOUND", "CONFLICT", "SYNC_CONFLICT", "STAGE_PRECONDITION_FAILED",
             "APPROVAL_GATE_NOT_SATISFIED", "AUDIT_GATE_FAILED", "DEDUCTION_REMARK_REQUIRED",
             "GPS_ACCURACY_REJECTED", "ACCOUNT_LOCKED", "OTP_INVALID", "OTP_EXPIRED",
             "RATE_LIMITED", "OFFLINE_GRACE_EXPIRED", "PAYLOAD_TOO_LARGE", "INTERNAL_ERROR"]}
schemas["ErrorResponse"] = {
    "type": "object", "description": "ADR-0004 section 3 error envelope.",
    "properties": {"success": {"type": "boolean", "enum": [False]},
                   "data": nullslot(),
                   "error": {"$ref": "#/components/schemas/ApiError"},
                   "meta": nullslot()},
    "required": ["success", "data", "error", "meta"]}

EXPOSE = [t for t, _, _, _, _ in RESOURCES] + ["claims", "users", "stores", "sessions",
                                               "roles", "permissions", "store_invites",
                                               "claim_access_grants", "audit_log"]

for t in EXPOSE:
    cols = TABLES[t]
    props = collections.OrderedDict()
    required = []
    for c in cols:
        props[c["name"]] = col_schema(c)
        if c["notnull"] and not c["default"]:
            required.append(c["name"])
    schemas[model(t)] = {"type": "object", "description": "Read model for `%s`." % t,
                         "properties": dict(props),
                         "required": required}

    if t in ("users", "stores", "sessions", "roles", "permissions", "audit_log",
             "claim_access_grants", "store_invites"):
        continue

    derived = DERIVED.get(t, set())
    wprops, wreq = collections.OrderedDict(), []
    for c in cols:
        n = c["name"]
        if n in SERVER_OWNED or n in derived:
            continue
        if n == "claim_id":       # comes from the path, never the body
            continue
        wprops[n] = col_schema(c)
        if c["notnull"] and not c["default"]:
            wreq.append(n)
    schemas[model(t) + "Create"] = {
        "type": "object", "additionalProperties": False,
        "description": ("Create payload for `%s`. `store_id` and `client_id` are taken from "
                        "the verified JWT and are rejected if present in the body "
                        "(ADR-0004 section 4)." % t),
        "properties": dict(wprops), "required": wreq}
    if t not in NO_UPDATE:
        schemas[model(t) + "Update"] = {
            "type": "object", "additionalProperties": False, "minProperties": 1,
            "description": "Partial update for `%s`. Absent fields are left unchanged." % t,
            "properties": dict(wprops)}

# Auth payloads
schemas.update({
 "RegisterRequest": {"type": "object", "additionalProperties": False,
   "description": "Registration always creates a NEW store (ADR-0005 D40). Joining an "
                  "existing store is invite-only via POST /auth/invites/accept.",
   "properties": {
     "full_name": {"type": "string", "minLength": 3, "maxLength": 150},
     "firm_name": {"type": "string", "minLength": 2, "maxLength": 200},
     "email": {"type": "string", "format": "email"},
     "mobile": {"type": "string", "pattern": r"^\+[1-9][0-9]{7,14}$", "example": "+919876543210"},
     "password": {"type": "string", "minLength": 8, "format": "password",
                  "description": "Min 8 chars, >=1 uppercase, >=1 number, >=1 special "
                                 "(00_auth_signup.md section 4)."},
     "sla_license_no": {"type": "string", "nullable": True,
                        "description": "Optional at signup (D35); required before FSR sign-off."},
     "sla_category": {"$ref": "#/components/schemas/SlaCategoryOrNull"},
     "base_location": {"type": "string", "nullable": True, "maxLength": 120},
     "terms_accepted": {"type": "boolean", "enum": [True]},
     "terms_version": {"type": "string", "maxLength": 16},
     "device": {"$ref": "#/components/schemas/DeviceInfo"}},
   "required": ["full_name", "firm_name", "email", "mobile", "password",
                "terms_accepted", "terms_version", "device"]},
 "DeviceInfo": {"type": "object", "additionalProperties": False,
   "properties": {"device_id": {"type": "string", "maxLength": 128},
                  "device_name": {"type": "string", "nullable": True, "maxLength": 120},
                  "platform": {"$ref": "#/components/schemas/DevicePlatform"},
                  "model": {"type": "string", "nullable": True},
                  "os_version": {"type": "string", "nullable": True},
                  "app_version": {"type": "string", "nullable": True}},
   "required": ["device_id", "platform"]},
 "LoginRequest": {"type": "object", "additionalProperties": False,
   "properties": {
     "identifier": {"type": "string",
       "description": "Universal identifier: email, 10-digit +91 mobile, or username "
                      "(CR-A1). Resolved globally; identifiers are unique across all "
                      "stores (ADR-0005 D43)."},
     "password": {"type": "string", "format": "password"},
     "remember_me": {"type": "boolean", "default": True},
     "device": {"$ref": "#/components/schemas/DeviceInfo"}},
   "required": ["identifier", "password", "device"]},
 "TokenPair": {"type": "object",
   "description": "ADR-0003 dual token. The access token is RS256 and lives 15 minutes; "
                  "the refresh token is a 64-byte opaque value, rotated on every use, "
                  "and must be stored in the iOS Keychain / Android Keystore.",
   "properties": {
     "access_token": {"type": "string"},
     "access_token_expires_at": {"type": "string", "format": "date-time"},
     "refresh_token": {"type": "string"},
     "refresh_token_expires_at": {"type": "string", "format": "date-time"},
     "session_id": {"type": "string", "format": "uuid"},
     "offline_grace_until": {"type": "string", "format": "date-time",
                             "description": "30-day offline grace (CR-A12)."}},
   "required": ["access_token", "access_token_expires_at", "refresh_token",
                "refresh_token_expires_at", "session_id"]},
 "AuthSession": {"type": "object",
   "properties": {"tokens": {"$ref": "#/components/schemas/TokenPair"},
                  "user": {"$ref": "#/components/schemas/User"},
                  "store": {"$ref": "#/components/schemas/Store"},
                  "roles": {"type": "array", "items": {"type": "string"}},
                  "permissions": {"type": "array", "items": {"type": "string"}}},
   "required": ["tokens", "user", "store", "roles", "permissions"]},
 "RefreshRequest": {"type": "object", "additionalProperties": False,
   "properties": {"refresh_token": {"type": "string"},
                  "device_id": {"type": "string", "maxLength": 128}},
   "required": ["refresh_token", "device_id"]},
 "OtpRequest": {"type": "object", "additionalProperties": False,
   "properties": {"identifier": {"type": "string"},
                  "channel": {"$ref": "#/components/schemas/OtpChannel"},
                  "purpose": {"$ref": "#/components/schemas/OtpPurpose"}},
   "required": ["identifier", "channel", "purpose"]},
 "OtpChallengeAccepted": {"type": "object",
   "description": "Deliberately reveals nothing about whether the identifier exists.",
   "properties": {"challenge_id": {"type": "string", "format": "uuid"},
                  "resend_available_at": {"type": "string", "format": "date-time",
                    "description": "SMS 30 s, email 45 s (D33)."},
                  "expires_at": {"type": "string", "format": "date-time"}},
   "required": ["challenge_id", "resend_available_at", "expires_at"]},
 "OtpVerifyRequest": {"type": "object", "additionalProperties": False,
   "properties": {"challenge_id": {"type": "string", "format": "uuid"},
                  "code": {"type": "string", "pattern": "^[0-9]{6}$"},
                  "device": {"$ref": "#/components/schemas/DeviceInfo"}},
   "required": ["challenge_id", "code", "device"]},
 "ForgotPasswordRequest": {"type": "object", "additionalProperties": False,
   "properties": {"identifier": {"type": "string"}}, "required": ["identifier"]},
 "ResetPasswordRequest": {"type": "object", "additionalProperties": False,
   "properties": {"token": {"type": "string"},
                  "new_password": {"type": "string", "minLength": 8, "format": "password"}},
   "required": ["token", "new_password"]},
 "AcceptInviteRequest": {"type": "object", "additionalProperties": False,
   "properties": {"token": {"type": "string"},
                  "full_name": {"type": "string", "minLength": 3},
                  "password": {"type": "string", "minLength": 8, "format": "password"},
                  "terms_accepted": {"type": "boolean", "enum": [True]},
                  "terms_version": {"type": "string"},
                  "device": {"$ref": "#/components/schemas/DeviceInfo"}},
   "required": ["token", "full_name", "password", "terms_accepted", "terms_version", "device"]},
 "StageAdvanceRequest": {"type": "object", "additionalProperties": False,
   "properties": {"to_stage": {"type": "integer", "minimum": 1, "maximum": 15},
                  "note": {"type": "string", "nullable": True}},
   "required": ["to_stage"]},
 "ApprovalGateRequest": {"type": "object", "additionalProperties": False,
   "description": "FR-14.4. All four points must be true in one request; the server "
                  "timestamps each and writes an audit_log APPROVE row. Export stays "
                  "blocked until every point is recorded (CLAUDE.md 14.4).",
   "properties": {
     "reviewed_ai_content": {"type": "boolean", "enum": [True]},
     "confirmed_factual_accuracy": {"type": "boolean", "enum": [True]},
     "confirmed_calculations": {"type": "boolean", "enum": [True]},
     "accepted_professional_responsibility": {"type": "boolean", "enum": [True]}},
   "required": ["reviewed_ai_content", "confirmed_factual_accuracy",
                "confirmed_calculations", "accepted_professional_responsibility"]},
 "ExportRequest": {"type": "object", "additionalProperties": False,
   "properties": {"engine": {"type": "string", "enum": ["server"], "default": "server",
     "description": "Only the server engine is authoritative (D22). A client-generated "
                    "offline draft is uploaded through the media endpoints instead."}}},
 "SignOffRequest": {"type": "object", "additionalProperties": False,
   "properties": {"surveyor_signature_media_id": {"type": "string", "format": "uuid"},
                  "declaration_accepted": {"type": "boolean", "enum": [True]}},
   "required": ["surveyor_signature_media_id", "declaration_accepted"]},
 "MediaUploadInit": {"type": "object", "additionalProperties": False,
   "properties": {"media_attachment_id": {"type": "string", "format": "uuid"},
                  "byte_size": {"type": "integer", "format": "int64", "minimum": 1},
                  "sha256": {"type": "string", "pattern": "^[0-9a-f]{64}$"},
                  "mime_type": {"type": "string"},
                  "chunk_size_bytes": {"type": "integer", "default": 5242880}},
   "required": ["media_attachment_id", "byte_size", "sha256", "mime_type"]},
 "MediaUploadTicket": {"type": "object",
   "properties": {"upload_id": {"type": "string"},
                  "chunk_size_bytes": {"type": "integer"},
                  "chunk_count": {"type": "integer"},
                  "expires_at": {"type": "string", "format": "date-time"}},
   "required": ["upload_id", "chunk_size_bytes", "chunk_count", "expires_at"]},
 "SyncPushRequest": {"type": "object", "additionalProperties": False,
   "description": "PROVISIONAL. sprint_0002 is the sync spike and owns this shape.",
   "properties": {
     "device_id": {"type": "string", "maxLength": 128},
     "since_revision": {"type": "integer", "format": "int64"},
     "changes": {"type": "array", "items": {"$ref": "#/components/schemas/SyncChange"}}},
   "required": ["device_id", "changes"]},
 "SyncChange": {"type": "object", "additionalProperties": False,
   "properties": {
     "entity": {"type": "string", "example": "assessment_line_items"},
     "entity_id": {"type": "string", "format": "uuid",
                   "description": "Client-generated UUIDv4, adopted verbatim by the server."},
     "claim_id": {"type": "string", "format": "uuid", "nullable": True},
     "operation": {"$ref": "#/components/schemas/SyncOperation"},
     "payload": {"type": "object", "additionalProperties": True},
     "field_updated_at": {"type": "object", "additionalProperties": {"type": "string",
                          "format": "date-time"},
       "description": "Per-field device timestamps. This is what makes AC 16.1.3 a "
                      "field-level merge rather than last-write-wins."},
     "base_sync_revision": {"type": "integer", "format": "int64", "nullable": True},
     "client_updated_at": {"type": "string", "format": "date-time"}},
   "required": ["entity", "entity_id", "operation", "payload", "field_updated_at",
                "client_updated_at"]},
 "SyncPushResult": {"type": "object",
   "properties": {
     "accepted": {"type": "array", "items": {"$ref": "#/components/schemas/SyncAccepted"}},
     "conflicts": {"type": "array", "items": {"$ref": "#/components/schemas/SyncConflict"}},
     "server_revision": {"type": "integer", "format": "int64"}},
   "required": ["accepted", "conflicts", "server_revision"]},
 "SyncAccepted": {"type": "object",
   "properties": {"entity": {"type": "string"},
                  "entity_id": {"type": "string", "format": "uuid"},
                  "sync_revision": {"type": "integer", "format": "int64"},
                  "server_assigned": {"type": "object", "additionalProperties": True,
                    "description": "Server-allocated values the device could not know, "
                                   "e.g. claims.claim_ref_no (FR-1.3)."}},
   "required": ["entity", "entity_id", "sync_revision"]},
 "SyncConflict": {"type": "object",
   "description": "Returned per field, never per row. The surveyor confirms the "
                  "resolution (AC 16.1.3); the server never picks a winner silently.",
   "properties": {"entity": {"type": "string"},
                  "entity_id": {"type": "string", "format": "uuid"},
                  "fields": {"type": "object", "additionalProperties": {
                    "type": "object",
                    "properties": {"local": {}, "server": {},
                                   "local_at": {"type": "string", "format": "date-time"},
                                   "server_at": {"type": "string", "format": "date-time"}}}}},
   "required": ["entity", "entity_id", "fields"]},
 "SyncPullResult": {"type": "object",
   "properties": {"changes": {"type": "array", "items": {"$ref": "#/components/schemas/SyncChange"}},
                  "server_revision": {"type": "integer", "format": "int64"},
                  "has_more": {"type": "boolean"}},
   "required": ["changes", "server_revision", "has_more"]},
 "HealthStatus": {"type": "object",
   "properties": {"status": {"type": "string", "enum": ["ok", "degraded"]},
                  "version": {"type": "string"},
                  "database": {"type": "string", "enum": ["up", "down"]}},
   "required": ["status", "version", "database"]},
})


NULLABLE_ENUMS.add("sla_category")
for _e in sorted(NULLABLE_ENUMS):
    schemas[pascal(_e) + "OrNull"] = {
        "type": "string", "nullable": True, "enum": ENUMS[_e],
        "description": "Nullable `%s`. OAS 3.0 cannot express a nullable $ref, so this "
                       "companion schema carries the same value list." % _e}


def ok(ref, array=False, paged=False):
    data = ({"type": "array", "items": {"$ref": "#/components/schemas/" + ref}}
            if array else {"$ref": "#/components/schemas/" + ref})
    props = {"success": {"type": "boolean", "enum": [True]},
             "data": data,
             "error": nullslot(),
             "meta": ({"$ref": "#/components/schemas/Meta"} if paged else nullslot())}
    return {"type": "object", "properties": props,
            "required": ["success", "data", "error", "meta"]}


def resp(desc, ref=None, array=False, paged=False):
    if ref is None:
        return {"description": desc}
    return {"description": desc,
            "content": {"application/json": {"schema": ok(ref, array, paged)}}}


def body(ref, required=True):
    return {"required": required,
            "content": {"application/json": {
                "schema": {"$ref": "#/components/schemas/" + ref}}}}


ERR = {
 "401": {"$ref": "#/components/responses/Unauthenticated"},
 "403": {"$ref": "#/components/responses/Forbidden"},
 "404": {"$ref": "#/components/responses/NotFound"},
 "409": {"$ref": "#/components/responses/Conflict"},
 "422": {"$ref": "#/components/responses/ValidationFailed"},
 "429": {"$ref": "#/components/responses/RateLimited"},
 "500": {"$ref": "#/components/responses/InternalError"},
}


def errs(*codes):
    return {c: ERR[c] for c in codes}


# ------------------------------------------------------------------ paths
paths = collections.OrderedDict()

paths["/healthz"] = {"get": {
    "tags": ["System"], "summary": "Liveness and database reachability",
    "security": [], "operationId": "getHealth",
    "responses": {"200": resp("Service healthy.", "HealthStatus"),
                  "503": {"$ref": "#/components/responses/InternalError"}}}}

AUTH = [
 ("/auth/register", "post", "registerSurveyor", "Register a surveyor and create a new store",
  "RegisterRequest", "AuthSession", "201", ["409", "422", "429"], True),
 ("/auth/login", "post", "login", "Log in with a universal identifier and password",
  "LoginRequest", "AuthSession", "200", ["401", "422", "429"], True),
 ("/auth/refresh", "post", "refreshToken", "Rotate the refresh token",
  "RefreshRequest", "TokenPair", "200", ["401", "429"], True),
 ("/auth/otp/request", "post", "requestOtp", "Request a phone or email OTP",
  "OtpRequest", "OtpChallengeAccepted", "202", ["422", "429"], True),
 ("/auth/otp/verify", "post", "verifyOtp", "Verify an OTP and start a session",
  "OtpVerifyRequest", "AuthSession", "200", ["401", "422", "429"], True),
 ("/auth/password/forgot", "post", "forgotPassword", "Request a password reset link",
  "ForgotPasswordRequest", None, "202", ["429"], True),
 ("/auth/password/reset", "post", "resetPassword", "Complete a password reset",
  "ResetPasswordRequest", None, "204", ["401", "422", "429"], True),
 ("/auth/invites/accept", "post", "acceptInvite", "Accept a store invite and create an account",
  "AcceptInviteRequest", "AuthSession", "201", ["401", "409", "422"], True),
]
for path, method, opid, summary, req, res, code, ecodes, public in AUTH:
    op = {"tags": ["Auth"], "summary": summary, "operationId": opid,
          "requestBody": body(req),
          "responses": {code: (resp("Success.", res) if res else resp("Accepted. No content."))}}
    op["responses"].update(errs(*ecodes))
    if public:
        op["security"] = []
    paths[path] = {method: op}

paths["/auth/logout"] = {"post": {
    "tags": ["Auth"], "summary": "Log out the current session", "operationId": "logout",
    "responses": dict({"204": resp("Session ended.")}, **errs("401"))}}
paths["/auth/logout-all"] = {"post": {
    "tags": ["Auth"], "summary": "Log out every session for the current user",
    "operationId": "logoutAll",
    "responses": dict({"204": resp("All sessions ended.")}, **errs("401"))}}
paths["/auth/me"] = {"get": {
    "tags": ["Auth"], "summary": "The authenticated user, roles and effective permissions",
    "operationId": "getCurrentUser",
    "responses": dict({"200": resp("Current identity.", "AuthSession")}, **errs("401"))}}
paths["/auth/sessions"] = {"get": {
    "tags": ["Auth"], "summary": "List active sessions for the current user",
    "operationId": "listSessions",
    "responses": dict({"200": resp("Sessions.", "Session", array=True)}, **errs("401"))}}
paths["/auth/sessions/{sessionId}"] = {"delete": {
    "tags": ["Auth"], "summary": "Revoke one session", "operationId": "revokeSession",
    "parameters": [{"name": "sessionId", "in": "path", "required": True,
                    "schema": {"type": "string", "format": "uuid"}}],
    "responses": dict({"204": resp("Revoked.")}, **errs("401", "403", "404"))}}

paths["/store-invites"] = {
 "get": {"tags": ["Store"], "summary": "List invites for the current store",
         "operationId": "listStoreInvites",
         "parameters": [{"$ref": "#/components/parameters/Page"},
                        {"$ref": "#/components/parameters/Limit"}],
         "responses": dict({"200": resp("Invites.", "StoreInvite", array=True, paged=True)},
                           **errs("401", "403"))},
 "post": {"tags": ["Store"], "summary": "Issue a store invite",
          "description": "Requires `user:invite`. The only path into an existing store "
                         "(ADR-0005 D40).",
          "operationId": "createStoreInvite",
          "requestBody": {"required": True, "content": {"application/json": {"schema": {
              "type": "object", "additionalProperties": False,
              "properties": {"email": {"type": "string", "format": "email", "nullable": True},
                             "mobile": {"type": "string", "nullable": True},
                             "role_id": {"type": "string", "format": "uuid"}},
              "required": ["role_id"]}}}},
          "responses": dict({"201": resp("Invite issued.", "StoreInvite")},
                            **errs("401", "403", "422"))}}
paths["/store-invites/{inviteId}"] = {"delete": {
    "tags": ["Store"], "summary": "Revoke a pending invite", "operationId": "revokeStoreInvite",
    "parameters": [{"name": "inviteId", "in": "path", "required": True,
                    "schema": {"type": "string", "format": "uuid"}}],
    "responses": dict({"204": resp("Revoked.")}, **errs("401", "403", "404"))}}

paths["/claims"] = {
 "get": {"tags": ["Claims"], "summary": "List claims in the current store",
   "description": "Scoped to the JWT `store_id`. An INSURER_VIEWER sees only claims with "
                  "a live `claim_access_grants` row.",
   "operationId": "listClaims",
   "parameters": [{"$ref": "#/components/parameters/Page"},
                  {"$ref": "#/components/parameters/Limit"},
                  {"name": "stage", "in": "query", "schema": {"type": "integer", "minimum": 1,
                   "maximum": 15}, "description": "Filter by current stage."},
                  {"name": "status", "in": "query",
                   "schema": {"$ref": "#/components/schemas/ClaimStatus"}},
                  {"name": "insurer_name", "in": "query", "schema": {"type": "string"}},
                  {"name": "q", "in": "query", "schema": {"type": "string", "maxLength": 100},
                   "description": "Search claim ref, insured, insurer and policy number."},
                  {"name": "loss_date_from", "in": "query",
                   "schema": {"type": "string", "format": "date"}},
                  {"name": "loss_date_to", "in": "query",
                   "schema": {"type": "string", "format": "date"}}],
   "responses": dict({"200": resp("Claims.", "Claim", array=True, paged=True)},
                     **errs("401", "403"))},
 "post": {"tags": ["Claims"], "summary": "Create a claim from an insurer appointment",
   "description": "`claim_ref_no` is allocated by the server (FR-1.3). A claim created "
                  "offline carries `temp_ref_no` until its first sync.",
   "operationId": "createClaim", "requestBody": body("ClaimCreate"),
   "responses": dict({"201": resp("Created.", "Claim")}, **errs("401", "403", "409", "422"))}}

paths["/claims/{claimId}"] = {
 "parameters": [{"$ref": "#/components/parameters/ClaimId"}],
 "get": {"tags": ["Claims"], "summary": "Fetch one claim", "operationId": "getClaim",
   "responses": dict({"200": resp("Claim.", "Claim")}, **errs("401", "403", "404"))},
 "patch": {"tags": ["Claims"], "summary": "Update a claim", "operationId": "updateClaim",
   "requestBody": body("ClaimUpdate"),
   "responses": dict({"200": resp("Updated.", "Claim")},
                     **errs("401", "403", "404", "409", "422"))},
 "delete": {"tags": ["Claims"], "summary": "Soft-delete a claim", "operationId": "deleteClaim",
   "responses": dict({"204": resp("Soft-deleted; a tombstone is retained for sync.")},
                     **errs("401", "403", "404"))}}

paths["/claims/{claimId}/stage-advance"] = {
 "parameters": [{"$ref": "#/components/parameters/ClaimId"}],
 "post": {"tags": ["Claims"], "summary": "Advance the claim state machine",
   "description": "Each stage's save-gate preconditions are checked here. A failure "
                  "returns STAGE_PRECONDITION_FAILED with the unmet rules in `details`.",
   "operationId": "advanceClaimStage", "requestBody": body("StageAdvanceRequest"),
   "responses": dict({"200": resp("Advanced.", "Claim")},
                     **errs("401", "403", "404", "409", "422"))}}

paths["/claims/{claimId}/audit-log"] = {
 "parameters": [{"$ref": "#/components/parameters/ClaimId"}],
 "get": {"tags": ["Audit"], "summary": "Read the immutable audit trail for a claim",
   "description": "Append-only. Requires `audit:read`.", "operationId": "listClaimAuditLog",
   "parameters": [{"$ref": "#/components/parameters/Page"},
                  {"$ref": "#/components/parameters/Limit"}],
   "responses": dict({"200": resp("Audit entries.", "AuditLog", array=True, paged=True)},
                     **errs("401", "403", "404"))}}

for table, seg, singleton, stage, label in RESOURCES:
    m = model(table)
    tag = "Stage %02d" % stage if stage else "Cross-stage"
    base = "/claims/{claimId}/" + seg
    if singleton:
        paths[base] = {
         "parameters": [{"$ref": "#/components/parameters/ClaimId"}],
         "get": {"tags": [tag], "summary": "Fetch the %s" % label.lower(),
           "operationId": "get" + m,
           "responses": dict({"200": resp(label + ".", m)}, **errs("401", "403", "404"))},
         "put": {"tags": [tag], "summary": "Create or replace the %s" % label.lower(),
           "operationId": "put" + m, "requestBody": body(m + "Create"),
           "responses": dict({"200": resp("Saved.", m)},
                             **errs("401", "403", "404", "409", "422"))},
         "patch": {"tags": [tag], "summary": "Partially update the %s" % label.lower(),
           "operationId": "update" + m, "requestBody": body(m + "Update"),
           "responses": dict({"200": resp("Updated.", m)},
                             **errs("401", "403", "404", "409", "422"))}}
        continue

    coll = {"parameters": [{"$ref": "#/components/parameters/ClaimId"}],
            "get": {"tags": [tag], "summary": "List %s" % label.lower(),
              "operationId": "list" + m + "s",
              "parameters": [{"$ref": "#/components/parameters/Page"},
                             {"$ref": "#/components/parameters/Limit"}],
              "responses": dict({"200": resp(label + ".", m, array=True, paged=True)},
                                **errs("401", "403", "404"))}}
    if table not in ("pre_submission_audits",):
        coll["post"] = {"tags": [tag], "summary": "Create a %s entry" % label.lower(),
                        "operationId": "create" + m, "requestBody": body(m + "Create"),
                        "responses": dict({"201": resp("Created.", m)},
                                          **errs("401", "403", "404", "409", "422"))}
    paths[base] = coll

    item = {"parameters": [{"$ref": "#/components/parameters/ClaimId"},
                           {"name": "id", "in": "path", "required": True,
                            "schema": {"type": "string", "format": "uuid"}}],
            "get": {"tags": [tag], "summary": "Fetch one entry", "operationId": "get" + m,
                    "responses": dict({"200": resp(label + ".", m)},
                                      **errs("401", "403", "404"))}}
    if table not in NO_UPDATE:
        item["patch"] = {"tags": [tag], "summary": "Update one entry",
                         "operationId": "update" + m, "requestBody": body(m + "Update"),
                         "responses": dict({"200": resp("Updated.", m)},
                                           **errs("401", "403", "404", "409", "422"))}
    if table not in NO_DELETE:
        item["delete"] = {"tags": [tag], "summary": "Soft-delete one entry",
                          "operationId": "delete" + m,
                          "responses": dict({"204": resp("Soft-deleted.")},
                                            **errs("401", "403", "404"))}
    paths[base + "/{id}"] = item

# Stage-specific actions
paths["/claims/{claimId}/preliminary-reports/{id}/approval-gate"] = {
 "parameters": [{"$ref": "#/components/parameters/ClaimId"},
                {"name": "id", "in": "path", "required": True,
                 "schema": {"type": "string", "format": "uuid"}}],
 "post": {"tags": ["Stage 08"], "summary": "Record the 4-point Human Approval Gate for a PSR",
   "operationId": "approvePreliminaryReport", "requestBody": body("ApprovalGateRequest"),
   "responses": dict({"200": resp("Recorded.", "PreliminarySurveyReport")},
                     **errs("401", "403", "404", "422"))}}
paths["/claims/{claimId}/preliminary-reports/{id}/export"] = {
 "parameters": [{"$ref": "#/components/parameters/ClaimId"},
                {"name": "id", "in": "path", "required": True,
                 "schema": {"type": "string", "format": "uuid"}}],
 "post": {"tags": ["Stage 08"], "summary": "Generate the PSR .docx",
   "description": "Blocked with APPROVAL_GATE_NOT_SATISFIED until all four gate points "
                  "are recorded (CLAUDE.md 14.4).",
   "operationId": "exportPreliminaryReport", "requestBody": body("ExportRequest", False),
   "responses": dict({"200": resp("Generated.", "PreliminarySurveyReport")},
                     **errs("401", "403", "404", "409", "422"))}}
paths["/claims/{claimId}/final-reports/{id}/draft-narrative"] = {
 "parameters": [{"$ref": "#/components/parameters/ClaimId"},
                {"name": "id", "in": "path", "required": True,
                 "schema": {"type": "string", "format": "uuid"}}],
 "post": {"tags": ["Stage 14"], "summary": "Request an AI-4 narrative draft for sections C, D, H or I",
   "description": "AI drafting is confined to sections C, D, H and I (FR-14.2). Returned "
                  "blocks carry `source: AI_DRAFT` and are inert until a human accepts "
                  "them; missing facts come back as `[SURVEYOR TO VERIFY]`, never invented "
                  "(CLAUDE.md 14.3). Requires `ai:invoke`.",
   "operationId": "draftFinalReportNarrative",
   "requestBody": {"required": True, "content": {"application/json": {"schema": {
     "type": "object", "additionalProperties": False,
     "properties": {"sections": {"type": "array", "minItems": 1,
                      "items": {"type": "string", "enum": ["C", "D", "H", "I"]}}},
     "required": ["sections"]}}}},
   "responses": dict({"200": resp("Draft produced.", "FinalSurveyReport")},
                     **errs("401", "403", "404", "422", "429"))}}
paths["/claims/{claimId}/final-reports/{id}/approval-gate"] = {
 "parameters": [{"$ref": "#/components/parameters/ClaimId"},
                {"name": "id", "in": "path", "required": True,
                 "schema": {"type": "string", "format": "uuid"}}],
 "post": {"tags": ["Stage 14"], "summary": "Record the 4-point Human Approval Gate for the FSR",
   "operationId": "approveFinalReport", "requestBody": body("ApprovalGateRequest"),
   "responses": dict({"200": resp("Recorded.", "FinalSurveyReport")},
                     **errs("401", "403", "404", "422"))}}
paths["/claims/{claimId}/final-reports/{id}/export"] = {
 "parameters": [{"$ref": "#/components/parameters/ClaimId"},
                {"name": "id", "in": "path", "required": True,
                 "schema": {"type": "string", "format": "uuid"}}],
 "post": {"tags": ["Stage 14"], "summary": "Generate the FSR .docx",
   "description": "Server-side Go engine; the CR-NF5 benchmark (9 sections, up to 50 photo "
                  "plates, under 5 s) applies here. Blocked until the approval gate is complete.",
   "operationId": "exportFinalReport", "requestBody": body("ExportRequest", False),
   "responses": dict({"200": resp("Generated.", "FinalSurveyReport")},
                     **errs("401", "403", "404", "409", "422"))}}
paths["/claims/{claimId}/pre-submission-audits/run"] = {
 "parameters": [{"$ref": "#/components/parameters/ClaimId"}],
 "post": {"tags": ["Stage 15"], "summary": "Run the seven compliance gates",
   "description": "FR-15.1. Always returns 200 with the run; a failing gate is a result, "
                  "not an HTTP error. Submission stays blocked until every gate passes.",
   "operationId": "runPreSubmissionAudit",
   "requestBody": {"required": True, "content": {"application/json": {"schema": {
     "type": "object", "additionalProperties": False,
     "properties": {"final_survey_report_id": {"type": "string", "format": "uuid"}},
     "required": ["final_survey_report_id"]}}}},
   "responses": dict({"200": resp("Audit run recorded.", "PreSubmissionAudit")},
                     **errs("401", "403", "404", "422"))}}
paths["/claims/{claimId}/final-reports/{id}/sign-off"] = {
 "parameters": [{"$ref": "#/components/parameters/ClaimId"},
                {"name": "id", "in": "path", "required": True,
                 "schema": {"type": "string", "format": "uuid"}}],
 "post": {"tags": ["Stage 15"], "summary": "Sign off the FSR and take the SHA-256 snapshot",
   "description": "Requires a passing audit run, the four approval points, and a licence "
                  "number and category on the signing surveyor (D35). Writes an "
                  "audit_log SIGN_OFF row.",
   "operationId": "signOffFinalReport", "requestBody": body("SignOffRequest"),
   "responses": dict({"200": resp("Signed off.", "FinalSurveyReport")},
                     **errs("401", "403", "404", "409", "422"))}}

paths["/media/uploads"] = {"post": {
 "tags": ["Media"], "summary": "Start a chunked media upload",
 "description": "Section 6.1 chunked pipeline. The photo is already compressed to "
                "1600x1200 at 85% and watermarked on the device before this call.",
 "operationId": "initMediaUpload", "requestBody": body("MediaUploadInit"),
 "responses": dict({"201": resp("Upload ticket.", "MediaUploadTicket")},
                   **errs("401", "403", "409", "422"))}}
paths["/media/uploads/{uploadId}/chunks/{index}"] = {"put": {
 "tags": ["Media"], "summary": "Upload one chunk", "operationId": "uploadMediaChunk",
 "parameters": [{"name": "uploadId", "in": "path", "required": True,
                 "schema": {"type": "string"}},
                {"name": "index", "in": "path", "required": True,
                 "schema": {"type": "integer", "minimum": 0}}],
 "requestBody": {"required": True, "content": {
   "application/octet-stream": {"schema": {"type": "string", "format": "binary"}}}},
 "responses": dict({"204": resp("Chunk stored.")},
                   **errs("401", "403", "404", "409"))}}
paths["/media/uploads/{uploadId}/complete"] = {"post": {
 "tags": ["Media"], "summary": "Finalise an upload",
 "description": "The server recomputes SHA-256 and rejects a mismatch with CONFLICT.",
 "operationId": "completeMediaUpload",
 "parameters": [{"name": "uploadId", "in": "path", "required": True,
                 "schema": {"type": "string"}}],
 "responses": dict({"200": resp("Upload complete.", "MediaAttachment")},
                   **errs("401", "403", "404", "409"))}}

paths["/sync/push"] = {"post": {
 "tags": ["Sync"], "summary": "Push local changes",
 "description": "PROVISIONAL -- sprint_0002 owns this contract. Conflicts come back "
                "per field, never per row, and are never resolved silently (AC 16.1.3).",
 "operationId": "syncPush", "requestBody": body("SyncPushRequest"),
 "responses": dict({"200": resp("Applied, with any conflicts.", "SyncPushResult")},
                   **errs("401", "403", "409", "422"))}}
paths["/sync/pull"] = {"get": {
 "tags": ["Sync"], "summary": "Pull server changes since a revision",
 "description": "PROVISIONAL -- sprint_0002 owns this contract.",
 "operationId": "syncPull",
 "parameters": [{"name": "device_id", "in": "query", "required": True,
                 "schema": {"type": "string", "maxLength": 128}},
                {"name": "since_revision", "in": "query", "required": True,
                 "schema": {"type": "integer", "format": "int64"}},
                {"name": "limit", "in": "query",
                 "schema": {"type": "integer", "minimum": 1, "maximum": 500, "default": 200}}],
 "responses": dict({"200": resp("Changes.", "SyncPullResult")}, **errs("401", "403", "422"))}}

# ------------------------------------------------------------------ document
def errresp(desc):
    return {"description": desc,
            "content": {"application/json": {
                "schema": {"$ref": "#/components/schemas/ErrorResponse"}}}}


doc = collections.OrderedDict()
doc["openapi"] = "3.0.3"
doc["info"] = {
 "title": "SurvScribe API",
 "version": "1.0.0",
 "description": (
   "REST/JSON contract for the SurvScribe platform: Stage 0 authentication and the "
   "15-stage general claim survey workflow.\n\n"
   "**Change control.** This contract is frozen at v1.0.0 under `sprint_0001` task 3. "
   "It is not immutable, but it is not edited casually either: an additive change "
   "(a new optional field, a new endpoint) is a minor version bump; anything that could "
   "break a shipped mobile client -- a removed or renamed field, a narrowed type, a new "
   "required request property, a removed enum value -- requires an ADR and a major bump, "
   "because a field surveyor may be running an old build offline for up to 30 days "
   "(CR-A12) and cannot be forced to update.\n\n"
   "**Generated, not hand-written.** Every entity schema here is derived from the DDL in "
   "`apps/backend/migrations/`, which is itself extracted from "
   "`documentation/architecture/physical-schema.md`. Contract and database therefore "
   "cannot drift apart. Regenerate rather than edit entity schemas by hand.\n\n"
   "**Conventions (ADR-0004).** Base path `/api/v1`; plural kebab-case resources; every "
   "response uses the success or error envelope; list responses carry `meta` pagination.\n\n"
   "**Store isolation.** `store_id` is always taken from the verified JWT and is never "
   "accepted in a request body, query string or path (ADR-0004 section 4, "
   "`identity-and-rbac.md` section 3.2). It is absent from every `*Create` and `*Update` "
   "schema for that reason, and a body containing it is rejected -- the write schemas set "
   "`additionalProperties: false`.\n\n"
   "**Money is a string.** Every `NUMERIC` value crosses the wire as a decimal string, not "
   "a JSON number. IEEE-754 doubles cannot represent `NUMERIC(15,2)` exactly, and "
   "FR-15.1 gate 1 requires the Section F totals to reconcile to the rupee.\n\n"
   "**Regulatory.** The platform assists licensed surveyors; it is not an insurer, an "
   "intermediary, an IRDAI-approved entity, or an autonomous claims decision-maker. No "
   "endpoint approves or repudiates a claim, and no endpoint lets AI set or alter a "
   "monetary value."),
 "contact": {"name": "SurvScribe", "email": "vipul@tezminds.com"},
 "license": {"name": "Proprietary"}}
doc["servers"] = [
 {"url": "http://localhost:8080/api/v1", "description": "Local development"},
 {"url": "https://{host}/api/v1",
  "description": "Deployed environment. No environment has been provisioned yet -- the "
                 "host is supplied by configuration (ADR-0008), not hard-coded here.",
  "variables": {"host": {"default": "localhost:8080",
                         "description": "API host for the target environment."}}}]
doc["tags"] = ([{"name": "System", "description": "Health and diagnostics."},
                  {"name": "Auth", "description": "Stage 0 registration, login, tokens and sessions."},
                  {"name": "Store", "description": "The surveyor firm: invites and membership."},
                  {"name": "Claims", "description": "Claim files and the 15-stage state machine."}]
               + [{"name": "Stage %02d" % s,
                   "description": lbl} for _, _, _, s, lbl in RESOURCES if s]
               + [{"name": "Cross-stage",
                   "description": "Discrepancy flags raised by rules and AI across stages."},
                  {"name": "Audit",
                   "description": "The immutable audit trail (SRS 5.1 rule 3, 6.2)."},
                  {"name": "Media",
                   "description": "Chunked upload of watermarked evidence."},
                  {"name": "Sync",
                   "description": "Offline-first bi-directional sync. Provisional -- "
                                  "sprint_0002 owns this contract."}])
seen, tags = set(), []
for t in doc["tags"]:
    if t["name"] in seen:
        continue
    seen.add(t["name"])
    tags.append(t)
doc["tags"] = tags
doc["security"] = [{"bearerAuth": []}]
doc["paths"] = dict(paths)
doc["components"] = {
 "securitySchemes": {"bearerAuth": {
   "type": "http", "scheme": "bearer", "bearerFormat": "JWT",
   "description": "RS256 access token, 15-minute lifetime (ADR-0003). Claims: `sub`, "
                  "`store_id`, `client_id`, `sid`, `roles[]`, `perms[]`, `pv`. A "
                  "privilege change bumps `pv` on the user, so a stale token dies "
                  "within one lifetime."}},
 "parameters": {
   "ClaimId": {"name": "claimId", "in": "path", "required": True,
               "schema": {"type": "string", "format": "uuid"},
               "description": "Claim UUID. Client-generated when created offline."},
   "Page": {"name": "page", "in": "query",
            "schema": {"type": "integer", "minimum": 1, "default": 1}},
   "Limit": {"name": "limit", "in": "query",
             "schema": {"type": "integer", "minimum": 1, "maximum": 200, "default": 20}}},
 "responses": {
   "Unauthenticated": errresp("Missing, expired or invalid access token."),
   "Forbidden": errresp("Authenticated but not permitted: a missing permission, a "
                        "cross-store access attempt (STORE_SCOPE_VIOLATION), or an "
                        "insurer viewer with no live claim grant (CLAIM_GRANT_REQUIRED)."),
   "NotFound": errresp("No such resource within the caller's store."),
   "Conflict": errresp("State conflict: duplicate, stale revision, or a precondition "
                       "such as an unsatisfied approval gate."),
   "ValidationFailed": errresp("Field-level validation failure; see `error.details`."),
   "RateLimited": errresp("Too many requests."),
   "InternalError": errresp("Unexpected server error.")},
 "schemas": dict(schemas)}

# Drop component schemas that nothing reaches. The DDL defines enums for tables the API
# deliberately does not expose (auth telemetry, invites, OTP); shipping them in the
# contract would put dead types in the generated client.
def refs_in(node, acc):
    if isinstance(node, dict):
        for k, v in node.items():
            if k == "$ref" and isinstance(v, str) and v.startswith("#/components/schemas/"):
                acc.add(v.rsplit("/", 1)[1])
            else:
                refs_in(v, acc)
    elif isinstance(node, list):
        for v in node:
            refs_in(v, acc)
    return acc

reachable = refs_in({"paths": doc["paths"],
                     "responses": doc["components"]["responses"]}, set())
frontier = set(reachable)
while frontier:
    nxt = set()
    for name in frontier:
        if name in schemas:
            nxt |= refs_in(schemas[name], set())
    nxt -= reachable
    reachable |= nxt
    frontier = nxt

pruned = sorted(set(schemas) - reachable)
for name in pruned:
    del schemas[name]
doc["components"]["schemas"] = dict(schemas)

os.makedirs(os.path.dirname(OUT), exist_ok=True)


class Dumper(yaml.SafeDumper):
    def ignore_aliases(self, data):
        return True


def str_presenter(dumper, data):
    if "\n" in data:
        return dumper.represent_scalar("tag:yaml.org,2002:str", data, style="|")
    return dumper.represent_scalar("tag:yaml.org,2002:str", data)


Dumper.add_representer(str, str_presenter)
Dumper.add_representer(collections.OrderedDict,
                       lambda d, data: d.represent_dict(data.items()))

banner = ("# SurvScribe API contract v1 -- GENERATED FILE, DO NOT EDIT BY HAND.\n"
          "#\n"
          "# Regenerate with:  python apps/backend/scripts/gen_openapi.py\n"
          "# Entity schemas are derived from apps/backend/migrations/*.up.sql, which is\n"
          "# itself extracted from documentation/architecture/physical-schema.md.\n"
          "# Editing this file directly will be overwritten and will let the contract\n"
          "# drift from the database.\n#\n"
          "# Frozen at v1.0.0 under sprint_0001 task 3. See info.description for the\n"
          "# change-control rule.\n\n")

io.open(OUT, "w", encoding="utf-8", newline="\n").write(
    banner + yaml.dump(doc, Dumper=Dumper, sort_keys=False, allow_unicode=True,
                       default_flow_style=False, width=100))

print("wrote", OUT)
print("  enums   :", len(ENUMS))
print("  schemas :", len(schemas))
print("  paths   :", len(paths))
print("  ops     :", sum(1 for p in paths.values() for k in p if k != "parameters"))
print("  pruned  :", len(pruned), "unreferenced schema(s):", ", ".join(pruned) or "none")
