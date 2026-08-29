# Architecture

Engineering artifacts that support the SRS. These are the documents to produce before/alongside the first code.

## Contents

| File | Purpose | Status |
| :-- | :-- | :-- |
| [`physical-schema.md`](physical-schema.md) | Finalized PostgreSQL schema — every entity from `Requirement.MD` §5.2 (10 core + the entities added by ADR-0001 / D27), with column types, PK/FK, indexes, enum value lists, and JSON payload shapes. | **Identity slice delivered** (2026-08-30, ADR-0005) — awaiting owner approval. Claim-workflow entities remain `sprint_0001` task 1. |
| [`identity-and-rbac.md`](identity-and-rbac.md) | Runtime behaviour for identity: token contract, request pipeline, store isolation, auth flows, telemetry, threat model, Go and React Native layouts. | **Delivered** (2026-08-30, ADR-0005) — awaiting owner approval. |
| `api-contract/` | OpenAPI spec for the Gin REST API + shared TypeScript types. (Was `packages/api-contracts/`.) | Not started |
| `sync-protocol.md` | Offline sync queue, field-level timestamp merge, conflict-resolution UX. | Not started |
| `docx-template-contract.md` | Shared template spec that the client (TS) and server (Go) `.docx` engines must both satisfy (D22). | Not started |
| `system-diagrams/` | Context, container, and data-flow diagrams. | Not started |

## Key references
- Decisions: [`../decisions/`](../decisions/)
- Requirements: [`../Requirement.MD`](../Requirement.MD)
- Living project context: [`../../CLAUDE.md`](../../CLAUDE.md)
