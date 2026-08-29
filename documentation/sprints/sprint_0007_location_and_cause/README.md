# Sprint 0007 — Location & Cause (Stages 4–5)

| | |
| :-- | :-- |
| **Roadmap ref** | S2.2 |
| **Stage** | 2 — Primary MVP Workflow |
| **Status** | Not started |
| **Depends on** | [`sprint_0006`](../sprint_0006_intake_and_policy/) |
| **Blocks** | sprint_0008 |
| **Specs** | [`05_risk_location_verification.md`](../../Screens/05_risk_location_verification/05_risk_location_verification.md) · [`06_cause_investigation.md`](../../Screens/06_cause_investigation/06_cause_investigation.md) |
| **Roadmap** | [`../README.md`](../README.md) |

---

## 1. Sprint Objective

Establish **where** the loss happened and **what happened** — GPS-verified location with the accuracy gates enforced, and a defensible incident chronology backed by statutory evidence. Both must work with hardware GPS alone, no cellular data.

Stage 3 (insured contact and scheduling) is intentionally **not** in this sprint: its dispatch features are Should-Have and gated on vendor provisioning. See §5.

---

## 2. Features & Tasks

| # | Feature / module | Task | Dependency | Priority | Expected outcome |
| :-- | :-- | :-- | :-- | :-- | :-- |
| 1 | Stage 4 GPS capture | Native GPS capture of latitude, longitude, accuracy radius, altitude, and timestamp on arrival at site. Works offline on device hardware. | sprint_0006 | Critical | FR-4.1; AC 4.1.4 |
| 2 | Accuracy gates | Accuracy worse than **10 m** warns and prompts re-capture (target ≤ 10 m); accuracy worse than **50 m** is rejected and cannot be saved (hard limit). | Task 1 | Critical | D28; AC 4.1.1 |
| 3 | Location comparison | Record the physical loss location (postal address, landmarks, coordinates) and compare it against the policy risk address from Stage 2. | Task 1 | Critical | FR-4.2 |
| 4 | Discrepancy protocol | On mismatch, raise `LOCATION_DISCREPANCY_DETECTED` and require mandatory documentation: nature of occupancy, business activities conducted, ownership of premises, and the reason for the discrepancy. Saving is blocked while `discrepancy_remarks` is empty. | Task 3 | Critical | FR-4.3; AC 4.1.2, AC 4.1.3; §11.3 |
| 5 | Geocoding adapter | `GeocodingService` interface plus the Google Maps adapter (ADR-0002) for reverse geocoding and a static map preview. **Behind the adapter, degrading gracefully when offline or when the key is not yet provisioned.** | ADR-0002 | High (Should) | AC 4.1.1 geocoded address |
| 6 | Stage 5 chronology | Incident Chronology Builder: timestamped events (occurrence, discovery, notification, fire-service arrival, extinguishment, police intimation), events immediately prior, the sequence during the incident, and post-incident containment. | sprint_0006 | Critical | FR-5.1; AC 5.1.1 |
| 7 | Statutory evidence vault | FIR / police diary (number, date, station, gist); Fire Brigade report (station, call time, arrival time, containment time, stated cause); IMD weather reports; factory shift logs; CCTV notes; witness statements — with attachments. | Task 6 | Critical | FR-5.2; AC 5.1.2 |
| 8 | Chronology validation | `discovery_datetime ≥ incident_datetime`; `fire_brigade_call_time` mandatory for Fire claims. | Task 6 | Critical | §11.4 |

---

## 3. Acceptance Criteria

- [ ] **AC 4.1.1** — "Verify Location" captures latitude, longitude, altitude, accuracy radius, and timestamp; the 10 m warning and the 50 m hard block are both demonstrated with mocked accuracy readings.
- [ ] **AC 4.1.2** — an address differing from the policy schedule triggers the discrepancy prompt.
- [ ] **AC 4.1.3** — the discrepancy justification fields are mandatory and block saving when empty.
- [ ] **AC 4.1.4** — the whole Stage 4 flow completes in airplane mode using device GPS only (the geocoded address may be absent in that mode).
- [ ] **AC 5.1.1** — timestamped chronology events can be added, reordered, and edited.
- [ ] **AC 5.1.2** — statutory evidence records and their attachments persist and sync.
- [ ] §11.4 validations enforced, including the Fire-claim fire-brigade call-time requirement.
- [ ] Both screens advance the state machine on "Save & Proceed".

---

## 4. Dependencies

- sprint_0006: Stage 2 policy risk address (the comparison baseline) and the claim record.
- ADR-0002 Google Maps key provisioning from sprint_0001 (for task 5 only; the sprint is not blocked without it).

---

## 5. Risks & Open Questions

| Item | Detail |
| :-- | :-- |
| Maps key and quota | If the Google Maps key is not provisioned, task 5 ships disabled behind the adapter. GPS capture itself (Critical) is unaffected. |
| GPS testing | Emulator and simulator GPS mocking is required to test the 10 m / 50 m gates deterministically. Build the mock harness rather than testing by walking outside. |
| Stage 3 deferral | Stage 3 (contact log, visit scheduling, calendar sync, Preservation Notice dispatch) is Should-Have/Medium and is scheduled post-MVP or as a fast-follow. A claim can reach the FSR without it. Confirm stakeholders accept this — it is a visible workflow gap for real-world use. |
| AI chronology check | FR-5.3 / AC 5.1.3 (the >2-hour gap warning) is Low priority and deferred. The chronology data model must still store what the check would later need. |

---

## 6. Definition of Done

Global DoD (see [`../README.md`](../README.md) §6) plus:

- The accuracy gates are **Tested** with mocked readings at, for example, 8 m, 25 m, and 75 m, and the results are quoted in the completion report.
- The geocoding adapter has a working no-op/offline path; no screen crashes or blocks when the vendor is unavailable.
- Discrepancy flags and their mandatory remarks write audit-log entries.
