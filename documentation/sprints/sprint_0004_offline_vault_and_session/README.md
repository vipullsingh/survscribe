# Sprint 0004 — Offline Vault & Session

| | |
| :-- | :-- |
| **Roadmap ref** | S1.2 |
| **Stage** | 1 — Core Data & Application Foundation |
| **Status** | Not started |
| **Depends on** | [`sprint_0003`](../sprint_0003_auth_online/) |
| **Blocks** | sprint_0005 and every field-capture sprint |
| **Specs** | SRS FR-0.3 · [ADR-0003](../../decisions/ADR-0003-session-token-and-auth-spec.md) |
| **Roadmap** | [`../README.md`](../README.md) |

---

## 1. Sprint Objective

Make the application usable with **zero network**: an encrypted local database, hardware-backed token storage, offline re-entry, the 15-minute idle lock, and the append-only client audit log.

Offline-first is a hard constraint on all 15 stages (`CLAUDE.md` §14.7). Everything built after this sprint assumes this foundation.

---

## 2. Features & Tasks

| # | Feature / module | Task | Dependency | Priority | Expected outcome |
| :-- | :-- | :-- | :-- | :-- | :-- |
| 1 | Encrypted local DB | WatermelonDB schema mirroring the relevant subset of the physical schema; SQLCipher AES-256 initialisation at startup using a key held in Keychain / Keystore. | sprint_0001 schema | Critical | The database file is unreadable without the key (verified, not assumed). |
| 2 | Secure token storage | React Native Encrypted Storage backed by iOS Keychain / Android Keystore for the access and refresh tokens. | sprint_0003 | Critical | ADR-0003 §2 satisfied. |
| 3 | Offline authentication | On a no-network launch, unlock using the device passcode and the cached encrypted session token; enforce the 30-day maximum offline duration, after which online re-authentication is required. | Tasks 1, 2 | Critical | AC 0.1.4 |
| 4 | Idle lock | 15 minutes of background inactivity triggers a local lock screen requiring the device passcode. **Passcode only — biometrics are deferred (D32), pending the Q3 reconciliation of ADR-0003 §3.1.** | Task 3 | Critical | CR-A12 |
| 5 | Client audit log | Append-only local `audit_log` table and writer; entries sync upward and are never mutated or deleted locally. | Task 1 | Critical | `CLAUDE.md` §14.10; SRS §5.2 entity 14 |
| 6 | Network state | A reliable online/offline detector shared across the app, driving the offline banner and sync triggers later. | — | Critical | Single source of truth for connectivity. |
| 7 | Clarification | Answer **Q7** — recovery when the Keychain/Keystore entry is wiped. Force online re-authentication and re-sync? Is there a local-data-loss risk the user must be warned about? | — | High | Written answer; behaviour implemented and surfaced in the UI. |

---

## 3. Acceptance Criteria

- [ ] After one successful online login, the application is fully usable with the device in airplane mode — including relaunching the app.
- [ ] The local database file is demonstrably encrypted (opening it without the key fails); evidence is recorded in the sprint report.
- [ ] Tokens are stored in Keychain / Keystore, never in plain storage or `AsyncStorage`.
- [ ] The idle lock fires after 15 minutes of background inactivity and requires the device passcode.
- [ ] The 30-day maximum offline duration is enforced; beyond it the app requires online re-authentication.
- [ ] Audit-log rows are written for authentication events and are append-only (an update or delete attempt fails).
- [ ] Q7 has a written answer and the implemented behaviour matches it.

---

## 4. Dependencies

- sprint_0003: working online authentication issuing the tokens this sprint caches.
- sprint_0001: the physical schema that the local schema mirrors.

---

## 5. Risks & Open Questions

| Item | Detail |
| :-- | :-- |
| SQLCipher + WatermelonDB on React Native | Native module setup — particularly on iOS — is a known source of integration friction. Allow buffer in this sprint rather than letting it silently consume sprint_0005. |
| **Q3** | ADR-0003 §3.1 still says the idle lock uses "device biometrics" while ADR-0001 D32 defers biometrics to post-MVP. This must be reconciled **before** task 4 is implemented; the roadmap assumes passcode-only. |
| **Q7** | Key-loss recovery is undocumented. Getting this wrong risks unrecoverable local field data. |
| Key provisioning | Where the SQLCipher key comes from on first run, and how it survives an app reinstall, must be explicit. |

---

## 6. Definition of Done

Global DoD (see [`../README.md`](../README.md) §6) plus:

- The completion report includes an explicit **airplane-mode test transcript**: install → online login → airplane mode → relaunch → use → background 15 min → lock → unlock.
- Encryption is **Verified** (proven by attempting to read the database without the key), not merely Implemented.
- No secret, key, or token appears in logs or crash reports.
