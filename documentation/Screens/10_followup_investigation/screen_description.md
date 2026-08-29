# Screen Specification: 10_followup_investigation

## 1. Screen Objective & Context
- **Screen Name**: Follow-Up Surveys & Re-Inspection Tracking
- **Stage Mapping**: Stage 9 of 15 (Follow-Up Surveys and Investigation)
- **Purpose**: Enables the surveyor to log and track subsequent physical site visits, re-inspections during equipment dismantling, verification of repaired or replaced machinery, physical stock reconciliations, joint inspections with insured/insurer engineers, and investigation of discrepancies prior to loss quantification.

---

## 2. Layout & UI Architecture

### 2.1 Desktop Web Layout
- **Multi-Visit Log & Audit Workspace**:
  - **Left Pane (35% width)**: Visit History Timeline (List of logged survey visits: *Visit #1 Initial Survey, Visit #2 Dismantling & Internal Damage Inspection, Visit #3 Post-Repair Testing*).
  - **Right Pane (65% width)**: Active Visit Details & Investigation Findings:
    - Visit Purpose & Personnel Present (Insured, OEM Engineer, Repair Contractor).
    - Physical Verification Notes (Measurements, Technical findings, Stock reconciliation counts).
    - Follow-Up Photo & Evidence Gallery with comparison to initial damage photos.

### 2.2 Mobile App Layout (iOS & Android)
- **Mobile Re-Inspection Log**:
  - "+ Add Follow-Up Visit" floating button.
  - Visit Cards with date, purpose, and findings summary.
  - In-app camera to snap follow-up photos (e.g., dismantled gearbox, repaired motor, new replacement invoice tag).
  - Quick-record voice notes for technical observations.

---

## 3. Detailed UI Component Hierarchy
1. **Visit History & Navigation**:
   - `VisitNumberBadge` (e.g., "Visit #2", "Visit #3")
   - `AddVisitButton`
   - `VisitListSummary`: Displays Date, Location, Purpose, Status (*Completed / In Progress*).
2. **Follow-Up Survey Form**:
   - `VisitDateInput` & `VisitTimeInput`
   - `VisitPurposeSelect` (*Dismantling & Internal Damage Verification, Repair Progress Inspection, Stock Count & Reconciliation, Joint Forensic Meeting, Salvage Inspection & Segregation*)
   - `PersonsPresentInput` (Names and designations of all attendees)
   - `TechnicalObservationsTextarea` (Detailed findings regarding repair feasibility, parts damaged internally, scrap weight, etc.)
   - `StockReconciliationGrid` (Claimed Stock Qty vs. Physical Count / Tally reconciliation)
3. **Follow-Up Photo Studio**:
   - `FollowUpPhotoGrid` (Watermarked photos tagged with specific visit number)
   - `BeforeAfterComparisonViewer` (Side-by-side comparison of initial damage photo vs. follow-up repaired/dismantled photo).

---

## 4. Data Fields, Types & Validations

| Field | Type | Mandatory | Validation Rules | Description |
| :--- | :--- | :--- | :--- | :--- |
| `visit_number` | Integer | Yes | Auto-incrementing $\ge 2$ | Sequential visit index |
| `visit_date` | Date | Yes | Must be $\ge$ `initial_survey_date` | Date of subsequent visit |
| `visit_purpose` | Enum / String | Yes | Min 5 chars | Reason for subsequent visit |
| `persons_attended` | String | Yes | Min 3 chars | Names of parties attending |
| `detailed_findings` | Text | Yes | Min 30 chars | Factual technical observations |
| `followup_photos` | Array<Photo> | No | GPS & timestamp watermarked | Visual evidence from follow-up visit |

---

## 5. AI Assistant Integration & Triggers
- **Technical Voice Note Structurer (AI-1)**: Converts technical field voice recordings (e.g., *"During dismantling of rotor, severe scoring on journal bearings was observed, stator winding is shorted to ground"*) into structured engineering observations.
- **Investigation Progress Summarizer (AI-4)**: Synthesizes multi-visit findings into a consolidated narrative for FSR Section D (*Follow-Up Survey Findings*).

---

## 6. Offline State & Sync Indicators
- All subsequent visit entries, GPS stamps, and follow-up photos are recorded offline and stored in SQLite.
- Background sync updates the cloud server when network connection is re-established.

---

## 7. Action Triggers & Navigation
- **Click "Save & Proceed to Document Audit"**: Validates visit findings, advancing to Stage 10 (`11_document_verification_audit`).
- **Click "+ Add Another Visit"**: Appends a new visit card to the timeline.
