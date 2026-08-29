# Sprint 0015 — Hardening & Security Review

| | |
| :-- | :-- |
| **Roadmap ref** | S4.1 |
| **Stage** | 4 — Quality, Security & MVP Readiness |
| **Status** | Not started |
| **Depends on** | [`sprint_0013`](../sprint_0013_fsr_assembly_and_submission_gates/) (M2) |
| **Blocks** | sprint_0016 |
| **Specs** | SRS §6.2 · [ADR-0003](../../decisions/ADR-0003-session-token-and-auth-spec.md) · `CLAUDE.md` §14 |
| **Roadmap** | [`../README.md`](../README.md) |

---

## 1. Sprint Objective

Make the product trustworthy in the field: systematic error and edge-case handling across all 15 stages, a finished sync-conflict experience, and a security review that verifies every hard constraint in `CLAUDE.md` §14 rather than assuming it.

No new features. This sprint closes gaps.

---

## 2. Features & Tasks

| # | Area | Task | Priority | Expected outcome |
| :-- | :-- | :-- | :-- | :-- |
| 1 | Error handling | Systematic pass over all 15 stages: network loss mid-action, device storage full, permission denial (camera, location), malformed sync payloads, backend 5xx, token expiry mid-form. | Critical | Every failure has a specific, recoverable user-facing state. |
| 2 | Sync conflict UX | Finalise the surveyor-confirmation dialog; test multi-field concurrent edits, delete-versus-edit races, and tombstone handling. | Critical | AC 16.1.3 fully satisfied in practice, not only in the happy path. |
| 3 | Security review | Verify: SQLCipher key handling, Keychain/Keystore storage, TLS 1.3 enforcement, JWT and refresh rotation plus revocation, audit-log append-only behaviour, disclaimer embedding in every export, tenant scoping on **every** endpoint, and no secrets in the repository, logs, or crash reports. Consider running the repository's `security-review` tooling over the branch. | Critical | Signed-off security checklist. |
| 4 | Tenant isolation | Prove that a user from one tenant cannot read or mutate another tenant's claim, media, or documents through any endpoint. | Critical | Negative tests per resource. |
| 5 | RBAC columns | Verify `tenant_id`, `created_by_user_id`, `assigned_surveyor_id`, `reviewer_id`, and `access_role_scope` are populated on every entity, and that the deferral of enforcement is documented rather than silently assumed. | Critical | SRS §5.1; AC 16.2.1, AC 16.2.2 |
| 6 | Audit-log integrity | Prove the audit log is genuinely append-only: attempts to update or delete entries fail at the database level, not merely in application code. | Critical | SRS §6.2; §14.10 |
| 7 | Regression run | Full Stage 1 → 15 offline-to-online run on the device matrix: 2–3 iOS devices and 3–4 Android devices including a low-end handset. | Critical | Documented pass, with defects filed. |
| 8 | Constraint audit | Walk `CLAUDE.md` §14 item by item and record, for each, the test or verification that proves it holds. | Critical | A constraint-to-evidence table. |

---

## 3. Acceptance Criteria

- [ ] No open Critical or High defects.
- [ ] Every §14 constraint has a passing test or a documented verification; none is marked "assumed".
- [ ] The security checklist is signed off, with findings either fixed or explicitly accepted in writing.
- [ ] Cross-tenant access attempts fail on every endpoint, proven by negative tests.
- [ ] Audit-log immutability is proven at the storage layer.
- [ ] The sync-conflict dialog handles multi-field, delete-versus-edit, and repeated-conflict cases without data loss.
- [ ] The device-matrix regression run passes end-to-end, including on a low-end Android device.
- [ ] Every user-facing error state is specific and recoverable — no silent failures, no generic "something went wrong" on a data-loss path.

---

## 4. Dependencies

- sprint_0013 (M2): the complete workflow this sprint hardens.
- sprint_0014 if AI-4 lands inside the MVP window, since it adds an external data path to review.

---

## 5. Risks & Open Questions

| Item | Detail |
| :-- | :-- |
| Late discovery | Security or sync defects found here can be expensive. Anything already flagged in sprints 0004, 0005, or 0013 should have been fixed there, not deferred to this sprint. |
| Device matrix | Low-end Android is where the photo pipeline (**R7**) and SQLCipher performance are most likely to fail. Do not test only on flagship hardware. |
| Honest reporting | Per `CLAUDE.md`, this sprint's report must clearly distinguish Implemented / Reviewed / Tested / Verified, and must not mask a broken state. Failing tests are reported with their actual output. |
| Scope discipline | Hardening sprints attract feature requests. New functionality belongs in the post-MVP list, not here. |

---

## 6. Definition of Done

Global DoD (see [`../README.md`](../README.md) §6) plus:

- The constraint-to-evidence table for `CLAUDE.md` §14 is complete and reviewed.
- Every security finding is either fixed or has a written, owner-accepted risk acceptance.
- The regression run is **Tested** on real devices, with the matrix and results recorded.
