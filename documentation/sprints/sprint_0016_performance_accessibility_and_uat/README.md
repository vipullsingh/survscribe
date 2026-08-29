# Sprint 0016 — Performance, Accessibility & UAT Preparation

| | |
| :-- | :-- |
| **Roadmap ref** | S4.2 |
| **Stage** | 4 — Quality, Security & MVP Readiness |
| **Status** | Not started |
| **Depends on** | [`sprint_0015`](../sprint_0015_hardening_and_security_review/) |
| **Blocks** | sprint_0017 (release) |
| **Specs** | SRS §6.3 · [`Visual Theme & Design System.md`](../../Visual%20Theme%20&%20Design%20System.md) §7, §8 |
| **Roadmap** | [`../README.md`](../README.md) |

---

## 1. Sprint Objective

Confirm the product meets its stated benchmarks, is accessible to WCAG 2.1 AA, matches the design system, and passes user acceptance testing **with a licensed surveyor using authentic insurance data**.

---

## 2. Features & Tasks

| # | Area | Task | Priority | Expected outcome |
| :-- | :-- | :-- | :-- | :-- |
| 1 | Report performance | Confirm the server Go `.docx` engine generates the full 9-section FSR with 50 embedded photo plates in **under 5 seconds** on target production infrastructure. | Critical | CR-NF5; SRS §6.3 |
| 2 | Media throughput | Measure the photo pipeline (capture → watermark → compress → store → upload) under field-realistic conditions, including a poor connection. | Critical | SRS §6.1 |
| 3 | Large-claim scale | Exercise a large claim: 200+ damage items and 300+ photos through sync, quantification, and FSR generation. | Critical | No timeouts, no memory failures, no unbounded sync queue. |
| 4 | App performance | Cold start, dashboard render with many claims, and the Stage 11 matrix recalculation latency. | High | Responsive on low-end hardware. |
| 5 | Accessibility | WCAG 2.1 AA pass: ≥ 4.5:1 contrast for normal text, **7:1 for financial figures**, touch targets ≥ 44–48px, screen-reader labels on all forms and on the loss matrix. | High | CR-NF7; Design System §7 |
| 6 | Design QA | Run the anti-pattern checklist (Design System §2 / §8) across every screen: no glassmorphism, no neon accents, no oversized radii, no floating chatbots, no sparkles, no gamified steppers. | High | §14.15 |
| 7 | Spec reconciliation | Reconcile the bottom-navigation labels between the design system and the dashboard spec; confirm every screen uses the canonical set. | Medium | `CLAUDE.md` §15 item 6 |
| 8 | Content authenticity | Verify no placeholder or lorem-ipsum content remains; every screen uses authentic insurance terminology. | High | Design System §7.3 |
| 9 | UAT scripts | Write acceptance scripts covering the five core questions of loss assessment, using authentic claim data. | Critical | Executable test scripts. |
| 10 | UAT execution | Recruit a licensed surveyor to run the scripts end-to-end and record findings and sign-off. | Critical | Signed UAT record. |

---

## 3. Acceptance Criteria

- [ ] The `< 5 s` / 50-plate benchmark is met on production-representative infrastructure, with the measurement recorded.
- [ ] The large-claim scenario completes without timeout, crash, or unbounded queue growth.
- [ ] Accessibility report is clean, or contains only Low-severity items with an owner-accepted plan.
- [ ] Financial figures meet the 7:1 contrast requirement.
- [ ] Every screen passes the design-system anti-pattern checklist.
- [ ] No placeholder content remains anywhere in the product.
- [ ] UAT is executed by a licensed surveyor and signed off; all Critical findings are resolved.
- [ ] The five core questions of loss assessment can each be answered by the product, demonstrably, from a completed claim.

---

## 4. Dependencies

- sprint_0015: a hardened, defect-free build; UAT on an unstable build wastes the surveyor's time.
- sprint_0013: the server `.docx` engine being benchmarked.

---

## 5. Risks & Open Questions

| Item | Detail |
| :-- | :-- |
| Benchmark failure | If the `< 5 s` benchmark fails here, remediation is late and possibly architectural. It should have been profiled in sprint_0013 — treat a failure here as a schedule risk to escalate, not to absorb. |
| Surveyor availability | UAT depends on a licensed surveyor's time. Schedule this in sprint_0001, not in this sprint. |
| Authentic data | Real claim data carries confidentiality obligations. Agree the handling and retention terms before UAT begins. |
| Late design findings | Anti-pattern violations found now are cheap to fix visually but expensive if they are structural. The per-sprint design checks in the global DoD exist to prevent a pile-up here. |

---

## 6. Definition of Done

Global DoD (see [`../README.md`](../README.md) §6) plus:

- Every benchmark is **Tested** with recorded numbers, not estimated.
- The UAT record names the surveyor, the scripts run, the findings, and the sign-off.
- All Critical UAT findings are resolved before sprint_0017 begins; the rest are triaged into the post-MVP list.
