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
- **Role Assignment**: Automatically assigns default role scope `role: 'SURVEYOR'`.
- **Tenant Initialization**: If a new firm name is entered, initializes a new `tenant_id` for multi-surveyor firm readiness.
- **Session Provisioning**: Creates an encrypted session token in local device storage for immediate offline survey preparation.

---

## 6. Action Triggers & Navigation
- **Click "Complete Registration"**: Creates user account, logs user in, and navigates to `01_dashboard` with a welcome tour toast.
- **Click "Sign In here"**: Navigates back to `00_auth_login`.
