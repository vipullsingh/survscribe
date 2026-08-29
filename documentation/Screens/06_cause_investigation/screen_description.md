# Screen Specification: 06_cause_investigation

## 1. Screen Objective & Context
- **Screen Name**: Cause and Circumstances Investigation
- **Stage Mapping**: Stage 5 of 15 (Investigation of Cause and Circumstances)
- **Purpose**: Establishes the exact sequence of events, origin, dynamics, and proximate cause of the loss. Captures chronological incident events, records statutory and third-party reports (Police FIR, Fire Brigade report, IMD weather logs, CCTV notes), and performs AI chronology consistency audits to answer *"What Happened?"* and *"Is the damage connected to the reported incident?"*.

---

## 2. Layout & UI Architecture

### 2.1 Desktop Web Layout
- **Two-Column Forensic Workspace**:
  - **Left Pane (55% width)**:
    - Interactive **Incident Chronology Timeline Builder** (Occurrence $\rightarrow$ Discovery $\rightarrow$ Response $\rightarrow$ Extinguishment/Containment).
    - Detailed Narration of Cause and Sequence of Events (Rich text editor with AI narrative assistant).
  - **Right Pane (45% width)**:
    - Statutory & Third-Party Reports Vault (Police FIR, Fire Brigade, Weather report, Factory logbook).
    - AI Chronology & Cause Consistency Auditor widget.

### 2.2 Mobile App Layout (iOS & Android)
- **Timeline-Centric Mobile Flow**:
  - Quick-add timeline buttons (+ Add Event: Discovery, Fire Brigade Arrival, etc.).
  - Voice Note recorder for surveyor to speak the chronological cause narrative on-site.
  - Attachment tabs for photographing FIR copy, Fire Brigade certificate, and witness statements.
  - Sticky "Run AI Consistency Check" button.

---

## 3. Detailed UI Component Hierarchy
1. **Incident Chronology Timeline**:
   - `AddTimelineEventButton`
   - `TimelineCardList`: Each card contains:
     - `EventTimestampPicker` (Date & Time)
     - `EventTypeSelect` (*Pre-Incident Activity, Loss Occurrence, Loss Discovery, Emergency Response, Extinguishment/Containment, Post-Loss Action*)
     - `EventDescriptionInput`
     - `WitnessPersonInput`
2. **Detailed Cause Narration Workspace**:
   - `ReportedCauseSelect` (Short Circuit, Inundation/Flood, Burst Pipe, Spontaneous Combustion, Burglary/Theft, Impact Damage, Lightning)
   - `OriginPointInput` (e.g., "Main electrical control panel on ground floor mezzanine")
   - `ChronologicalNarrativeTextarea` (Full narrative of sequence of events)
   - `StepsTakenByInsuredTextarea` (Mitigation and emergency measures undertaken)
3. **Statutory & Official Evidence Vault**:
   - `FIRDetailsGroup`: FIR/Police Dairy No., Date, Police Station Name, Attached Document.
   - `FireBrigadeGroup`: Fire Station, Call Time, Arrival Time, Extinguishment Time, Fire Officer Name, Reported Cause by Fire Dept.
   - `ThirdPartyReportsGroup`: IMD/Weather report, Factory logbook, CCTV footage notes, Forensic engineer report.
4. **AI Consistency & Causation Audit Widget**:
   - `ConsistencyScoreMeter` (Green: Consistent / Yellow: Timeline Gap / Red: Contradiction)
   - `AnomalyList` (Highlights discrepancies, e.g., "Fire Brigade call time is 4 hours after stated discovery time").

---

## 4. Data Fields, Types & Validations

| Field | Type | Mandatory | Validation Rules | Description |
| :--- | :--- | :--- | :--- | :--- |
| `incident_datetime` | DateTime | Yes | Cannot be in future | Exact date & time loss occurred |
| `discovery_datetime` | DateTime | Yes | Must be $\ge$ `incident_datetime` | Date & time loss was first noticed |
| `reported_cause` | Enum / String | Yes | Min 5 chars | Proximate cause identified |
| `point_of_origin` | String | Yes | Min 5 chars | Physical location where peril started |
| `sequence_of_events` | Text | Yes | Min 50 chars | Detailed chronological narrative |
| `mitigation_steps` | Text | Yes | Min 20 chars | Steps taken by insured to arrest loss |
| `fir_number` | String | No | Alphanumeric | Police FIR reference number |
| `fire_brigade_call_time`| DateTime | Conditional | Mandatory for Fire claims | Fire brigade dispatch time |

---

## 5. AI Assistant Integration & Triggers
- **Chronology Synthesizer (AI-4)**: Converts surveyor timeline bullet points and voice notes into a formal, chronological narrative paragraph for FSR Section C (*Cause and Circumstances of Loss*).
- **Timeline & Document Cross-Check (AI-3)**: Compares stated incident time against timestamps on Fire Brigade report, CCTV logs, and FIR. Flags timing anomalies with exact time gap calculations.
- **Zero-Hallucination Guardrail**: AI narrative generator strictly uses the provided timeline entries and refuses to add speculative causes or unstated events.

---

## 6. Offline State & Sync Indicators
- Surveyor can add timeline events, speak voice notes, and photograph police/fire reports completely offline.
- Data and images are cached locally with sync status `PENDING_SYNC`.

---

## 7. Action Triggers & Navigation
- **Click "Save & Proceed to Damage Inspection Studio"**: Validates timeline and mandatory cause fields, advancing to Stage 6 (`07_damage_inspection_studio`).
- **Click "Generate AI Cause Draft"**: Generates narrative preview in Section C format.
