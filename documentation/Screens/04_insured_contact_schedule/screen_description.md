# Screen Specification: 04_insured_contact_schedule

## 1. Screen Objective & Context
- **Screen Name**: Insured Contact & Survey Scheduling
- **Stage Mapping**: Stage 3 of 15 (Initial Contact and Survey Visit)
- **Purpose**: Manages communication logs with the insured/claimant, scheduling the physical survey visit, capturing initial incident explanations, and auto-dispatching the formal **Evidence & Loss Preservation Notice**.

---

## 2. Layout & UI Architecture

### 2.1 Primary Mobile App View (iOS & Android) - Core Mobile Experience
- **Mobile Field Communications Hub**:
  - Top: Insured Quick-Action Bar with prominent one-tap Call (`tel:`) and WhatsApp (`whatsapp:`) buttons.
  - Interactive Date-Time Picker for inspection scheduling with "Add to Device Calendar" toggle.
  - One-Tap Dispatch Sheet for Evidence & Loss Preservation Notice (Direct share via WhatsApp, SMS, or Email).
  - Voice memo button for speaking call notes.
  - Collapsible chronological Call Log stream.
  - Sticky bottom CTA: "Schedule Visit & Proceed to Site".

### 2.2 Responsive Desktop Web View
- **Two-Column Workflow View**:
  - **Left Column (50% width)**: Insured Contact Card, Survey Visit Scheduling Form, and Initial Incident Statement Log.
  - **Right Column (50% width)**: Formal Evidence Preservation Notice Generator (Live template preview with customizable clauses) and Historical Communication & Call Log Timeline.

---

## 3. Detailed UI Component Hierarchy
1. **Insured Quick Contact Card**:
   - `ContactName`, `Designation`, `PhoneNumber` (Direct `tel:` and `whatsapp:` links), `EmailAddress`.
2. **Survey Visit Scheduler**:
   - `ScheduledDatePicker` & `ScheduledTimePicker`
   - `SurveyorLeadSelect` (Assigned surveyor)
   - `SiteAccessibilityNotes` (e.g., "Site power disconnected, safety shoes and helmets required").
   - `AddToCalendarToggle` (Generates `.ics` / device calendar event).
3. **Loss Preservation Notice Generator**:
   - `NoticeTemplatePreview` (Pre-drafted legal notice instructing preservation of damaged property, prohibition of unauthorized repairs, and mitigation duties).
   - `CustomInstructionInput` (Add custom preservation demands, e.g., "Retain burnt copper windings").
   - `DispatchActionGroup` (Buttons: *Send WhatsApp*, *Send Email*, *Copy Text*, *Download PDF*).
4. **Communication Log Timeline**:
   - `AddLogEntryButton`
   - `TimelineStream`: Chronological cards showing Date, Time, Contact Person, Call Outcome (*Connected / Busy / Site Confirmed*), Notes.

---

## 4. Data Fields, Types & Validations

| Field | Type | Mandatory | Validation Rules | Description |
| :--- | :--- | :--- | :--- | :--- |
| `scheduled_visit_date` | Date | Yes | Cannot be in past | Proposed site inspection date |
| `scheduled_visit_time` | Time | Yes | Valid time string | Proposed site inspection time |
| `insured_spokesperson` | String | Yes | Min 3 chars | Person met/spoken with |
| `contact_log_notes` | Text | Yes | Min 10 chars | Summary of telephonic conversation |
| `preservation_notice_sent`| Boolean | Yes | Tracked automatically | Confirmation that legal notice was dispatched |

---

## 5. AI Assistant Integration & Triggers
- **Smart Call-Note Structurer (AI-1)**: Surveyor can speak a voice memo after calling the insured (e.g., *"Spoke with Plant Manager Mr. Sharma, he confirmed factory is accessible tomorrow at 10 AM. Fire was put out yesterday at 6 PM"*). AI extracts the date, time, contact name, and summary into the scheduling form.
- **Dynamic Notice Tailoring**: AI adjusts the Evidence Preservation Notice based on peril (e.g., adds specific water drainage preservation steps for flood claims, or electrical isolation advice for machinery breakdown).

---

## 6. Offline State & Sync Indicators
- Surveyor can schedule visits and log call records offline. Messages queued for dispatch trigger when network is detected.
- Calendar sync operates natively on iOS/Android without server connectivity.

---

## 7. Action Triggers & Navigation
- **Click "Schedule Visit & Proceed to Risk Location"**: Locks appointment time, marks notice as dispatched, and advances to Stage 4 (`05_risk_location_verification`).
- **Click "Dispatch Notice"**: Triggers native share sheet (WhatsApp/Email/SMS).
