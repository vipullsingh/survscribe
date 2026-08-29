# Screen Specification: 01_dashboard

## 1. Screen Objective & Context
- **Screen Name**: Survey Pipeline Dashboard & Claim Tracker
- **Stage Mapping**: Global Overview / Entry Point
- **Purpose**: Provides the surveyor with a high-level operational overview of all active, pending, and submitted claim surveys. Allows rapid filtering across the 15-stage survey lifecycle, quick access to urgent tasks (e.g., upcoming inspections, pending PSR submissions), and instant creation of new survey assignments.

---

## 2. Layout & UI Architecture

### 2.1 Primary Mobile App View (iOS & Android) - Core Mobile Experience
- **Compact Mobile Top Bar**: App branding (`SurvScribe`), Offline/Online sync badge with tap-to-sync button, Search icon, and Notification bell.
- **Daily Field Focus Carousel**: Horizontally swipeable cards showing today’s scheduled field visits with one-tap "Start Field Survey" and "Navigate via GPS" buttons.
- **Segmented Stage Filter Pills**: Touch-friendly chips: *All (15)*, *In Field*, *Audit/Quantification*, *Report Drafting*, *Ready to Submit*.
- **Card-Based Claim Feed**: Touch-optimized cards displaying Claim #, Insured Name, Risk City, Stage Badge (e.g., "Stage 6 of 15"), and sync status dot.
- **Swipe Actions**: Swiping left on a card reveals quick-action triggers: *Call Insured*, *Open Maps*, *Add Quick Photo*.
- **Floating Action Button (FAB)**: Prominent bottom-right `+` button to start a new claim survey or record an instant voice field note.
- **Bottom Navigation Bar (canonical 5 tabs)**: *Dashboard*, *Claims*, *Field Studio*, *Reports*, *Profile*. (See Visual Theme & Design System §6.1 for the authoritative label set.)

### 2.2 Responsive Desktop Web View
- **Top App Bar**: Global Search Bar (by Claim #, Policy #, Insured Name, Insurer), Sync Status Indicator, "New Survey" CTA Button, User Profile Chip.
- **Metric Summary Cards (4 Cards)**: Active Surveys, Today's Field Visits, Pending Audits, Reports Ready to Submit.
- **15-Stage Pipeline Stepper Bar / Kanban View**: Visual horizontal pipeline showing claim distribution across all 15 stages.
- **Main Data Grid**: Multi-column searchable table with column-level sorting and batch export actions.

---

## 3. Detailed UI Component Hierarchy
1. **Header Component**:
   - `LogoBrand`
   - `GlobalSearchInput` (Debounced 300ms, search across all claim fields)
   - `SyncStatusWidget` (Green: Synced, Yellow: Syncing (X items), Gray: Offline)
   - `CreateSurveyButton`
2. **Metrics Bar**:
   - `MetricCard` (Icon, Title, Value, Subtitle trend)
3. **Pipeline Progress Filter**:
   - `StageTabs` (Numbered 1 to 15 with badge counts)
4. **Claim List Component**:
   - `ClaimDataTable` (Desktop) / `ClaimCardList` (Mobile)
   - `StageBadge` (Color-coded by stage category: Blue=Intake, Orange=Field, Purple=Quantification, Green=Final Report)
   - `SyncStatusIcon` (Local vs Cloud synced)
   - `ContextMenu` (Open Claim, Duplicate, Export Summary, Archive)

---

## 4. Data Fields, Types & Validations

| Field | Type | Validation Rules | Description |
| :--- | :--- | :--- | :--- |
| `search_query` | String | Max 100 chars, alphanumeric | Filters table across Claim ID, Insured, Insurer, Policy # |
| `stage_filter` | Enum (1-15, All) | Optional | Filters claims by exact survey stage |
| `insurer_filter` | String / Dropdown | Optional | Multi-select filter by insurance company |
| `date_range` | Date Range | Optional (Defaults to Last 90 Days) | Filters claims by loss date or appointment date |

---

## 5. AI Assistant Integration & Triggers
- **Smart Priority Recommender**: AI highlights claims that have pending statutory deadlines (e.g., "PSR overdue by 48 hours for National Insurance claim #4412").
- **Natural Language Query**: Surveyor can type in the search bar: *"Show all flood claims assigned this week above 50 Lakhs"* $\rightarrow$ AI filters data grid dynamically.

---

## 6. Offline State & Sync Indicators
- When offline: A top notification bar states: *"Working Offline — All local claims accessible. 4 pending edits will sync once online."*
- Cached claims in SQLite are fully readable and editable.
- Newly created claims receive a local temporary ID (`TEMP-SS-XXXX`) until synced with the server, after which they are assigned a permanent `SS-YYYY-XXXXX` reference.

---

## 7. Action Triggers & Navigation
- **Click on Claim Row/Card**: Navigates to the claim's active stage or Stage Overview screen.
- **Click "+ New Survey"**: Opens `02_appointment_claim_intake`.
- **Swipe on Mobile Card**: Left swipe reveals quick actions: *Call Insured*, *Open Maps*, *Add Photo*.
