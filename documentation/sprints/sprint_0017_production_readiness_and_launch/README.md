# Sprint 0017 — Production Readiness & Launch

| | |
| :-- | :-- |
| **Roadmap ref** | S5.1 |
| **Stage** | 5 — MVP Release |
| **Status** | Not started |
| **Depends on** | [`sprint_0016`](../sprint_0016_performance_accessibility_and_uat/) |
| **Blocks** | — |
| **Specs** | `CLAUDE.md` §14 · [`../README.md#9-mvp-release-criteria`](../README.md) |
| **Roadmap** | [`../README.md`](../README.md) |

---

## 1. Sprint Objective

Ship the MVP: production infrastructure, observability, store distribution, and a release gate that verifies every constraint before a real surveyor's claim data enters the system.

---

## 2. Features & Tasks

| # | Area | Task | Priority | Expected outcome |
| :-- | :-- | :-- | :-- | :-- |
| 1 | Database | Production PostgreSQL with automated backups and point-in-time recovery; a documented migration runbook stating that migrations run **only** on explicit approval, never automatically. | Critical | Restorable production database. |
| 2 | Media storage | Provision the production object store for photos and documents, with a retention policy. Closes **Q11**. | Critical | Documented storage and retention approach. |
| 3 | Backend deployment | Containerised Go service deployment, TLS 1.3 certificates, a secrets manager holding the RS256 key and every vendor credential. | Critical | Reproducible deployment. |
| 4 | Observability | Structured logs, metrics, and crash/error reporting for both backend and mobile; alerts on sync failures, `.docx` generation failures, and authentication anomalies; audit-log monitoring. | Critical | Failures are detected before users report them. |
| 5 | Store builds | iOS TestFlight and Google Play internal testing tracks; store metadata; privacy disclosures. | Critical | Distributable builds. |
| 6 | Positioning review | Review all store listings, marketing copy, and in-app text against `CLAUDE.md` §14.1: no claim or implication of being an insurer, intermediary, IRDAI-approved entity, or autonomous claims decision-maker. | Critical | Compliance-reviewed copy. |
| 7 | Release gate | Verify the full [MVP Release Criteria](../README.md) list, including CR-W18 (the 4-point gate) and CR-W19 (the 7 audit gates), plus every §14 constraint. | Critical | Signed release checklist. |
| 8 | Rollback plan | A documented rollback procedure for backend and mobile, plus a backup-and-restore drill actually performed. | Critical | Rehearsed, not theoretical. |
| 9 | Support plan | On-call rota, incident runbook, bug-triage SLA, and a feedback channel for the pilot surveyors. | High | Operational readiness. |
| 10 | Documentation | Update `CLAUDE.md` §2 (development status), §18 (decision log), and §19 (reconciliation) to reflect that implementation has begun and what shipped. | High | Project context stays accurate. |

---

## 3. Acceptance Criteria

- [ ] Every item in the roadmap's **MVP Release Criteria** (§9) is satisfied and evidenced.
- [ ] Production backups are configured and a **restore has actually been performed**, not merely configured.
- [ ] Monitoring and alerting are live and have been proven by triggering a test alert.
- [ ] TestFlight and Play internal builds are distributed to the pilot surveyors.
- [ ] The positioning review is complete; no listing or screen implies regulatory approval or autonomous decision-making.
- [ ] The rollback procedure has been rehearsed.
- [ ] The support rota and incident runbook are in place.
- [ ] `CLAUDE.md` is updated to reflect the true post-launch state of the repository.

---

## 4. Dependencies

- sprint_0016: benchmarks met and UAT signed off.
- sprint_0015: security review signed off.
- sprint_0001: the secrets-management approach this sprint operationalises.

---

## 5. Risks & Open Questions

| Item | Detail |
| :-- | :-- |
| **Q11** | The production media storage backend and retention policy are undocumented and must be decided here at the latest. |
| Real data | From launch, real claim data with confidentiality obligations enters the system. Backups, retention, and access controls are not deferrable. |
| Store review | App Store and Play review can reject on regulatory-claim wording. The positioning review (task 6) exists to prevent that, and should happen before submission, not after a rejection. |
| Vendor readiness | Any vendor still in sandbox at this point (notably SMS DLT) must be either production-ready or the dependent feature must be visibly disabled. |
| First-run migrations | Migrations must be run deliberately against production, following the runbook and with explicit approval — never as an automatic deployment side effect. |

---

## 6. Definition of Done

Global DoD (see [`../README.md`](../README.md) §6) plus:

- The release checklist is signed by the project owner.
- The backup restore and the rollback procedure are **Verified** by execution, not by documentation alone.
- The launch report states plainly what shipped, what was deferred, and what remains unverified.
