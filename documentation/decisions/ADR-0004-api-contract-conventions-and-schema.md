# ADR-0004 — API Contract Conventions & Database Schema Design Rules

- **Status:** Accepted
- **Date:** 2026-08-30
- **Deciders:** Project owner (vipul@tezminds.com)
- **Context:** To ensure consistent REST JSON API design across backend and mobile client teams, standardized API envelopes, pagination protocols, error formats, and database schema principles are established.

---

## Decisions

### 1. REST JSON API Conventions
- **Base Endpoint Path:** `/api/v1`
- **URL Naming:** Plural kebab-case resources (e.g., `/api/v1/claims`, `/api/v1/loss-assessments`).

### 2. Standardized JSON Response Envelope
All API endpoints MUST respond using a uniform JSON envelope:
```json
{
  "success": true,
  "data": { ... },
  "error": null,
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 142
  }
}
```

### 3. Standardized Error Response Envelope
```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "Invalid license number format.",
    "details": [
      { "field": "license_number", "issue": "Must match regex SLA-[0-9]{4,8}" }
    ]
  },
  "meta": null
}
```

### 4. Database Schema Standards
- **Primary Keys:** UUIDv4 for public entities (`id`); BigInt auto-increment for internal sequence indexing.
- **Timestamp Strategy:** `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`, `updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`, `deleted_at TIMESTAMPTZ` (soft deletes for claims & documents).
- **Tenant Isolation:** Every operational table MUST include `tenant_id UUID NOT NULL REFERENCES tenants(id)`.

---

## Consequences

- Go backend middleware and React Native API client (`src/shared/api/client.ts`) will adopt these envelope structures and conventions across all 15 stages.
