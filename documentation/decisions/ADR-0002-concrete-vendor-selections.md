# ADR-0002 — Concrete External Service Vendor Selections

- **Status:** Accepted
- **Date:** 2026-08-30
- **Deciders:** Project owner (vipul@tezminds.com)
- **Context:** ADR-0001 (D25) established that all third-party integrations sit behind provider-agnostic interfaces with config-driven adapters. To proceed with implementation of Stage 0 (Auth), Stage 3 (Contact & Dispatch), Stage 4 (Geocoding), and AI features, concrete vendor selections must be standardized.

---

## Decisions

### 1. SMS OTP Provider: Twilio SMS (Primary) / AWS SNS (Fallback)
- **Primary:** Twilio Messaging API for global high-deliverability SMS OTP delivery during user registration and password resets.
- **Fallback:** AWS SNS SMS as a secondary route for automated failover.
- **Interface:** `SMSProvider` adapter interface in `NotificationService`.

### 2. Transactional Email Provider: SendGrid (Twilio)
- **Primary:** SendGrid v3 Mail Send API for transactional emails (OTP delivery, requisition notices, report distribution).
- **Interface:** `EmailProvider` adapter interface in `NotificationService`.

### 3. Maps & Geocoding Provider: Google Maps Platform
- **Primary:** Google Maps Geocoding & Places API for Stage 4 risk location geocoding, reverse geocoding, and static map preview generation.
- **Interface:** `GeocodingService` adapter interface.

### 4. WhatsApp Dispatch Provider: Twilio API for WhatsApp
- **Primary:** Twilio for WhatsApp Business API for automated dispatch of Loss Preservation Notices (Stage 3) and Requisition Notices (Stage 8).
- **Interface:** `WhatsAppProvider` adapter interface in `NotificationService`.

### 5. Cloud LLM Provider: Anthropic Claude 3.5 Sonnet (Primary) / OpenAI GPT-4o (Fallback)
- **Primary:** Anthropic Claude 3.5 Sonnet API for automated document contradiction scanning, loss assessment reasoning, and pre-submission audit validation (AI Gates 1-7).
- **Interface:** `AssistantService` adapter interface.

### 6. Cloud OCR & Document Intelligence: AWS Textract (Primary) / Google Cloud Vision (Fallback)
- **Primary:** AWS Textract for policy document key-value extraction, claim form parsing, and tabular loss estimate digitizing.
- **Interface:** `DocumentIntelligenceService` adapter interface.

---

## Consequences

- All service calls MUST interact through interface abstractions (`apps/backend/internal/platform/*` and `apps/mobile/src/infrastructure/services/*`), allowing zero-code-change vendor switching via environment variables.
