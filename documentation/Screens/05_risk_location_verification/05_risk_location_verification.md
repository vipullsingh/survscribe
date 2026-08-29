# Screen Specification: 05_risk_location_verification

## 1. Screen Objective & Context
- **Screen Name**: Risk & Loss Location Verification
- **Stage Mapping**: Stage 4 of 15 (Verification of Risk and Loss Location)
- **Purpose**: Verifies and documents the exact physical site where the loss occurred, confirms geo-coordinates (GPS) via field device, compares physical address against the Policy Schedule risk address, records occupancy and business activities, and flags location discrepancies for insurer review.

---

## 2. Layout & UI Architecture

### 2.1 Primary Mobile App View (iOS & Android) - Core Mobile Experience
- **Mobile Field Geo-Tagging Hub**:
  - Top prominent "Capture GPS Location" one-tap hardware GPS button (captures Lat/Lng with $\pm$ accuracy radius).
  - Native map snippet with current surveyor pin, policy risk pin, and reverse-geocoded address display.
  - Live Location Match Status Card (*Green: Address Matched / Red: Address Discrepancy Detected*).
  - Quick-fill occupancy form and surrounding hazard checklist.
  - Camera button to photograph the factory entrance/premises signboard as location proof.
  - Sticky bottom CTA: "Confirm Location & Proceed to Cause Investigation".

### 2.2 Responsive Desktop Web View
- **Two-Column Verification Layout**:
  - **Left Pane (50% width)**: Policy Risk Address Card vs. Actual Physical Loss Location Card, side-by-side comparison table with automated discrepancy indicator, and interactive Satellite Map.
  - **Right Pane (50% width)**: Occupancy & Operational Profile Form and Location Discrepancy & Material Change Log.

---

## 3. Detailed UI Component Hierarchy
1. **GPS Capture & Geocoding Component**:
   - `GPSCaptureButton` (Triggers device location API)
   - `CoordinateDisplay` (Latitude, Longitude, Accuracy $\pm X$ meters, Altitude, Timestamp)
   - `ReverseGeocodedAddressBox`
2. **Address Comparison Grid**:
   - `PolicyAddressViewer` (Read-only from Stage 2)
   - `ActualLossAddressInput` (Editable physical address)
   - `DistanceVarianceCalculator` (Displays distance in meters/kilometers between policy pin and survey GPS)
   - `DiscrepancyToggle` (*No Discrepancy / Location Mismatch / Uninsured Premises*)
3. **Premises Occupancy & Risk Profile**:
   - `OccupancyCategorySelect` (Industrial Manufacturing, Warehouse / Storage, Commercial Office, Retail Store, Residential)
   - `NatureOfBusinessInput` (Detailed description of active business operations)
   - `PremisesOwnershipSelect` (*Owned by Insured / Leased / Shared Tenancy*)
   - `SurroundingHazardsChecklist` (e.g., Adjacent chemical storage, nearby river/nullah, open timber yard)
4. **Discrepancy Justification Panel** (Conditional):
   - `DiscrepancyReasonTextarea` (Required if `DiscrepancyToggle` is active)
   - `InsurerNotificationDraft` (Pre-drafted notice to insurer regarding risk location variance)

---

## 4. Data Fields, Types & Validations

| Field | Type | Mandatory | Validation Rules | Description |
| :--- | :--- | :--- | :--- | :--- |
| `gps_latitude` | Float | Yes | $-90.0$ to $+90.0$ | GPS Latitude from field device |
| `gps_longitude` | Float | Yes | $-180.0$ to $+180.0$ | GPS Longitude from field device |
| `gps_accuracy_meters`| Float | Yes | $\le 50$ meters | GPS accuracy reading |
| `actual_loss_address`| Text | Yes | Min 15 chars | Physical address of the loss site |
| `location_discrepancy`| Boolean | Yes | Boolean flag | Indicates address mismatch |
| `discrepancy_remarks` | Text | Conditional | Mandatory if `location_discrepancy = true` | Explanation for location mismatch |
| `occupancy_nature` | String | Yes | Min 5 chars | Nature of business at site |

---

## 5. AI Assistant Integration & Triggers
- **Address String Matching (AI-3)**: Performs fuzzy match between policy address string and reverse-geocoded address. Suggests match confidence score (e.g., "94% Match: Minor street name variation" vs. "0% Match: Different Industrial Area").
- **Hazard Risk Analyzer**: Evaluates surrounding hazards and suggests relevant risk observations for the Final Survey Report Section B (Description of Risk).

---

## 6. Offline State & Sync Indicators
- Device native GPS operates fully offline using hardware satellite receivers.
- Coordinates and offline map tiles are cached locally in SQLite.

---

## 7. Action Triggers & Navigation
- **Click "Save & Proceed to Cause Investigation"**: Validates GPS capture and occupancy data, advances to Stage 5 (`06_cause_investigation`).
- **Click "Flag Discrepancy to Insurer"**: Prepares an interim notification regarding location divergence.
