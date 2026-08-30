# SurvScribe Migrations — Runbook

> **Migrations are never executed automatically.** Not by the API server on boot, not by
> CI, not by a test harness, not by a script that "just sets things up". Every apply is a
> deliberate, human-initiated command against a database the operator has named. This is
> the `sprint_0001` task 2 rule and it is not negotiable.

---

## 1. What is here

| File range | Contents |
| :-- | :-- |
| `000001` | `citext` / `pgcrypto` extensions, `set_updated_at()` and `reject_mutation()` trigger functions |
| `000002` | All 50 enum types (identity + workflow) |
| `000003` | `stores`, `users`, and the deferred `stores.owner_user_id` foreign key |
| `000004` | `permissions`, `roles`, `role_permissions`, `user_roles`, `claim_access_grants` |
| `000005` | `sessions`, `user_devices`, `auth_events`, `store_invites`, `otp_challenges`, `password_reset_tokens` |
| `000006` | `claims`, `policy_details`, `policy_sections` |
| `000007` | `contact_logs`, `preservation_notices`, `site_visits`, `cause_investigations`, `chronology_events` |
| `000008` | `damage_items`, `media_attachments`, `documents`, `document_damage_links`, `document_line_items` |
| `000009` | `requisition_notices`, `preliminary_survey_reports`, `discrepancy_flags`, `assessment_heads`, `assessment_line_items`, `salvage_records`, `coverage_opinions`, `final_survey_reports`, `pre_submission_audits`, `report_dispatches` |
| `000010` | `audit_log` (append-only), `sync_queue` |
| `000011` | `claim_access_grants.claim_id → claims(id)` — deferred because the identity slice is created before `claims` |
| `000012` | Seed: the 38-code permission catalogue and the four system roles with their matrices |

**38 tables, 50 enum types, 246 statements.**

The single source of truth is
[`documentation/architecture/physical-schema.md`](../../../documentation/architecture/physical-schema.md).
The DDL in `000001`–`000010` is extracted verbatim from that document. **Change the
document first, then regenerate or amend the migration** — never the other way round, or
the schema document silently stops describing the database.

---

## 2. Status

**These migrations have never been executed.** They were authored on a machine with
neither Docker nor `psql` available, so nothing beyond a static structural check has been
run against them. Treat the first real apply as a review step, not a formality.

What *has* been verified:

```
python apps/backend/scripts/check_migrations.py
```

That checker reports 0 errors: no unbalanced parentheses or dollar-quotes, no
unterminated statements, no forward references (nothing is referenced before the
migration that creates it), every up-migration has a matching down-migration, and every
table and type is dropped by some down-migration. It is a structural check only — it is
not a PostgreSQL parser and cannot tell you the SQL is valid.

---

## 3. Local development database

`deployments/docker-compose.yml` brings up a throwaway PostgreSQL 16 for development
only. It is not a template for any deployed environment.

```bash
cd apps/backend
docker compose -f deployments/docker-compose.yml up -d
```

The container is named `survscribe-postgres-dev`, listens on **5433** (deliberately not
5432, so it cannot collide with a local Postgres that may hold real data), and uses the
credentials in `deployments/docker-compose.yml`. Those credentials are development-only
and are safe to have in the repository precisely because they only ever reach a
disposable container on `localhost`.

---

## 4. Applying migrations

The project uses [`golang-migrate`](https://github.com/golang-migrate/migrate) file
naming (`{version}_{name}.{up|down}.sql`).

```bash
# Install once
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

# Apply everything, against a database you have named explicitly
migrate -path apps/backend/migrations \
        -database "postgres://survscribe:devpassword@localhost:5433/survscribe_dev?sslmode=disable" \
        up
```

Or, without installing anything, apply them in order with `psql`:

```bash
for f in apps/backend/migrations/*.up.sql; do
  echo "--- $f"
  psql "postgres://survscribe:devpassword@localhost:5433/survscribe_dev" -v ON_ERROR_STOP=1 -f "$f"
done
```

### Rules

1. **Never point a migration command at a shared, staging or production database
   without an explicit, recorded instruction to do so.** The connection string is always
   typed by a human, never read from a default.
2. **Never wire `migrate up` into server startup, `go test`, `make dev`, a Dockerfile
   `CMD`, or CI.** A migration that runs as a side effect of something else is how
   production schemas get changed by accident.
3. **Read the down-migration before running it.** `000010`'s down drops `audit_log`,
   which is evidentiary: it holds the record of every loss-assessment figure change and
   every insurer file access (SRS §5.1 rule 3, §6.2). Down-migrating past `000010` in any
   environment holding real survey data requires an archival step first.
4. **`000012` is reference data, not user data.** Its down-migration removes only the
   seeded system roles and the permission catalogue; store-authored custom roles are left
   alone. `role_permissions → permissions` is `ON DELETE RESTRICT`, so a custom role still
   holding a catalogue permission will correctly block the delete rather than silently
   orphaning it.

---

## 5. Grants

`000010` runs `REVOKE UPDATE, DELETE, TRUNCATE ON audit_log FROM PUBLIC`, and `000005`
does the same for `auth_events`. The matching `GRANT` for the application role is left
**commented out** in both files, because the role name is an environment concern rather
than a schema concern:

```sql
-- GRANT INSERT, SELECT ON audit_log   TO survscribe_app;
-- GRANT INSERT, SELECT ON auth_events TO survscribe_app;
```

Whoever provisions a database must create that role and issue those grants. The
application must **not** connect as the database owner — owner privileges bypass the
`REVOKE`, which would defeat the append-only guarantee that `CLAUDE.md` §14 constraint 10
and §14 constraint 17 depend on. This belongs in the deployment runbook that ADR-0008
(configuration and secrets) will own.

---

## 6. Open items that will change these files

Carried from `physical-schema.md` §38. None of them is settled, and each will require a
migration amendment rather than a new migration, because nothing has been applied yet:

- **Sync columns** (`client_updated_at`, `field_updated_at`, `sync_revision`) and the
  whole of `sync_queue` are provisional pending `sprint_0002`, the sync spike. This
  affects every workflow table and is the largest churn risk in the set.
- **`policy_sections`**, **`assessment_heads`**, **`discrepancy_flags`**,
  **`document_line_items`**, **`chronology_events`**, **`preliminary_survey_reports`**,
  **`pre_submission_audits`** and **`report_dispatches`** are additions beyond the
  SRS §5.2 entity list and are awaiting owner approval.
- **`uom`** and **`document_type`** enum value lists were closed from specs that ended
  with "etc.". Adding a value later is a migration.
- The **`ADMIN` role has no `assessment:approve`** and **`REVIEWER` has no
  `report:submit`**, transcribed verbatim from `physical-schema.md` §7.7. Both read as
  deliberate separation of duties; confirm before the RBAC middleware ships.
