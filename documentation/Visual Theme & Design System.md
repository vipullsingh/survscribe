# SurvScribe Visual Theme & Design System Specification
**Version:** 1.0.0-MVP  
**Application:** SurvScribe (Mobile & Web)  
**Design Philosophy:** **"Forensic Precision & Field Ergonomics"** — High-trust, sleek modern aesthetics, single-hand touch ergonomics, sunlight-readable contrast in the field, and pixel-perfect mathematical clarity for claim quantification.

---

## 1. Brand Identity & Visual Tone
- **Archetype**: Precision InsurTech Co-pilot (Authoritative, Objective, Modern, Crisp).
- **Core Visual Drivers**:
  - *Zero Clutter*: High information density balanced by clean whitespace and micro-surfaces.
  - *High Contrast for Field Utility*: Legible outdoors in bright daylight; eye-friendly Dark Mode for late-night desk report drafting.
  - *Forensic Verification Accents*: Color-coded assurance states (Verified Emerald, Discrepancy Amber, Breach Ruby, AI-Grounded Cobalt).

---

## 2. Color Palette & Semantic Tokens

### 2.1 Primary & Accent Brand Colors

| Token Name | Hex Code | HSL | Preview / Usage |
| :--- | :--- | :--- | :--- |
| `--color-brand-primary` | `#1E40AF` | `hsl(224, 76%, 40%)` | **Deep Cobalt Blue** — Main brand identity, primary CTA buttons, active stage steppers |
| `--color-brand-electric` | `#3B82F6` | `hsl(217, 91%, 60%)` | **Electric Azure** — Interactive focus rings, AI generation triggers, audio recording pulses |
| `--color-brand-midnight` | `#0F172A` | `hsl(222, 47%, 11%)` | **Obsidian Slate** — High-contrast text, dark mode canvas, top navigation bars |
| `--color-brand-accent` | `#6366F1` | `hsl(239, 84%, 67%)` | **Indigo Violet** — AI narrative drafting highlights, OCR bounding boxes |

### 2.2 Functional & Claim State Tokens

| Semantic Token | Hex Code | HSL | Applied Context |
| :--- | :--- | :--- | :--- |
| `--color-success-bg` | `#ECFDF5` | `hsl(152, 81%, 96%)` | Verified line items, Admissible claim badge, GPS accuracy $< 5\text{m}$ |
| `--color-success-text` | `#065F46` | `hsl(163, 88%, 20%)` | Math totals matched, 100% Pre-submission audit passed |
| `--color-success-border` | `#10B981` | `hsl(158, 64%, 52%)` | Verified checkmark outline, Active sync complete dot |
| `--color-warning-bg` | `#FFFBEB` | `hsl(48, 100%, 96%)` | Underinsurance / Average clause triggered, Rate variance $> 20\%$ |
| `--color-warning-text` | `#92400E` | `hsl(28, 80%, 31%)` | Pending document requisition, Location address discrepancy |
| `--color-warning-border`| `#F59E0B` | `hsl(38, 92%, 50%)` | Duplicate claim alert outline, Timeline anomaly tag |
| `--color-danger-bg` | `#FEF2F2` | `hsl(0, 86%, 97%)` | Total Loss recommendation, Policy breach flag, Repudiation stance |
| `--color-danger-text` | `#991B1B` | `hsl(0, 70%, 35%)` | Disallowed item, Uninsured premises warning |
| `--color-danger-border` | `#EF4444` | `hsl(0, 84%, 60%)` | Error input border, Critical audit blocker gate |
| `--color-ai-bg` | `#F5F3FF` | `hsl(250, 100%, 98%)` | AI Narrative draft preview box, OCR extracted table background |
| `--color-ai-border` | `#8B5CF6` | `hsl(258, 90%, 66%)` | AI assistant active border, Voice-to-text waveform |

### 2.3 Neutral Surface & Background Scales

```css
/* Light Field Mode (Default - Optimized for Sunlight Readability) */
--bg-app: #F8FAFC;              /* Canvas background (Slate 50) */
--bg-surface: #FFFFFF;          /* Card & Modal surface */
--bg-surface-subtle: #F1F5F9;   /* Inner table rows, input backgrounds */
--border-subtle: #E2E8F0;       /* Card divider lines */
--border-strong: #CBD5E1;       /* Input default borders */
--text-primary: #0F172A;        /* Headlines, financial amounts */
--text-secondary: #475569;      /* Labels, descriptions, dates */
--text-muted: #94A3B8;          /* Placeholders, disabled icons */

/* Dark Desk Mode (Night Review & Low-Light Environments) */
--bg-app-dark: #0B0F19;         /* True Obsidian dark canvas */
--bg-surface-dark: #151C2C;     /* Elevated dark card surface */
--bg-surface-subtle-dark: #1E293B;
--border-subtle-dark: #2A364F;
--border-strong-dark: #3E4D6B;
--text-primary-dark: #F8FAFC;
--text-secondary-dark: #94A3B8;
--text-muted-dark: #64748B;
```

---

## 3. Typography Hierarchy

### 3.1 Font Families
- **Primary Interface Font**: `Plus Jakarta Sans` / `Inter` (Sans-serif) — Geometric, modern, highly legible at small sizes on mobile screens.
- **Financial & Forensic Monospace Font**: `JetBrains Mono` / `Fira Code` (Monospace) — Used for **Policy Numbers, Claim Reference IDs, Currency Figures (₹), GPS Coordinates, and Assessment Table Math** to ensure columnar alignment.

### 3.2 Modular Scale & Type Styles

```css
/* Mobile Typography Tokens */
--text-display: 700 28px/34px 'Plus Jakarta Sans', sans-serif;  /* Screen Titles on Mobile */
--text-h1:      700 22px/28px 'Plus Jakarta Sans', sans-serif;  /* Card Section Headers */
--text-h2:      600 18px/24px 'Plus Jakarta Sans', sans-serif;  /* Sub-sections & Accordion Titles */
--text-h3:      600 15px/20px 'Plus Jakarta Sans', sans-serif;  /* Field Group Titles */
--text-body-lg: 500 15px/22px 'Plus Jakarta Sans', sans-serif;  /* Primary Form Text */
--text-body:    400 14px/20px 'Plus Jakarta Sans', sans-serif;  /* Descriptions & Narratives */
--text-body-sm: 400 12px/16px 'Plus Jakarta Sans', sans-serif;  /* Helper Text, Metadata */
--text-caption: 600 11px/14px 'Plus Jakarta Sans', sans-serif;  /* Badges, Stage Chips, Uppercase Tags */

/* Monospace Numbers */
--text-money-hero: 700 24px/28px 'JetBrains Mono', monospace;  /* Net Recommended Amount Header */
--text-money-grid: 600 14px/18px 'JetBrains Mono', monospace;  /* Assessment Table Cells */
--text-mono-code:  500 12px/16px 'JetBrains Mono', monospace;  /* GPS Lat/Lng & Serial Numbers */
```

---

## 4. Form Controls & Input Design System

### 4.1 Text Inputs & Dropdowns

```
+----------------------------------------------------------------+
|  Label: Insured Legal Name *                                  |
|  +----------------------------------------------------------+  |
|  | ABC Manufacturing Pvt. Ltd.                              |  |
|  +----------------------------------------------------------+  |
|  Helper text: Must match the policy schedule entity exactly   |
+----------------------------------------------------------------+
```

- **Dimensions**:
  - Height: `50px` (Mobile touch target $\ge 48\text{px}$) / `42px` (Desktop).
  - Corner Radius: `10px` (`--radius-md`).
  - Padding: `12px 16px`.
- **States & Visual Styling**:
  - **Default**: Background `#FFFFFF`, Border `1.5px solid #CBD5E1`, Text `#0F172A`.
  - **Hover**: Border `1.5px solid #94A3B8`.
  - **Focus**: Border `2px solid #1E40AF`, Box-shadow `0 0 0 4px rgba(30, 64, 175, 0.12)`.
  - **Filled / Valid**: Background `#F8FAFC`, Border `1.5px solid #CBD5E1`.
  - **Error**: Border `2px solid #EF4444`, Box-shadow `0 0 0 4px rgba(239, 68, 68, 0.12)`, Error message in `#991B1B` with `AlertCircle` icon.
  - **Disabled / Read-Only**: Background `#F1F5F9`, Border `1px solid #E2E8F0`, Text `#94A3B8`.

### 4.2 Specialized Inputs

#### Currency & Numeric Inputs (₹)
- Left Prefix: Fixed dark chip with Indian Rupee symbol `₹` in `#1E40AF` bold text.
- Right Suffix: Optional unit chip (e.g., `Nos`, `Kgs`, `SqMtr`).
- Font: `JetBrains Mono` with automated comma formatting (`12,50,000.00`).

#### Voice-Enabled Smart Field Notes (Microphone Integration)
- Embedded inside input/textarea at right side.
- Interactive pulsating button:
  - *Idle*: Neutral gray microphone icon `#64748B`.
  - *Recording*: Vibrant `#EF4444` red pulse with radial sound wave animation and *"Listening..."* floating pill.
  - *Transcribing*: Shimmering `#8B5CF6` purple gradient.

#### Mobile Date & Time Selectors
- Native iOS / Android modal wheels on mobile.
- Quick shortcut chips: `[ Today ]`, `[ Yesterday ]`, `[ 10:00 AM ]`, `[ 02:30 PM ]`.

---

## 5. Buttons, Actions & Interactive Components

### 5.1 Button Hierarchy

```css
/* 1. Primary Action CTA */
.btn-primary {
  background: linear-gradient(135deg, #1E40AF 0%, #1D4ED8 100%);
  color: #FFFFFF;
  font-weight: 600;
  font-size: 15px;
  height: 50px;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(30, 64, 175, 0.25);
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}
.btn-primary:active {
  transform: scale(0.98);
  box-shadow: 0 2px 6px rgba(30, 64, 175, 0.2);
}

/* 2. Secondary Outline */
.btn-secondary {
  background: #FFFFFF;
  color: #1E40AF;
  border: 1.5px solid #CBD5E1;
  height: 50px;
  border-radius: 12px;
}

/* 3. AI Smart Action Button */
.btn-ai-magic {
  background: linear-gradient(135deg, #6366F1 0%, #8B5CF6 100%);
  color: #FFFFFF;
  border-radius: 12px;
  box-shadow: 0 4px 14px rgba(99, 102, 241, 0.3);
  display: flex;
  align-items: center;
  gap: 8px;
}

/* 4. Floating Action Button (FAB - Mobile) */
.btn-fab {
  position: fixed;
  bottom: 80px;
  right: 20px;
  width: 58px;
  height: 58px;
  border-radius: 29px;
  background: #1E40AF;
  color: #FFFFFF;
  box-shadow: 0 8px 24px rgba(30, 64, 175, 0.4);
}
```

---

## 6. Cards, Modals & Mobile Bottom Sheets

### 6.1 Card Elevation & Glassmorphism
- **Base Card**: White surface `#FFFFFF`, Border `1px solid #E2E8F0`, Corner Radius `16px`, Box-shadow `0 2px 8px rgba(15, 23, 42, 0.04)`.
- **Active / Focused Card**: Border `1.5px solid #3B82F6`, Box-shadow `0 8px 20px rgba(59, 130, 246, 0.1)`.
- **Glassmorphic Floating Top/Bottom Bars**:
  - Background: `rgba(255, 255, 255, 0.88)` (Light) / `rgba(15, 23, 42, 0.88)` (Dark).
  - Backdrop Filter: `blur(12px) saturate(180%)`.
  - Border: `1px solid rgba(226, 232, 240, 0.6)`.

### 6.2 Mobile Bottom Sheets
- Triggered for: *Document OCR verification, OTP verification, Photo category tagger, Voice memo details*.
- UI Features:
  - Top central drag handle pill (`40px x 5px`, `#CBD5E1`, rounded).
  - Smooth slide-up transition with dark dimmed backdrop (`rgba(15, 23, 42, 0.5)`).
  - Sticky bottom action buttons.

---

## 7. Photo Studio & Forensic Watermark Specification

### 7.1 Camera HUD & Overlay Interface
- **Top HUD**: GPS lock indicator (`🟢 GPS Locked ±3m`), Flash toggle, Aspect ratio toggle (4:3 standard).
- **Center Focus Square**: Forensic crosshair grid for aligning machinery nameplates and crack measurements.
- **Bottom HUD**: Category tag picker pill (*Overall View*, *Damaged Asset*, *Nameplate/Serial*, *Origin Evidence*), Shutter button with haptic feedback.

### 7.2 Indelible Photo Watermark Layout

```
+----------------------------------------------------------------+
| [ PHOTO EVIDENCE VIEW ]                                        |
|                                                                |
|                                                                |
|                                                                |
|                                                                |
| +------------------------------------------------------------+ |
| | SurvScribe Certified Evidence | Claim: SA-2026-00101       | |
| | Lat: 19.0760° N, Lng: 72.8777° E (Acc: ±3.2m)              | |
| | Date: 2026-08-29 14:32:05 IST | Category: Serial Plate     | |
| +------------------------------------------------------------+ |
+----------------------------------------------------------------+
```
- **Watermark Strip**: Solid semi-transparent dark bar (`rgba(0, 0, 0, 0.75)`) at bottom-left of photo.
- **Text**: Crisp white monospace font `#FFFFFF`, size `11px`, with surveyor SLA license and claim reference ID.

---

## 8. Status Badges, Chips & Progress Indicators

### 8.1 15-Stage Progress Chip Tokens
| Stage Group | Badge Color | Background | Text Color |
| :--- | :--- | :--- | :--- |
| **Intake (Stages 1–3)** | Cool Blue | `#EFF6FF` | `#1D4ED8` |
| **Field Survey (Stages 4–7)** | Vivid Orange | `#FFF7ED` | `#C2410C` |
| **Forensic Audit (Stages 8–10)**| Violet Indigo | `#F5F3FF` | `#6D28D9` |
| **Quantification (Stages 11–13)**| Cyan Teal | `#ECFEFF` | `#0E7490` |
| **Final Report (Stages 14–15)** | Emerald Green| `#ECFDF5` | `#047857` |

### 8.2 Offline / Online Sync Indicator
- **Online & Fully Synced**: Circular pill with green dot: `🟢 Synced with Cloud`.
- **Sync in Progress**: Circular pill with rotating amber arrows: `🔄 Syncing 4 items...`.
- **Offline Mode**: Circular pill with gray cloud strike: `☁️ Offline — Local SQLite Active`.

---

## 9. Animation & Micro-Interactions
- **Transitions**: `150ms` to `250ms` using `cubic-bezier(0.4, 0, 0.2, 1)`.
- **Card Tap**: Subtly scales to `0.98` with medium haptic feedback on mobile.
- **AI Narrative Generating**: Subtle shimmering violet border glow with typing cursor simulation.
- **Number Counters**: Smooth rolling counter animation when calculation totals update.
