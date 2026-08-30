# ADR-0009 — MVP Release Scope: AI-4 Timing and Dual-`.docx` Engine Scope

- **Status:** Accepted
- **Date:** 2026-08-30
- **Deciders:** Project owner (vipul@tezminds.com)
- **Sprint:** `sprint_0001` task 11
- **Closes:** `sprint_0001` §16 Q9; the dual-`.docx` MVP-scope question named alongside it in `sprint_0001` task 11 and DoD
- **Depends on:** ADR-0001 (D22 dual-engine `.docx`), ADR-0002 (D6 LLM vendor), `sprint_0014` (AI narrative drafter)

---

## Context

Two scope questions were left open by `sprint_0001` §5/§6 and blocked that sprint's Definition of Done:

1. **Q9** — is AI-4, the Report Draft Generator, required inside the MVP release window, or can it ship as a post-launch fast-follow? This determines whether `sprint_0014` is a release gate.
2. **Dual-`.docx` MVP scope** — ADR-0001 D22 specifies two `.docx` engines (an offline client-side TypeScript engine for drafts, and an authoritative server-side Go engine for final reports). Does MVP build both, or defer the client engine?

Both were put to the project owner on 2026-08-30 and answered.

---

## Decisions

### 1. AI-4 is a post-launch fast-follow — **Q9 closed**

**AI-4 does not gate MVP release.** `sprint_0014` remains scheduled where it already sits, after M2, and ships after the MVP launch rather than as a precondition of it.

Reasoning:

- `sprint_0014`'s own README already states the intended purpose of that scheduling: the MVP's end-to-end viability must never depend on an AI vendor, a privacy clearance, or model behaviour. Making AI-4 a release gate would contradict the reason the sprint was placed there in the first place.
- The FSR workflow is complete without it. Stage 14 compiles all nine sections regardless of who drafts sections C, D, H and I; FR-14.2 makes the AI drafter an accelerator for those four sections, not a precondition for assembling or submitting a report. A surveyor can write them directly, exactly as every other FSR section is already written.
- The Anthropic LLM vendor (ADR-0002 decision 5) is, per the vendor tracker, **not yet provisioned** (row 7: `NOT STARTED`). Making AI-4 a release gate puts an unprovisioned external vendor account, and whatever privacy/data-processing review a claim-data LLM integration requires, on the MVP critical path. Neither is an engineering risk the team controls the timeline of.
- `CLAUDE.md` §14 constraint 2 already requires every AI suggestion to be human-reviewed and editable. A report drafted entirely by a surveyor without AI assistance satisfies that constraint trivially — it is not a degraded version of the requirement, it is the requirement's floor case.

**What this changes:**
- `sprint_0014` is removed from the MVP release-gate set. It still must ship — the SRS's characterization of AI-4 as the platform's primary/core feature is unchanged — but "primary feature" and "release-blocking for v1" are no longer the same claim.
- Stage 14 (`sprint_0013`) must work completely with sections C, D, H and I entered by the surveyor with no AI assist available. This was already true architecturally (AI output is always optional and editable) but is now a **tested requirement**, not an incidental consequence.
- The `[SURVEYOR TO VERIFY]` placeholder mechanism (`CLAUDE.md` §14 constraint 3) has nothing to do with this: it governs missing *data*, not a missing AI *feature*. A report with no AI assistance has no AI-drafted blocks at all, and therefore no placeholders to resolve.

### 2. MVP ships the server-side `.docx` engine only — client engine deferred post-MVP

**Only the authoritative server-side Go `.docx` engine is built for MVP.** The offline client-side TypeScript engine specified in ADR-0001 D22 is deferred to post-MVP.

Reasoning:

- The server engine is required unconditionally: it is what produces every submitted PSR and FSR, and CR-NF5's `< 5 s` / 50-photo-plate benchmark is defined against it specifically. There is no scope reduction available on this half of D22.
- The client engine's entire purpose is letting a surveyor preview or export a **draft** while disconnected. It does not change what data can be captured offline — every one of the 15 stages already works fully offline per `CLAUDE.md` §14 constraint 7, independent of report export. A surveyor without the client engine can still complete an inspection, log damage items, capture watermarked photos, and enter the loss assessment while offline; they view that data on-screen and export the formatted document once reconnected.
- Building two independent `.docx` generators and holding them in format parity from day one (`CLAUDE.md` §14 constraint 16) is substantial, ongoing engineering cost. Building one first, against a shared template contract explicitly designed to support a second implementation later, is safer: the template contract is proven against real reports before a second engine has to match it.
- This is a scope and sequencing decision, not a retraction of D22. The dual-engine architecture stands; only the delivery order changes.

**What this changes:**
- `sprint_0013` (FSR assembly) implements the server-side engine only. Its Definition of Done should read "server engine" rather than "both engines" wherever it currently implies both.
- The **shared template contract** (`final_survey_reports.section_*_json` envelope, `physical-schema.md` §33) is still built exactly as specified — it is what makes adding the client engine later a bounded, well-defined task rather than a rewrite.
- Offline behaviour for Stage 8 (PSR) and Stage 14 (FSR) in MVP: the surveyor can complete every field, and the 4-point Human Approval Gate can be recorded offline (it needs no network call), but the `.docx` file itself generates only once the device reaches the server. This is stated explicitly here so it is not discovered as a surprise gap during `sprint_0013`.
- A post-MVP sprint is scheduled to add the client engine once real reports have exercised the template contract.

---

## Consequences

- `sprint_0001` task 11 and its Definition of Done item ("Q9 and the dual-`.docx` MVP scope have written answers") are satisfied by this ADR.
- `sprint_0014`'s README and the master roadmap (`documentation/sprints/README.md`) should be updated to reflect that it is no longer a release gate — a documentation follow-up, tracked here rather than performed as a side effect of this ADR.
- `sprint_0013`'s scope statement should be narrowed to the server engine explicitly, with the client engine's absence stated rather than implied.
- `CLAUDE.md` §16 should mark Q9 closed and record this decision in §18.

---

## Alternatives considered

**AI-4 required in MVP.** Rejected for the vendor-timeline and architectural reasons in decision 1. The counter-argument — that AI-4 is described as the platform's core feature — is real, but "core feature" describes the product's eventual value proposition, not a claim about what must exist at first launch; `sprint_0014`'s own placement in the roadmap already reflects that distinction.

**Both `.docx` engines in MVP.** Rejected for the reasons in decision 2. The counter-argument — that offline-first is a hard requirement and dropping the client engine narrows it — is acknowledged directly: offline-first is preserved for every stage of *data capture*, and only the *rendering of the final document* requires connectivity in MVP, which is a materially smaller gap than losing offline capability during a field survey.

**Deferring the decision further, into `sprint_0013`/`sprint_0014` themselves.** Rejected: both sprints depend on knowing their own scope before they can be planned in detail, and `sprint_0001`'s Definition of Done already named this as a blocking clarification for the entry sprint.
