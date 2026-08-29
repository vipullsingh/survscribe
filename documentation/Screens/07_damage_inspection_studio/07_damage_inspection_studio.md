# Screen Specification: 07_damage_inspection_studio

## 1. Screen Objective & Context
- **Screen Name**: Physical Inspection & Damage Documentation Studio
- **Stage Mapping**: Stage 6 of 15 (Physical Inspection and Documentation of Damage)
- **Purpose**: Core on-site field inspection workspace. Allows the surveyor to record itemized damaged property inventories (make, model, serial no, extent of damage, repair vs replace recommendation), capture watermarked geo-tagged photographs/videos across categorized views, and record voice notes transcribed in real-time. Directly answers *"What was damaged?"*.

---

## 2. Layout & UI Architecture

### 2.1 Primary Mobile App View (iOS & Android) - Core Mobile Experience
- **Field Inspection Hub**:
  - Top: Horizontal Asset Category Carousel (*Building*, *Plant & Machinery*, *Stock*, *Electrical*, *Furniture*).
  - Prominent "Smart Camera" Button: Opens native camera with automatic GPS, timestamp, and surveyor ID watermark overlay.
  - Prominent "Voice Field Note" Button: Hold-to-record voice observations with live AI transcription into item descriptions.
  - Item List Cards with swipe gestures: *Add Photos*, *Mark Repairable*, *Mark Total Loss*, *Delete*.
  - Floating Quick-Add Item (`+`) button.
  - Offline thumbnail gallery showing cached photos pending cloud sync.
  - Bottom Action Bar: "Proceed to Ownership Locker".

### 2.2 Responsive Desktop Web View
- **Three-Pane Studio Layout**:
  - **Left Pane (30% width)**: Damaged Property Item Tree / Category Selector with item counts and total damaged values.
  - **Middle Pane (45% width)**: Damaged Item Specification Editor & Voice Note Transcript Reviewer.
  - **Right Pane (25% width)**: Photo & Media Gallery (Grid of categorized, watermarked photos linked to active item).

---

## 3. Detailed UI Component Hierarchy
1. **Itemized Damage Inventory Register**:
   - `CategorySelector`: Dropdown/Pills (*Building / Civil*, *Plant & Machinery*, *Electrical Installations*, *Furniture & Fixtures*, *Raw Materials / Stock*, *Finished Goods*).
   - `DamageItemTable` (Desktop) / `DamageCardList` (Mobile):
     - `ItemNameInput` (e.g., "CNC Milling Machine 5-Axis")
     - `MakeModelCapacityInput` (e.g., "Haas VF-4 / 12,000 RPM")
     - `SerialNumberInput` (Asset Tag / Serial Number)
     - `QuantityInput` & `UOMSelect` (Nos, Kgs, Liters, SqMtr, Sets)
     - `DamageSeveritySelect` (*Total Loss / Severe Burn / Water Ingress / Moderate / Minor*)
     - `SurveyorRecommendation` (*Repairable / Replace / Salvage Only*)
     - `PreExistingConditionNotes` (Wear & tear, rust, prior maintenance issues)
     - `EstimatedReinstatementCost` (₹)
2. **Watermarked Photo Studio**:
   - `CameraLauncherButton` (Captures image with embedded indelible EXIF metadata: Date, Time, Lat/Lng coordinates, Survey Ref ID, Category Tag).
   - `CategoryTaggingBar`: Required selection for each photo:
     - `Tag1: Panoramic / Overall Site View`
     - `Tag2: Affected Section / Department`
     - `Tag3: Individual Damaged Asset`
     - `Tag4: Nameplate / Serial Number Close-up`
     - `Tag5: Close-up Damage Detail`
     - `Tag6: Cause / Point of Origin Evidence`
   - `PhotoThumbnailGrid`: Displays photos with category badge, timestamp, and caption.
   - `PhotoAnnotationTool`: Surveyor can draw circles/arrows on photos to highlight specific cracks, burns, or watermarks.
3. **Voice-to-Text Field Assistant**:
   - `MicrophoneRecordButton` (With pulsating recording visualizer)
   - `LiveTranscriptBox`
   - `AIStructuredExtractionButton` (Converts speech into structured Item Name, Model, Serial, and Damage Extent).

---

## 4. Data Fields, Types & Validations

| Field | Type | Mandatory | Validation Rules | Description |
| :--- | :--- | :--- | :--- | :--- |
| `head_category` | Enum | Yes | Standard asset heads | Broad classification of damaged asset |
| `item_description` | String | Yes | Min 3 chars | Name and specifications of item |
| `make_model` | String | No | Alphanumeric | Manufacturer, model, capacity |
| `serial_number` | String | Conditional | Mandatory for Machinery/Electronics | Equipment serial / asset ID |
| `quantity` | Float | Yes | $> 0$ | Count or measurement |
| `uom` | Enum | Yes | Nos, Kgs, Ltrs, Meters, SqFt, etc. | Unit of measurement |
| `damage_severity` | Enum | Yes | Total Loss, Severe, Moderate, Minor | Degree of physical damage |
| `recommendation` | Enum | Yes | Repairable, Replace, Salvage | Recommended loss handling |
| `photo_attachments` | Array<Photo> | Yes | At least 1 photo per damaged item | Supporting visual evidence |

---

## 5. AI Assistant Integration & Triggers
- **Voice-to-Damage-Item Parser (AI-1)**:
  - Input: Surveyor speaks *"Item number three is a L&T switchgear panel rated 415 volts, completely incinerated due to busbar flashover. Serial number LNT-9921. Total loss, cannot be repaired."*
  - Output: Auto-populates `Category: Electrical`, `Description: L&T Switchgear Panel 415V`, `Serial: LNT-9921`, `Damage: Total Loss`, `Recommendation: Replace`, `Remarks: Busbar flashover`.
- **Serial Plate OCR**: OCR automatically detects serial numbers and model text directly from close-up nameplate photos and populates the item fields.
- **Physical Findings Drafter (AI-4)**: Compiles all item records into an executive summary narrative for FSR Section D (*Physical Survey Findings*).

---

## 6. Offline State & Sync Indicators
- Critical offline capability: Full camera capture, local compression (JPEG 1600x1200), voice recording, and item indexing operate 100% offline.
- Photos and audio files are stored in local encrypted app sandbox (`/media_cache/`) and queued for cloud synchronization.

---

## 7. Action Triggers & Navigation
- **Click "Save & Proceed to Ownership Verification"**: Validates item list and photo attachments, advancing to Stage 7 (`08_ownership_document_locker`).
- **Click "Export Damage Inventory"**: Exports a structured Excel / CSV / Docx inventory for on-site discussion with the insured.
