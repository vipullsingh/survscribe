# Architecture Decision Records (ADRs)

One record per significant, hard-to-reverse decision. Newest decisions get the next number; superseded ADRs are kept and marked `Superseded by ADR-XXXX`.

| ADR | Title | Status | Date |
| :-- | :-- | :-- | :-- |
| [ADR-0001](ADR-0001-foundational-stack-and-mvp-scope.md) | Foundational stack & MVP scope decisions | Accepted | 2026-08-30 |

## Pending ADRs (decision owed before the related work starts)

- Concrete SMS OTP provider (blocks Stage 0).
- Concrete transactional email provider (blocks Stage 0).
- Cloud LLM provider (blocks AI-3 / AI-4).
- Cloud OCR provider (blocks AI-2).
- Maps / reverse-geocoding provider (blocks Stage 4 geocoding).
- WhatsApp dispatch provider (blocks Stage 3 / Stage 8 notice dispatch).
- Session token format & lifetime (JWT vs opaque; refresh; offline expiry).
- Physical database schema (types, PK/FK, indexes, enum value lists, JSON shapes).
- API contract conventions (versioning, error envelope, pagination, auth header).
- Linter / formatter / test framework / branching strategy (when first code lands).
