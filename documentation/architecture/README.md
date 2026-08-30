# Architecture

Engineering artifacts that support the SRS. These are the documents to produce before/alongside the first code.

## Contents

| File | Purpose | Status |
| :-- | :-- | :-- |
| [`physical-schema.md`](physical-schema.md) | PostgreSQL schema, all 38 tables — Part A identity (finalized, ADR-0005) + Part B claim-workflow (drafted, `sprint_0001` task 1), with column types, PK/FK, indexes, enum value lists, and JSON payload shapes. | **Delivered** (2026-08-30) — awaiting owner approval, `CLAUDE.md` §16 Q12. |
| [`identity-and-rbac.md`](identity-and-rbac.md) | Runtime behaviour for identity: token contract, request pipeline, store isolation, auth flows, telemetry, threat model, Go and React Native layouts. | **Delivered** (2026-08-30, ADR-0005) — awaiting owner approval. |
| [`api-contract/openapi.yaml`](api-contract/openapi.yaml) | OpenAPI v1 spec for the Gin REST API, generated from the migration DDL; consumed as `@survscribe/types` (TS) and vendored by `packages/api-contracts/`. | **Delivered** (2026-08-30, `sprint_0001`) — lints clean, frozen under change control. |
| [`sync-protocol.md`](sync-protocol.md) | Offline sync queue, field-level timestamp merge, conflict-resolution UX, multi-device concurrency, media backoff. | **Delivered** (2026-08-30, `sprint_0002`) — awaiting owner approval. See `ADR-0010` for the algorithm choice behind it. |
| [`docx-template-contract.md`](docx-template-contract.md) | Shared template spec that the client (TS, deferred post-MVP per ADR-0009) and server (Go) `.docx` engines must both satisfy (D22). | **Delivered** (2026-08-30, `sprint_0002`) — awaiting owner approval. |
| `system-diagrams/` | Context, container, and data-flow diagrams. | Not started |

## Key references
- Decisions: [`../decisions/`](../decisions/)
- Requirements: [`../Requirement.MD`](../Requirement.MD)
- Living project context: [`../../CLAUDE.md`](../../CLAUDE.md)
