# Sprint 0008 — Damage Studio & Photos (Stage 6)

| | |
| :-- | :-- |
| **Roadmap ref** | S2.3 |
| **Stage** | 2 — Primary MVP Workflow |
| **Status** | Not started |
| **Depends on** | [`sprint_0007`](../sprint_0007_location_and_cause/) |
| **Blocks** | sprint_0009 (M1) |
| **Specs** | [`07_damage_inspection_studio.md`](../../Screens/07_damage_inspection_studio/07_damage_inspection_studio.md) · SRS FR-6.1, FR-6.2, §6.1 |
| **Roadmap** | [`../README.md`](../README.md) |

---

## 1. Sprint Objective

Build the evidence-capture core: an **itemized damage register** and the **Smart Photo Studio** whose indelible watermarking and mandatory categorisation are hard constraints (`CLAUDE.md` §14.9). This is the sprint that makes the product genuinely usable in the field.

---

## 2. Features & Tasks

| # | Feature / module | Task | Dependency | Priority | Expected outcome |
| :-- | :-- | :-- | :-- | :-- | :-- |
| 1 | Damage register | Item head (Building, Plant & Machinery, Electrical, FFF, Stocks); description; make; model; capacity; serial number / asset tag; quantity affected; unit of measurement (Nos, Kgs, Meters, SqFt); nature and extent of damage (Total Destruction, Severe Submersion, Smoke Contamination, Repairable Component Burnout); surveyor recommendation (Repairable vs Total Loss / Replace); pre-existing wear and tear notes. | sprint_0007 | Critical | FR-6.1; AC 6.1.1, AC 6.1.3 |
| 2 | Camera capture | Native camera integration within the app, optimised for one-handed field use. | Task 1 | Critical | FR-6.2 |
| 3 | Indelible watermark | Burn a non-editable overlay into the image pixels: date/time, GPS latitude and longitude, claim reference ID, and surveyor ID. | Task 2 | Critical | AC 6.2.1; §14.9 |
| 4 | Compression pipeline | On-device compression to JPEG **1600×1200 at 85% quality** with EXIF and metadata preserved. | Task 3 | Critical | SRS §6.1; AC 6.2.4 |
| 5 | Category tagging | Mandatory 6-category tag: Overall Site View, Affected Section/Room, Damaged Machine/Asset, Serial Number / Nameplate, Close-up Damage Detail, Point of Origin. Plus a descriptive caption per photo. | Task 2 | Critical | AC 6.2.2, AC 6.2.3 |
| 6 | Photo-per-item rule | Enforce at least one photo per damaged item before the stage can advance. | Tasks 1, 2 | Critical | CR-W8 |
| 7 | Local media store | Encrypted-at-rest local file store with thumbnails; media queued for background upload with exponential backoff, resuming across app restarts. | sprint_0005 sync | Critical | SRS §6.1; AC 6.2.4 |
| 8 | Evidence card UI | Evidence cards per the design system: 1px `#E2E8F0` border, 8px radius, watermark banner `rgba(15,23,42,0.85)` with white monospace text, and an explicit audit-linkage tag to the damage item. | `packages/ui` | High | Design System §12.4 |

---

## 3. Acceptance Criteria

- [ ] **AC 6.1.1** — all damage-item fields are recordable with their documented enums.
- [ ] **AC 6.1.3** — pre-existing wear, obsolescence, and maintenance defects are recorded separately with their own deduction notes.
- [ ] **AC 6.2.1** — the watermark is **burned into the pixels** and survives export; removing it from a saved photo is not possible through the app.
- [ ] **AC 6.2.2** — a photo cannot be saved without a category tag.
- [ ] **AC 6.2.3** — captions are editable per photo.
- [ ] **AC 6.2.4** — photos are stored at JPEG 1600×1200 @85% with EXIF preserved, and queued for sync.
- [ ] A damaged item without at least one photo blocks stage advance with a specific message.
- [ ] 50 photos captured entirely offline upload successfully after reconnection, resuming correctly if the app is backgrounded or killed mid-upload.

---

## 4. Dependencies

- sprint_0007: GPS coordinates for the watermark.
- sprint_0006: the claim reference for the watermark.
- sprint_0005: the sync queue that media uploads extend.

---

## 5. Risks & Open Questions

| Item | Detail |
| :-- | :-- |
| **R7** | On-device watermarking plus compression across 50+ photos is a real performance concern on low-end Android hardware. Benchmark early in the sprint; a native image module may be required rather than a JavaScript path. |
| Storage pressure | A large claim can hold hundreds of photos. The UX must handle a full device gracefully rather than failing a capture silently. |
| Camera permissions | Denial, revocation mid-session, and restricted-mode edge cases all need explicit handling. |
| Watermark verification | "Indelible" must be **proven**, not asserted. Verify against the exported file, not the in-app preview. |
| Voice-to-text deferred | AI-1 (AC 6.1.2) is Low priority and deferred. The damage-item model should still accommodate a transcript field for later. |

---

## 6. Definition of Done

Global DoD (see [`../README.md`](../README.md) §6) plus:

- Watermark indelibility is **Verified** against an exported file on both platforms.
- Capture and compression are benchmarked on at least one low-end Android device, with the numbers recorded.
- The 50-photo offline capture and reconnect upload is **Tested**, including a mid-upload app kill.
