# SurvScribe Visual Theme & Design System Specification
**Version:** 2.0.0-Enterprise  
**Application:** SurvScribe (Mobile Field App & Web Workspace)  
**Target Domain:** General Insurance Surveyors, Loss Assessors (SLA) & Insurer Operations  
**Design Philosophy:** **"Enterprise Precision, Operational Trust & Field Ergonomics"**

---

## 1. Executive Summary & Design Philosophy

SurvScribe is an enterprise-grade SaaS platform engineered for licensed Insurance Surveyors and Loss Assessors (SLA). It handles mission-critical insurance claims, forensic physical evidence, statutory police/fire reports, and legally binding financial loss assessments.

The interface is designed as a **mature, authoritative B2B SaaS tool** created by seasoned product designers for financial and insurance operations. It deliberately avoids the visual tropes of consumer apps, Dribbble concepts, and generic AI dashboards.

### Core Brand Attributes
- **Professionalism & Trust**: Conservative, institutional visual tone appropriate for insurers, court proceedings, and statutory audits.
- **Accuracy & Mathematical Authority**: Pixel-perfect numerical alignment, right-aligned monetary values, and transparent audit trails.
- **Structured Case Management**: Predictable information architecture inspired by mature financial analysis, legal tech, and case management platforms.
- **Field Ergonomics**: Touch-optimized, high-contrast layouts built for harsh outdoor sunlight, one-handed mobile use, and intermittent cellular connectivity.
- **Restrained AI Assistance**: AI features operate as unobtrusive, grounded workflow utilities rather than dominating chatbot novelties.

---

## 2. Critical Anti-Patterns (Eliminating the "AI-Generated UI" Look)

To maintain enterprise credibility and avoid looking like an AI-generated template, the application strictly adheres to the following UI prohibitions:

| Prohibited Anti-Pattern | Reason for Exclusion | Approved Enterprise Pattern |
| :--- | :--- | :--- |
| **Excessive Gradients & Glowing Edges** | Looks like a consumer tech landing page / crypto app | Solid, refined neutral surfaces with crisp `1px` subtle borders (`#E2E8F0` / `#CBD5E1`) |
| **Neon / Cyberpunk Accents** | Destroys institutional trust and legibility | Conservative Deep Cobalt (`#1E3A8A`) and Slate (`#0F172A`) palette |
| **Oversized Rounded Cards ($> 20\text{px}$)** | Wastes valuable vertical screen space and feels childish | Restrained `6px` to `10px` radii for form controls; `8px` to `12px` for surface cards |
| **Random Floating Widgets & Chatbots** | Distracts from the sequential 15-stage survey lifecycle | Contextual, inline tools embedded directly inside the relevant workflow stage |
| **Heavy Glassmorphism & Blurs** | Impairs readability in bright outdoor sunlight | Opaque, high-contrast surfaces (`#FFFFFF` on `#F8FAFC`) with subtle solid dividers |
| **Decorative "Sparkles" & AI Icons** | Communicates experimental novelty rather than forensic rigor | Professional, standard utility labels (*"Draft Narrative"*, *"Extract Details"*, *"Verify Consistency"*) |
| **Gamified Progress Steppers** | Inappropriate for formal loss adjusting | Professional, linear case progress tracker showing status, pending items, and compliance gates |
| **Huge Display Headings** | Consumes critical screen real estate needed for evidence and tables | Tight, functional typographic hierarchy ($20\text{px} - 24\text{px}$ max section titles) |
| **Excessive Competing Badges** | Creates visual noise and alarm fatigue | Strict semantic color rules: Green for verified, Amber for warnings, Red for critical blocks |

---

## 3. Design System Foundations & Design Tokens

### 3.1 Color Palette & Semantic Tokens

The color system is conservative, restrained, and purposeful. Color is used exclusively to convey information hierarchy, interactive affordance, or critical operational state.

> **Canonical primary blue (Decision 2026-08-30):** `--color-primary: #1E3A8A`, `--color-primary-hover: #1E40AF`, `--color-primary-active: #172554`. This token scale in this document is authoritative for the UI. The logo/brand-mark assets use `#1E40AF` as an intentional brand shade; do not "correct" the logos to `#1E3A8A`.

```
PRIMARY BRAND PALETTE
-------------------------------------------------------------------------------------------------
Deep Navy / Cobalt       #1E3A8A   hsl(224, 76%, 33%)   Primary brand actions, active state markers
Slate Midnight           #0F172A   hsl(222, 47%, 11%)   Primary typography, dark navigation headers
Slate Cool               #475569   hsl(215, 19%, 35%)   Secondary labels, timestamps, table column headers
Slate Border             #CBD5E1   hsl(214, 32%, 91%)   Input borders, structural container outlines
Surface Base (Canvas)    #F8FAFC   hsl(210, 40%, 98%)   Application background canvas (Slate 50)
Surface Pure (Card)      #FFFFFF   hsl(0, 0%, 100%)     Workplace cards, data tables, modal surfaces
-------------------------------------------------------------------------------------------------

FUNCTIONAL & SEMANTIC TOKENS (Strict Utility Usage)
-------------------------------------------------------------------------------------------------
Success Emerald          #059669   hsl(160, 84%, 31%)   Verified line items, matched arithmetic, sign-off complete
Success Background       #F0FDF4   hsl(140, 60%, 97%)   Background fill for verified status chips (Border: #BBF7D0)
Warning Amber            #D97706   hsl(38, 92%, 44%)    Underinsurance detected, rate discrepancy, pending documents
Warning Background       #FFFBEB   hsl(48, 100%, 96%)   Background fill for warning banners (Border: #FDE68A)
Critical Crimson         #DC2626   hsl(0, 72%, 51%)     Policy breach, location discrepancy blocker, disallowed claim
Critical Background      #FEF2F2   hsl(0, 86%, 97%)     Background fill for critical blocker alerts (Border: #FECACA)
Interactive Link         #2563EB   hsl(217, 91%, 60%)   Hyperlinks, secondary clickable utility triggers
-------------------------------------------------------------------------------------------------
```

```css
:root {
  /* Canvas & Neutral Surfaces */
  --bg-app: #F8FAFC;
  --bg-surface: #FFFFFF;
  --bg-surface-subtle: #F1F5F9;
  --bg-surface-muted: #E2E8F0;

  /* Typography Colors */
  --text-primary: #0F172A;
  --text-secondary: #475569;
  --text-muted: #94A3B8;
  --text-inverse: #FFFFFF;

  /* Borders & Dividers */
  --border-subtle: #E2E8F0;
  --border-default: #CBD5E1;
  --border-strong: #94A3B8;
  --border-focus: #1E3A8A;

  /* Brand Primary */
  --color-primary: #1E3A8A;
  --color-primary-hover: #1E40AF;
  --color-primary-active: #172554;
  --color-primary-subtle: #EFF6FF;

  /* Semantic State Tokens */
  --state-success-text: #065F46;
  --state-success-bg: #F0FDF4;
  --state-success-border: #BBF7D0;

  --state-warning-text: #92400E;
  --state-warning-bg: #FFFBEB;
  --state-warning-border: #FDE68A;

  --state-danger-text: #991B1B;
  --state-danger-bg: #FEF2F2;
  --state-danger-border: #FECACA;

  /* Elevation & Shadows (Restrained) */
  --shadow-xs: 0 1px 2px 0 rgba(15, 23, 42, 0.05);
  --shadow-sm: 0 1px 3px 0 rgba(15, 23, 42, 0.08), 0 1px 2px -1px rgba(15, 23, 42, 0.08);
  --shadow-md: 0 4px 6px -1px rgba(15, 23, 42, 0.08), 0 2px 4px -2px rgba(15, 23, 42, 0.06);
  --shadow-modal: 0 20px 25px -5px rgba(15, 23, 42, 0.12), 0 8px 10px -6px rgba(15, 23, 42, 0.08);

  /* Radii */
  --radius-xs: 4px;
  --radius-sm: 6px;
  --radius-md: 8px;
  --radius-lg: 12px;
}
```

---

### 3.2 Typography Hierarchy

SurvScribe uses **Inter** (or **Plus Jakarta Sans**) as its primary typeface, paired with **JetBrains Mono** for financial figures, policy numbers, GPS coordinates, and mathematical calculations.

```
TYPOGRAPHY SPECIFICATION TABLE
-------------------------------------------------------------------------------------------------
Level / Token       Font Family         Size / Line Height    Weight     Applied Context
-------------------------------------------------------------------------------------------------
Page Title          Plus Jakarta Sans   20px / 28px          700 (Bold) Top app bar, desktop headers
Section Header (H1) Plus Jakarta Sans   16px / 24px          700 (Bold) Major card headers, stage titles
Card Title (H2)     Plus Jakarta Sans   14px / 20px          600 (Semi) Sub-sections, modal headers
Field Label         Plus Jakarta Sans   12px / 16px          600 (Semi) Form labels, column headers
Body Text           Inter / System      13px / 18px          400 (Reg)  General field values, descriptions
Body Small          Inter / System      11px / 16px          400 (Reg)  Helper text, photo timestamps
Badge / Chip Text   Inter / System      11px / 14px          600 (Semi) Status chips, stage tags (uppercase)

Financial / Table   JetBrains Mono      13px / 18px          500 (Med)  Assessment amounts, tax values
Financial Total     JetBrains Mono      15px / 20px          700 (Bold) Subtotals, Net Recommended sum
Forensic Monospace  JetBrains Mono      11px / 14px          400 (Reg)  GPS lat/lng, SLA license #, serials
-------------------------------------------------------------------------------------------------
```

```css
/* Tabular Figures Formatting Rule */
.font-mono-num {
  font-family: 'JetBrains Mono', monospace;
  font-feature-settings: "tnum" 1, "zero" 1;
  text-align: right;
}
```

---

### 3.3 Spacing & Layout Grid Tokens

Layouts are constructed on an **8pt grid** (with a `4pt` sub-unit for fine alignments). Spacing is compact and dense to ensure surveyors can view complete evidence records and loss matrices without endless scrolling.

```
SPACING TOKENS
--space-1:  4px    (Micro gaps, inline badges)
--space-2:  8px    (Icon-to-text spacing, compact form gaps)
--space-3: 12px    (Form field vertical gaps, inner chip padding)
--space-4: 16px    (Standard card interior padding, mobile screen padding)
--space-5: 20px    (Section dividers, desktop column gutters)
--space-6: 24px    (Major card separation)
--space-8: 32px    (Page section spacing)
```

---

### 3.4 Iconography & Visual Stroke Rules

- **Icon Set**: Standard enterprise outline icons (Lucide / Heroicons outline).
- **Stroke Width**: Strict `1.5px` stroke (no heavy bold icons, no cartoon 3D illustrations, no colored emoji icons in functional tables).
- **Size Standards**:
  - `16px × 16px`: Form inputs, table action buttons, inline badges.
  - `20px × 20px`: Navigation items, section headers, primary actions.
  - `24px × 24px`: Camera HUD controls, evidence upload drop zones.

---

## 4. Component Design System

### 4.1 Form Controls & Input Fields

Form controls feature clean borders, visible focus rings, and clear helper cues.

```
+-------------------------------------------------------------------------+
|  Policy Sum Insured (Building) *                                       |
|  +-------------------------------------------------------------------+  |
|  |  ₹  |  2,50,00,000.00                                             |  |
|  +-------------------------------------------------------------------+  |
|  Matches Schedule Section 1 (Standard Fire & Special Perils)           |
+-------------------------------------------------------------------------+
```

- **Height**: `44px` (Mobile touch baseline) / `38px` (Desktop dense layout).
- **Border**: `1px solid #CBD5E1` (Default) $\rightarrow$ `1.5px solid #1E3A8A` with `0 0 0 3px rgba(30, 58, 138, 0.1)` on Focus.
- **Background**: `#FFFFFF` (Active) / `#F1F5F9` (Read-only / Locked).
- **Currency Field Affordance**: Solid neutral prefix chip `₹` in `#475569` with right-aligned monospace value.

---

### 4.2 Button & Action Hierarchy

Buttons communicate clear intent through restrained styling:

```css
/* 1. Primary Action (Save, Submit, Continue) */
.btn-primary {
  background-color: #1E3A8A;
  color: #FFFFFF;
  font-size: 13px;
  font-weight: 600;
  height: 44px;
  padding: 0 16px;
  border-radius: 6px;
  border: 1px solid #172554;
  box-shadow: var(--shadow-xs);
}
.btn-primary:hover {
  background-color: #1E40AF;
}

/* 2. Secondary Action (Cancel, Back, Add Row) */
.btn-secondary {
  background-color: #FFFFFF;
  color: #0F172A;
  font-size: 13px;
  font-weight: 600;
  height: 44px;
  padding: 0 16px;
  border-radius: 6px;
  border: 1px solid #CBD5E1;
  box-shadow: var(--shadow-xs);
}
.btn-secondary:hover {
  background-color: #F8FAFC;
  border-color: #94A3B8;
}

/* 3. Destructive Action (Delete Item, Disallow) */
.btn-destructive {
  background-color: #FFFFFF;
  color: #DC2626;
  font-size: 13px;
  font-weight: 600;
  height: 44px;
  padding: 0 16px;
  border-radius: 6px;
  border: 1px solid #FECACA;
}
.btn-destructive:hover {
  background-color: #FEF2F2;
}

/* 4. Utility / Integrated AI Action (Restrained, Professional) */
.btn-ai-utility {
  background-color: #F8FAFC;
  color: #1E3A8A;
  font-size: 12px;
  font-weight: 600;
  height: 36px;
  padding: 0 12px;
  border-radius: 6px;
  border: 1px solid #CBD5E1;
  display: inline-flex;
  align-items: center;
  gap: 6px;
}
.btn-ai-utility:hover {
  background-color: #EFF6FF;
  border-color: #93C5FD;
}
```

---

### 4.3 Enterprise Data Tables & Loss Quantification Grids

Stage 11 Loss Assessment is the mathematical core of the application. It is styled like an authoritative financial ledger:

```
+-------------------------------------------------------------------------------------------------------------------------+
| LOSS QUANTIFICATION MATRIX — HEAD 2: PLANT & MACHINERY                                               [ + Add Item ]     |
+-------------------------------------------------------------------------------------------------------------------------+
| Item Description        | Claimed (₹)   | Assessed (₹)  | Depr % | Depr (₹)    | Salvage (₹) | Excess (₹)  | Net Loss (₹)   |
+-------------------------+---------------+---------------+--------+-------------+-------------+-------------+----------------+
| CNC Milling Center VMC  | 14,50,000.00  | 12,00,000.00  | 25.0%  | 3,00,000.00 | 1,20,000.00 |   50,000.00 |   7,30,000.00  |
| 150 kVA DG Set (Burnt)  |  6,20,000.00  |  5,80,000.00  | 30.0%  | 1,74,000.00 |   65,000.00 |   25,000.00 |   3,16,000.00  |
| Control Panel Wiring    |  1,80,000.00  |  1,40,000.00  |  0.0%  |        0.00 |    5,000.00 |   10,000.00 |   1,25,000.00  |
+-------------------------+---------------+---------------+--------+-------------+-------------+-------------+----------------+
| HEAD 2 SUB-TOTAL        | 22,50,000.00  | 19,20,000.00  |        | 4,74,000.00 | 1,90,000.00 |   85,000.00 |  11,71,000.00  |
+-------------------------------------------------------------------------------------------------------------------------+
```

- **Header Row**: `#F1F5F9` background, `11px` bold uppercase text `#475569`, bottom border `1.5px solid #CBD5E1`.
- **Data Rows**: `#FFFFFF` background with alternating `#F8FAFC` subtle rows; right-aligned monospace values (`JetBrains Mono`).
- **Subtotals & Total Summary Row**: Highlighted background `#F8FAFC`, top border `2px solid #0F172A`, bold `14px` monospace figures.
- **Inline Justification Indicators**: Expandable chevron showing surveyor's mandatory depreciation & rate deduction justification remarks.

---

### 4.4 Evidence & Inspection Management (Photo Studio & Case File)

Photo grids and evidence lockers are designed as **traceable, audit-ready case files**:

```
+-------------------------------------------------------------------------+
| EVIDENCE ITEM #04: Control Panel Internal Flashover                     |
| +---------------------------------------------------------------------+ |
| | [ HIGH-RES CAPTURED PHOTO WITH INDELIBLE WATERMARK STRIP ]          | |
| |                                                                     | |
| | +-----------------------------------------------------------------+ | |
| | | SurvScribe Certified SLA Evidence | Claim: SS-2026-00101        | | |
| | | Lat: 19.0760° N, Lng: 72.8777° E (GPS Acc: ±2.4m) | 2026-08-29  | | |
| | | Cat: Damage Origin / Close-up | Surveyor SLA: 10294             | | |
| | +-----------------------------------------------------------------+ | |
| +---------------------------------------------------------------------+ |
| Linked Item: Item #2 (150 kVA Control Panel) • Category: Origin Point   |
| Caption: Severe arc tracking observed on main 400A busbar contacts.    |
+-------------------------------------------------------------------------+
```

- **Grid Card Structure**: Solid `1px solid #E2E8F0` border, `8px` radius, clear metadata row (Timestamp, GPS Accuracy, Category Tag).
- **Watermark Banner**: Solid semi-transparent dark container (`rgba(15, 23, 42, 0.85)`) embedded in photo bottom strip with high-contrast white monospace text.
- **Audit Linking**: Clear tag indicating which Stage 6 Damage Register item or Stage 10 Claim Invoice this photo verifies.

---

### 4.5 Case Lifecycle & 15-Stage Progress Tracker

The 15 survey stages are represented as a clean, professional linear pipeline rather than a gamified colorful stepper:

```
+-------------------------------------------------------------------------------------------------------------------------+
| STAGE 13 OF 15: Coverage & Liability Consideration                             [ 85% Complete ] [ 1 Warning Pending ]    |
| +---------------------------------------------------------------------------------------------------------------------+ |
| | (✓) 01. Intake  (✓) 02. Policy  (✓) 04. Location  ...  (●) 13. Liability  (○) 14. FSR Builder  (○) 15. Sign & Submit | |
| +---------------------------------------------------------------------------------------------------------------------+ |
+-------------------------------------------------------------------------------------------------------------------------+
```

- **Completed Stage**: Small green checkmark `(✓)` with `#059669` text.
- **Active Stage**: Solid Deep Cobalt circle `(●)` with bold `#1E3A8A` text and subtle bottom indicator line.
- **Upcoming Stage**: Neutral gray circle `(○)` with `#94A3B8` text.
- **Discrepancy / Warning Flag**: Inline amber warning tag indicating unresolved items before report compilation.

---

## 5. Subtle & Professional AI Integration Patterns

AI tools inside SurvScribe are designed as **grounded, reliable assistants for the licensed surveyor**. They never dominate the screen or make autonomous claims decisions.

### 5.1 AI Action Nomenclature & Visual Framing

| Feature Area | Prohibited "AI Gimmick" Label | Approved Enterprise SaaS Label | UI Component Type |
| :--- | :--- | :--- | :--- |
| **FSR Report Drafting** | *"Magic AI Write" / "Generate Super Report"* | **"Draft Narrative with Field Notes"** | Secondary utility button with clean text editor |
| **Invoice Line Item OCR** | *"AI Smart Vision Extract"* | **"Extract Invoice Line Items"** | Side-by-side verification table with bounding boxes |
| **Fraud & Duplicate Audit** | *"AI Fraud Detector"* | **"Check Claim Discrepancies"** | Structured reconciliation table with source links |
| **Speech-to-Text Notes** | *"AI Voice Wizard"* | **"Record Voice Field Note"** | Standard microphone recorder with editable text preview |
| **Policy Clause Review** | *"AI Policy Oracle"* | **"Review Applicable Warranties"** | Highlighted checklist based on verified peril |

### 5.2 Discrepancy & Consistency Review Box

When AI detects a variance (e.g., between FIR loss time and factory security logs), it renders as a **structured audit finding**:

```
+-------------------------------------------------------------------------+
| ⚠️ TIMELINE VARIANCE DETECTED (Audit Flag)                              |
| Reported Time of Loss in Claim Intimation: 02:30 AM                     |
| Fire Brigade Turnout Time in Station Report: 04:15 AM (1h 45m variance) |
| [ Action Required: Document reason for delayed notification in Sec C ]  |
+-------------------------------------------------------------------------+
```
- **Styling**: `#FFFBEB` surface, `1px solid #FDE68A` border, `#92400E` text, and actionable resolution link for the surveyor.

---

## 6. Application Layout Specifications

### 6.1 Mobile Application (Field Operations Tool)

The mobile view is ergonomically optimized for single-handed use during site inspections in noisy, outdoor industrial environments.

```
+-------------------------------------------------------------------------+
| [ 09:41 ]                      [ 🟢 Synced ] [ ☁️ Offline Vault Ready ]  |
+-------------------------------------------------------------------------+
| CLAIM: SS-2026-00101 • ABC Manufacturing Pvt. Ltd.                      |
| Stage 6 of 15: Damage Documentation Studio                              |
+-------------------------------------------------------------------------+
|                                                                         |
|  [ + Capture Photo with Watermark ]      [ 🎙️ Voice Note Record ]       |
|                                                                         |
|  DAMAGED PROPERTY REGISTER (3 Items Logged)                             |
|  +-------------------------------------------------------------------+  |
|  | Item #1: Main Transformer Unit 500 kVA                            |  |
|  | Severity: Total Burnout • Recommendation: Replace                 |  |
|  | Photos Attached: 4 Photos (GPS & Watermarks Verified)             |  |
|  +-------------------------------------------------------------------+  |
|                                                                         |
+-------------------------------------------------------------------------+
| [ STICKY BOTTOM ACTION: Save & Continue to Ownership Verification (→) ] |
+-------------------------------------------------------------------------+
| [ 🏠 Dashboard ] [ 📋 Claims ] [ 📷 Studio ] [ 📄 Reports ] [ ⚙️ More ] |
+-------------------------------------------------------------------------+
```

- **Sticky Header**: Shows active claim reference ID, insured name, and unobtrusive cloud sync/offline status badge.
- **Prominent Primary Actions**: High-contrast, large touch targets ($\ge 48\text{px}$) for camera capture, voice recording, and item addition.
- **Sticky Bottom Action Bar**: Always provides one-tap access to save progress and proceed to the next survey stage.
- **Bottom Navigation (canonical, 5 tabs)**: `Dashboard` · `Claims` · `Field Studio` · `Reports` · `Profile`. (This is the authoritative label set; screen specs reference it.)

---

### 6.2 Desktop Companion Application (Professional Workspace) — POST-MVP

> **Scope note (2026-08-30):** The desktop companion is **deferred beyond the MVP**. This section and the "Responsive Desktop Web View" blocks in the screen specs are retained as forward-looking design, not MVP build targets. The MVP ships the React Native mobile app only.

The desktop companion provides a dense, multi-pane workstation for detailed loss quantification, document OCR reconciliation, and FSR compilation.

```
+-------------------------------------------------------------------------------------------------------------------------+
| SurvScribe | Claims / SS-2026-00101 / Stage 10: Document Forensic Audit                     [ User: SLA-10294 | Sync: OK ] |
+-------------------------------------------------------------------------------------------------------------------------+
| SIDEBAR NAV       | MAIN WORKSPACE: SPLIT-SCREEN DOCUMENT RECONCILIATION                                                |
| • Dashboard       | +-----------------------------------------+-------------------------------------------------------+ |
| • All Claims (42) | | ORIGINAL INVOICE (Scanned PDF)          | OCR EXTRACTED LINE ITEMS                              | |
| • Active Stages   | | Siemens India Invoice #INV-9821         | Line 1: 400A MCCB Switchgear     | ₹ 45,000.00 [ ✓ ]  | |
|   01. Intake      | | Date: 12-Jan-2024                       | Line 2: 120sqmm XLPE Copper Cable| ₹ 82,000.00 [ ✓ ]  | |
|   ...             | | [ Embedded PDF Viewer with Bounding Box]| Line 3: Labor & Installation Cost| ₹ 18,000.00 [ ✓ ]  | |
|   10. Audit (●)   | +-----------------------------------------+-------------------------------------------------------+ |
|   11. Loss Matrix | AUDIT REMARKS: Invoice verified against Far Extract capitalization date. No betterment detected.   |
|   14. FSR Builder | [ + Add Disallowed Items ]               [ Verify All & Transfer to Head 2 Loss Table ]           |
+-------------------------------------------------------------------------------------------------------------------------+
```

- **Structured Collapsible Sidebar**: Quick navigation across claim lifecycle stages and active case files.
- **Split-Screen Verification Layouts**: 50/50 split allowing side-by-side inspection of source PDFs vs. extracted data tables.
- **Contextual Right-Hand Inspector**: Shows policy warranties, insured history, and audit discrepancies without navigating away from the calculation sheet.

---

## 7. Accessibility, Contrast & Production Quality Standards

SurvScribe is engineered to meet strict institutional software compliance standards:

1. **WCAG 2.1 AA Compliance**:
   - High text contrast: Minimum `4.5:1` for normal text; `7:1` for financial table figures against white/slate surfaces.
   - Sunlight outdoor legibility tested with high-contrast `#0F172A` text on pure `#FFFFFF` background.
2. **Keyboard Navigation & Desktop Efficiency**:
   - Full keyboard navigation across data tables (`Tab`, `Shift+Tab`, `Arrow keys`, `Enter` to edit cells).
3. **No Placeholder Content**:
   - Every mockup and production screen uses authentic insurance terminology (e.g., *Sum Insured, Value at Risk, Pro-rata Average Clause, Salvage Value, Policy Excess, Reinstatement Value Clause*).
4. **Resilient Offline Architecture**:
   - Offline indicators are clear and calming, assuring the surveyor that local AES-256 SQLite storage is active and changes will seamlessly sync when connectivity returns.

---

## 8. Summary Checklist for UI Implementations

Before any screen or UI component is marked approved, it must pass this validation checklist:

- [x] Does it look like a **serious B2B financial/insurance SaaS application** (like FactSet, Guidewire, or Linear) rather than an AI template?
- [x] Are financial figures right-aligned in monospace (`JetBrains Mono`) with comma separators and currency symbols?
- [x] Are AI capabilities labeled with objective utility names (*"Draft Narrative"*, *"Extract Details"*) without sparkles, neon colors, or chatbot widgets?
- [x] Are status colors strictly limited to green (verified), amber (warning), and red (critical blocker)?
- [x] Are touch targets on mobile at least `44px` to `48px` with sticky primary actions?
- [x] Is the 15-stage workflow structured as a clear, professional case management pipeline?
