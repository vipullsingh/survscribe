# SurvScribe Backend Service (`apps/backend`)

Go + Gin REST API service for SurvScribe.

## Architecture Highlights
- **Framework**: Go 1.22+ with Gin web framework.
- **Database**: PostgreSQL with `pgx` driver and SQL migration scripts.
- **Authoritative Report Engine**: Server-side Go `.docx` template compiler meeting the `< 5s` / 50-photo-plate benchmark.

## Development Setup
```bash
cd apps/backend
go run cmd/server/main.go
```
