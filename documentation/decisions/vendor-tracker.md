# Vendor & Credential Tracker

> **Purpose:** one place that answers "is this account open, who owns the key, and when was it last rotated" for every external service SurvScribe depends on.
> **Owner:** project owner (vipul@tezminds.com).
> **Created:** 2026-08-30 (`sprint_0001` task 10). **Last updated:** 2026-08-30.
> **Governing decisions:** [ADR-0002](ADR-0002-concrete-vendor-selections.md) (vendor choices), [ADR-0006](ADR-0006-geoip-provider.md) (geo-IP), [ADR-0008](ADR-0008-configuration-and-secrets.md) (custody and rotation).

**This document contains no credentials and never will.** It records *status and ownership only*. Keys live in the secret manager per ADR-0008 §4; a key pasted here would be a key in git history forever.

---

## 1. Status

**Nothing is provisioned.** Every row below is `NOT STARTED`. Vendors are *selected* (ADR-0002); no account has been opened, and no key exists. Opening these accounts is a project-owner action — it requires a company identity, a payment method and, for Indian SMS, regulatory filings. It is not something a developer or an agent can or should do.

| # | Service | Vendor | Needed by | Status | Account owner | Key location | Last rotated |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| 1 | SMS OTP (primary) | Twilio Messaging | `sprint_0003` (deferred, see R4) | **NOT STARTED** | — | — | — |
| 2 | SMS OTP (fallback) | AWS SNS | post-MVP | **NOT STARTED** | — | — | — |
| 3 | **India SMS DLT registration** | TRAI / Twilio | blocks #1 | **NOT STARTED — START NOW** | — | n/a | n/a |
| 4 | Transactional email | SendGrid | `sprint_0003` (password reset), `sprint_0009` | **NOT STARTED** | — | — | — |
| 5 | WhatsApp dispatch | Twilio WhatsApp Business | `sprint_0007` (Stage 3 notices) | **NOT STARTED** | — | — | — |
| 6 | Maps & geocoding | Google Maps Platform | `sprint_0007` (Stage 4) | **NOT STARTED** | — | — | — |
| 7 | Cloud LLM (primary) | Anthropic Claude | `sprint_0014` (AI-4) | **NOT STARTED** | — | — | — |
| 8 | Cloud LLM (fallback) | OpenAI GPT-4o | post-MVP | **NOT STARTED** | — | — | — |
| 9 | Cloud OCR (primary) | AWS Textract (`ap-south-1`) | `sprint_0010` (Stage 10) | **NOT STARTED** | — | — | — |
| 10 | Cloud OCR (fallback) | Google Cloud Vision | post-MVP | **NOT STARTED** | — | — | — |
| 11 | Geo-IP database | MaxMind GeoLite2 | `sprint_0003` (auth telemetry) | **NOT STARTED** | — | — | — |
| 12 | Secret manager | AWS Secrets Manager (provisional) | `sprint_0003` | **NOT STARTED** | — | n/a | n/a |
| 13 | Media object storage | undecided | `sprint_0008` | **NOT DECIDED** | — | — | — |
| 14 | Application hosting | undecided | `sprint_0017` | **NOT DECIDED** | — | — | — |

---

## 2. The one item that is genuinely urgent

**Row 3 — India SMS DLT registration.** `sprint_0001` records this as risk **R4**: registration with the Indian telecom DLT platform (entity registration, header/sender-ID approval, and template approval for each OTP message) routinely takes **weeks**, and it is a hard prerequisite for delivering a single SMS to an Indian handset. It cannot be compressed by starting it later.

This is why OTP login is already deferred out of `sprint_0003` and why phone-OTP sign-in is a Should-Have rather than a release gate. That mitigation only holds if registration is *in progress*. Starting it now costs a form; starting it in `sprint_0003` costs the release date.

Three separate approvals are needed, in order: entity registration → sender ID (header) → each message template. A template change after approval requires re-approval, so the OTP message wording should be settled before filing.

---

## 3. What blocks what

| Blocked work | Blocked by | Consequence if the key is missing |
| :-- | :-- | :-- |
| Phone OTP login (CR-A2) | #1, #3 | Feature cannot ship. Password login is unaffected. |
| Email OTP, password reset (CR-A3) | #4 | `password_reset_tokens` exists in the schema but the flow cannot dispatch. |
| Stage 3 preservation notice (FR-3.3) | #4, #5 | The notice can be generated and stored; it cannot be dispatched. |
| Stage 4 address verification (FR-4.2) | #6 | GPS capture still works — it is device hardware and offline-capable. Only reverse geocoding and distance variance are lost. |
| Stage 10 OCR (FR-10.1) | #9 | Documents upload and store; line items must be keyed by hand. |
| Stage 14 AI narrative (FR-14.2) | #7 | The FSR is still assembled; sections C, D, H, I must be written by the surveyor. |
| Auth geo-enrichment (D44) | #11 | Nothing blocks. ADR-0006 makes enrichment best-effort; every geo column is nullable and a failure never blocks authentication. |

**Every one of these degrades rather than breaks.** That is a direct consequence of the offline-first requirement: a feature that cannot work without a network call was never allowed on a critical field path (`CLAUDE.md` §14 constraint 7). A missing vendor key delays a capability; it does not stop a surveyor completing a survey.

---

## 4. Rules for whoever provisions these

1. **Separate credentials per environment.** Development, staging and production never share a key. A development key with production send rights is a production key.
2. **Sandbox first.** Twilio, SendGrid and Textract all offer test modes. No integration is written against a live-billing key.
3. **Record the owner, not the secret.** Fill in the "Account owner" and "Key location" columns above; the key itself goes to the secret manager (ADR-0008 §4).
4. **Set a billing alert on every metered account** before the first real call. LLM and OCR spend scales with claim volume, and an unbounded key on a public endpoint is a financial incident.
5. **Restrict by scope.** Google Maps keys are restricted by API and by referrer/IP. AWS keys get an IAM policy limited to Textract in `ap-south-1`. A key that can do more than the feature needs is a key that will eventually do more than the feature needs.
6. **No provider key ever reaches the mobile app.** The app calls providers only through the SurvScribe backend (ADR-0008 §3). A key in a React Native bundle is a published key.
7. **Log the rotation date here** every time a key is rotated, per the ADR-0008 §6 cadence.

---

## 5. Open decisions

- **Media object storage (row 13).** Stage 6 produces watermarked JPEGs at 1600×1200 and Stage 14 embeds up to 50 plates per report. Storage class, region (data residency for Indian insurance claim data), lifecycle and signed-URL policy are all undecided. Needs an ADR before `sprint_0008`.
- **Hosting (row 14).** Undecided, which is why ADR-0008 marks AWS Secrets Manager as provisional rather than chosen.
- **Data residency.** Indian insurance claim data may carry residency obligations that constrain rows 7, 9, 13 and 14. This is a legal question, not an engineering one, and it should be answered before an OCR or LLM vendor processes a real claim document.
