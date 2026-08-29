# Architecture Decision Records (ADRs)

One record per significant, hard-to-reverse decision. Newest decisions get the next number; superseded ADRs are kept and marked `Superseded by ADR-XXXX`.

| ADR | Title | Status | Date |
| :-- | :-- | :-- | :-- |
| [ADR-0001](ADR-0001-foundational-stack-and-mvp-scope.md) | Foundational stack & MVP scope decisions | Accepted | 2026-08-30 |
| [ADR-0002](ADR-0002-concrete-vendor-selections.md) | Concrete external service vendor selections (SMS, Email, Maps, WhatsApp, LLM, OCR) | Accepted | 2026-08-30 |
| [ADR-0003](ADR-0003-session-token-and-auth-spec.md) | Session token, authentication & offline security specification | Accepted | 2026-08-30 |
| [ADR-0004](ADR-0004-api-contract-conventions-and-schema.md) | API contract conventions & database schema design rules | Accepted | 2026-08-30 |
| [ADR-0005](ADR-0005-identity-model-store-client-and-rbac.md) | Identity model: store/client naming, DB-driven RBAC, invite-only join & auth telemetry | Accepted | 2026-08-30 |
| [ADR-0006](ADR-0006-geoip-provider.md) | Geo-IP enrichment provider | Accepted | 2026-08-30 |

## Amendment chain

ADR-0005 amends three earlier records. Where they disagree, **ADR-0005 governs**:

| Amended | Section | Change |
| :-- | :-- | :-- |
| `Requirement.MD` | §5.1, §5.2 (entities 11–13) | `tenant_id` → `store_id`, `created_by_user_id` → `client_id`; finalized `users` / `stores` / `sessions` field lists |
| ADR-0003 | §1 | JWT claim set restated (`store_id`, `client_id`, `sid`, `roles`, `perms`, `pv`) |
| ADR-0003 | §3.1 | Idle lock is **passcode only** — biometrics deferred per ADR-0001 D32 (resolves Q3) |
| ADR-0004 | §4 | Tenant-isolation rule → `store_id UUID NOT NULL REFERENCES stores(id)` |

## Resolved ADR Tracker

All core architectural decisions, vendor selections, authentication mechanics, API conventions, and the identity/RBAC model are formally documented above.

The resulting engineering contract lives in [`../architecture/physical-schema.md`](../architecture/physical-schema.md) and [`../architecture/identity-and-rbac.md`](../architecture/identity-and-rbac.md).
