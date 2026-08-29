# Architecture

Engineering artifacts that support the SRS. Nothing here is built yet — these are the documents to produce before/alongside the first code.

## Planned contents

| File | Purpose | Status |
| :-- | :-- | :-- |
| `physical-schema.md` | Finalized PostgreSQL schema — every entity from `Requirement.MD` §5.2 (10 core + the entities added by ADR-0001 / D27), with column types, PK/FK, indexes, enum value lists, and JSON payload shapes. | Not started |
| `api-contract/` | OpenAPI spec for the Gin REST API + shared TypeScript types. (Was `packages/api-contracts/`.) | Not started |
| `sync-protocol.md` | Offline sync queue, field-level timestamp merge, conflict-resolution UX. | Not started |
| `docx-template-contract.md` | Shared template spec that the client (TS) and server (Go) `.docx` engines must both satisfy (D22). | Not started |
| `system-diagrams/` | Context, container, and data-flow diagrams. | Not started |

## Key references
- Decisions: [`../decisions/`](../decisions/)
- Requirements: [`../Requirement.MD`](../Requirement.MD)
- Living project context: [`../../CLAUDE.md`](../../CLAUDE.md)
