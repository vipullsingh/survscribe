# Sprint 0014 — AI-4 Grounded Narrative Drafter

| | |
| :-- | :-- |
| **Roadmap ref** | SAI.1 |
| **Stage** | 3.5 — AI Narrative Drafter (fast-follow) |
| **Status** | Not started |
| **MVP priority** | **Should Have** — the headline differentiator, but the FSR is completable without it |
| **Depends on** | [`sprint_0013`](../sprint_0013_fsr_assembly_and_submission_gates/) (M2) |
| **Specs** | SRS FR-14.2, §4.1 AI-4, §4.2, §4.3 · Epic 14 Story 14.1 · [ADR-0002](../../decisions/ADR-0002-concrete-vendor-selections.md) |
| **Roadmap** | [`../README.md`](../README.md) |

---

## 1. Sprint Objective

Deliver the platform's primary AI feature: drafting formal, surveyor-grade prose for FSR **Sections C, D, H, and I** from verified Stage 1–13 data — under strict zero-hallucination guardrails, with every draft requiring an affirmative human action before it enters the report.

This sprint is scheduled after M2 so that the MVP's end-to-end viability never depends on an AI vendor, a privacy clearance, or model behaviour. **Q9** determines whether it is a release gate or a post-launch fast-follow.

---

## 2. Features & Tasks

| # | Feature / module | Task | Dependency | Priority | Expected outcome |
| :-- | :-- | :-- | :-- | :-- | :-- |
| 1 | Service interface | Implement `AssistantService` (Go) / `IAssistantService` (TypeScript) per SRS §4.2, with `CloudAssistantService` for online and an explicit disabled path when offline. | sprint_0013 | High | SRS §4.2 |
| 2 | Cloud adapter | Anthropic Claude adapter behind the interface, config-driven so the vendor can be swapped without code changes. | ADR-0002 | High | ADR-0002 §5 |
| 3 | Grounded context builder | Assemble **only** structured, verified fields from Stages 1–13 into the prompt. No open-ended retrieval, no web access, no free-form claim text beyond recorded surveyor input. | Task 1 | High | AC 14.1.1; §14.3 |
| 4 | Placeholder rule | A missing input produces the literal `[SURVEYOR TO VERIFY]` placeholder — never an inferred or invented detail. | Task 3 | High | AC 14.1.1; §14.3 |
| 5 | Numeric prohibition | The narrative path is architecturally prevented from generating or altering any monetary value, date, policy term, or cause. All numbers come from the deterministic engine. | Task 3 | High | §14.2, §14.5; SRS §4.3 |
| 6 | Section drafting | Generate Section C (cause and chronology), Section D (physical findings), Section H (discrepancies), and Section I (surveyor's opinion). Sections A, B, E, F, G are never AI-drafted. | Task 3 | High | AC 14.1.2–14.1.4; §14.12 |
| 7 | Editing UX | Full in-place editing, accept/reject per draft, live word count. No draft enters the report without an affirmative human action. | Task 6 | High | AC 14.1.5; §14.3 |
| 8 | UI framing | Objective inline labels only — "Draft Narrative with Field Notes". No sparkles, no "Magic AI Write", no floating chatbot widget. | `packages/ui` | High | Design System §5; §14.15 |
| 9 | Guardrail test suite | Automated tests: a missing input yields the placeholder and never an invented fact; numeric values in the output match the deterministic engine exactly; output is diff-able against its source facts. | Tasks 4, 5 | High | §14.3 |
| 10 | Privacy clearance | Complete the data-residency and privacy review for sending Indian insurance claim data to a cloud LLM, before enabling the feature outside a sandbox. | — | High | Written clearance. |

---

## 3. Acceptance Criteria

- [ ] **AC 14.1.1** — the narrative engine accepts only structured Stage 1–13 data; a missing input produces `[SURVEYOR TO VERIFY]`.
- [ ] **AC 14.1.2** — Section C synthesises the chronology, fire-brigade timings, and event sequence into professional narration.
- [ ] **AC 14.1.3** — Section D synthesises physical findings and the damage register.
- [ ] **AC 14.1.4** — Section I links cause, physical proof, and quantification rationale.
- [ ] **AC 14.1.5** — the surveyor can edit, rewrite, accept, or reject every draft, with a live word count.
- [ ] The guardrail suite passes: no invented facts, no altered numbers.
- [ ] With AI text present but unreviewed, **Stage 15 gate 7 still blocks submission**.
- [ ] Offline behaviour is unchanged: the feature is cleanly disabled and manual narrative entry still works.
- [ ] No UI element implies autonomy, and the platform never dispatches or approves anything.
- [ ] Privacy clearance is recorded before any non-sandbox enablement.

---

## 4. Dependencies

- sprint_0013: the FSR assembly the drafts populate, and the gates that govern them.
- sprint_0012, sprint_0011, sprint_0010: the verified Stage 10–13 data the grounding depends on.

---

## 5. Risks & Open Questions

| Item | Detail |
| :-- | :-- |
| **R5** | Sending Indian insurance claim data to a cloud LLM requires a data-residency and privacy review. Keep the feature sandbox-only until it is cleared. This is a hard gate, not a formality. |
| Prompt injection | OCR'd documents and free-text surveyor fields flow into the prompt. Treat all such content as untrusted data, never as instructions. |
| Grounding drift | The temptation to "improve" output by widening the context is the exact failure mode `CLAUDE.md` §14.3 prohibits. Widening the grounding set requires a decision record, not a code change. |
| **Q9** | Whether AI-4 is required inside the MVP release window should have been answered in sprint_0001. It determines whether this sprint gates the release. |
| **Q5 linkage** | If Stage 15 gate 6 (Contradiction Scanner) was designed as AI-assisted in sprint_0013, this sprint becomes a dependency of M2 rather than a fast-follow. |

---

## 6. Definition of Done

Global DoD (see [`../README.md`](../README.md) §6) plus:

- The guardrail suite is part of CI, not a manual review.
- A deliberate missing-data scenario is **Tested** and produces the placeholder.
- The feature is fully disable-able by configuration, and the product remains complete without it.
- No monetary value in any generated narrative differs from the deterministic engine's output.
