# Screen Specification: 00_auth_signup

## 1. Screen Objective & Context
- **Screen Name**: Surveyor Registration & Profile Setup
- **Stage Mapping**: Security & Onboarding Gateway (Screen 00-B)
- **Purpose**: Facilitates new user onboarding for licensed Insurance Surveyors and Loss Assessors (SLA). Captures personal details, surveyor firm information, IRDAI / SLA license credentials, and creates secure account credentials.
- **Inter-Screen Navigation**: Seamlessly switchable with `00_auth_login` via "Already have an account? Sign In" link.

---

## 2. Layout & UI Architecture

### 2.1 Primary Mobile App View (iOS & Android) - Core Mobile Experience
- **Stepped Mobile Registration Flow**:
  - **Top Progress Indicator**: Visual 2-step registration progress bar (*Step 1: Surveyor Details $\rightarrow$ Step 2: SLA Credentials & Security*).
  - **Step 1: Personal & Firm Particulars**:
    - Full Legal Name of Surveyor (Matches SLA license).
    - Surveyor Firm / Sole Proprietorship Name.
    - Mobile Phone Number (with OTP verification button).
    - Official Email Address.
  - **Step 2: Professional SLA Credentials & Password**:
    - SLA / IRDAI License Number input (e.g., `SLA-10294`) with helper text: *"Syntax format validation only"*.
    - SLA Category Picker (*Fellow / Associate / Licentiate / Trainee*).
    - Operating Territory / Base City (e.g., *Mumbai / Delhi / Bengaluru*).
    - Password creation field with visual strength meter (Weak/Medium/Strong).
    - Confirm Password field with real-time match check.
    - Terms of Service & Privacy Policy acceptance checkbox.
    - **Regulatory Disclaimer Notice Box**:
      > *"License details are provided by the user and are subject to independent verification. Platform registration does not constitute regulatory approval or endorsement."*
    - **License fields are optional at signup.** If left blank, registration still completes. A non-blocking reminder is shown, and the surveyor will be **prompted for License Number + Category before Final Survey Report (FSR) generation is allowed** (they populate the report sign-off block).
  - **Primary Action Button**: Full-width **"Complete Registration & Enter Workspace"** CTA.
  - **Bottom Switcher Bar**: *"Already have an account? **Sign In here**"* (routes to `00_auth_login`).

### 2.2 Responsive Desktop Web View
- **Split-Screen Desktop Layout**:
  - **Left Hero Panel (45% width)**: Deep blue gradient branding showcase highlighting key platform benefits: Instant PDF report compilation, AI narrative generation, offline photo studio, and loss quantification engine.
  - **Right Registration Card (55% width)**: Comprehensive two-column onboarding form capturing personal, firm, and SLA license data with live format validation and prominent regulatory disclaimer block.

---

## 3. Detailed UI Component Hierarchy
1. **Branding & Header**:
   - `AppLogoBrand`
   - `OnboardingTitle` ("Register as Licensed Surveyor")
   - `StepProgressBar` (Step 1 of 2 / Step 2 of 2)
2. **Step 1 Components: Surveyor Basics**:
   - `FullNameInput`
   - `FirmNameInput`
   - `MobileNumberInput`
   - `EmailAddressInput`
   - `ProceedToStep2Button`
3. **Step 2 Components: SLA Credentials & Security**:
   - `SLALicenseNumberInput` (With syntax format validator: regex `SLA-[0-9]{4,8}`)
   - `SLACategorySelect` (*Fellow*, *Associate*, *Licentiate*, *Trainee*)
   - `BaseLocationInput`
   - `RegulatoryDisclaimerCard` (Mandatory disclaimer text)
   - `CreatePasswordInput` (With show/hide eye toggle & complexity validator)
   - `ConfirmPasswordInput`
   - `TermsConsentCheckbox`
   - `CompleteSignUpButton`
4. **Footer Switcher**:
   - `NavigateToSignInLink` (Opens `00_auth_login`)

---

## 4. Data Fields, Types & Validations

| Field | Type | Mandatory | Validation Rules | Description |
| :--- | :--- | :--- | :--- | :--- |
| `full_name` | String | Yes | Min 3 chars, alphabetic | Surveyor legal name |
| `firm_name` | String | Yes | Min 2 chars | Survey firm / company name |
| `mobile_number` | String | Yes | 10 digits (+91) | Primary contact number |
| `email` | String | Yes | Valid email address | Account email & notifications |
| `sla_license_no` | String | No | Format: `SLA-[0-9]{4,8}` or alphanumeric | Surveyor license number (Optional) |
| `sla_category` | Enum | No | Fellow / Associate / Licentiate / Trainee | License qualification level (Optional) |
| `base_location` | String | No | e.g., Mumbai, Maharashtra | Operating Territory (Optional) |
| `password` | Password | Yes | Min 8 chars, 1 uppercase, 1 number, 1 special char | Account password |
| `terms_accepted` | Boolean | Yes | Must be `true` | Agreement to terms |

---

## 5. Security & RBAC Metadata Initialization

*(Amended 2026-08-30 by ADR-0005 — see `documentation/architecture/identity-and-rbac.md` §4.1.)*

- **Store Initialization**: Registration **always creates a new store** (the surveyor firm / parent company) and makes the registrant its `owner_user_id`. A firm name matching an existing store is **never** joined automatically — firm names are neither unique nor verified, so auto-joining would let anyone who can spell a firm's name reach its claim files. Adding a colleague to an existing store is invite-only (`00_auth_invite_accept`, ADR-0005 D40).
- **Role Assignment**: Assigns role scope `access_role_scope: 'SURVEYOR'` — the registrant's professional role, which appears on reports — **and** grants the `ADMIN` role in `user_roles`, which is what lets the founder invite colleagues. Multi-role assignment is what makes both true at once.
- **Signup Provenance**: Records the originating IP address, user agent, device identifier and platform, plus best-effort geo-IP enrichment (country, region, city, ASN, ISP, timezone). A geo lookup failure records NULL and never blocks registration.
- **Session Provisioning**: Creates a session bound to this device, storing the access and refresh tokens in the hardware keystore/keychain for immediate offline survey preparation.
- **Username**: The login screen accepts an alphanumeric username as a `login_identifier`, but **this form does not capture one**. `username` is therefore `NULL` at registration and set later from the Profile screen. *(Open item — the alternative is an optional username input in Step 2; see ADR-0005 open item 1 / sprints Q14.)*

---

## 6. Action Triggers & Navigation
- **Click "Complete Registration"**: Creates user account, logs user in, and navigates to `01_dashboard` with a welcome tour toast.
- **Click "Sign In here"**: Navigates back to `00_auth_login`.
