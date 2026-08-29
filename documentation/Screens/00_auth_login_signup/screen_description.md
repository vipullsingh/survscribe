# Screen Specification: 00_auth_login_signup

## 1. Screen Objective & Context
- **Screen Name**: Authentication, Registration & Mobile Biometric Access
- **Stage Mapping**: Pre-Workflow / Security Gateway (Screen 00)
- **Purpose**: Provides secure, frictionless entry into the SurveyAssist mobile application. Supports Surveyor Sign In (Email/Password, Mobile Phone + OTP, and FaceID / Fingerprint Biometrics), New Surveyor Registration (Firm Name, Surveyor Name, SLA License Number, Mobile, Email), Password Recovery, and Offline Session Authentication.

---

## 2. Layout & UI Architecture

### 2.1 Primary Mobile App View (iOS & Android) - Core Mobile Experience
- **Sleek Mobile Auth Experience**:
  - **Top Branding Banner**: Animated SurveyAssist logo, tagline (*"Intelligent Claim Surveying & Loss Assessment"*), and Offline/Online connectivity status badge.
  - **Segmented Auth Toggle**: Two-tab top switcher: `[ Sign In ]` | `[ Create Account ]`.
  - **Sign In Tab**:
    - Mode Switcher: *Password Login* vs. *Mobile OTP Login*.
    - Phone Number / Email input with country code picker (`+91` default).
    - Secure Password input with visibility toggle eye icon.
    - "Remember Me on this Device" toggle.
    - "Forgot Password?" link.
    - Prominent Primary CTA: **"Sign In to Workspace"**.
    - **Biometric Unlock Button**: One-tap FaceID / TouchID biometric prompt for cached offline access.
  - **Create Account (Sign Up) Tab**:
    - Stepped Registration Form:
      1. *Personal & Contact Info* (Full Legal Name, Email, Mobile).
      2. *Professional Credentials* (Surveyor Firm Name, IRDAI / SLA License No., Category: Fellow/Associate/Licentiate).
      3. *Security Setup* (Create Password, Confirm Password, Accept Terms of Service).
    - Primary CTA: **"Create Surveyor Account"**.
  - **OTP Verification Bottom Sheet Modal**: 6-digit auto-advancing OTP input with 30-second countdown timer and "Resend Code" link.
  - **Offline Login Banner**: When cellular signal is lost, the screen automatically enables *Offline Biometric Mode* using on-device encrypted keys.

### 2.2 Responsive Desktop Web View
- **Split-Screen Desktop Auth View**:
  - **Left Hero Pane (50% width)**: Deep blue gradient branding showcase highlighting key SurveyAssist capabilities (Offline-first capture, Zero-hallucination AI report generator, 15-stage workflow, and `.docx` export).
  - **Right Auth Pane (50% width)**: Centered authentication card with tabbed Sign In / Sign Up forms, OTP verification dialogs, and enterprise single sign-on (SSO) placeholder.

---

## 3. Detailed UI Component Hierarchy
1. **Branding & Header**:
   - `AppLogoBrand`
   - `AppTagline`
   - `NetworkStatusBadge` (Green: Cloud Connected / Amber: Offline Mode Ready)
2. **Tab Selector**:
   - `AuthSegmentedControl` (*Sign In* / *Sign Up*)
3. **Sign In Component Group**:
   - `AuthModeTabs` (*Email & Password* / *Mobile OTP*)
   - `EmailOrPhoneInput` (With format auto-detection)
   - `PasswordInputField` (With eye toggle)
   - `RememberDeviceCheckbox`
   - `ForgotPasswordLink`
   - `SignInButton`
   - `BiometricAuthButton` (FaceID / Fingerprint icon with "Unlock with Biometrics")
4. **Sign Up (Registration) Component Group**:
   - `SurveyorFullNameInput`
   - `SurveyorFirmNameInput`
   - `SLALicenseNumberInput` (e.g., `SLA-XXXXX`)
   - `SLACategorySelect` (*Fellow*, *Associate*, *Licentiate*)
   - `MobileNumberInput`
   - `EmailAddressInput`
   - `CreatePasswordInput` (With password strength meter)
   - `TermsAndPrivacyCheckbox`
   - `SignUpSubmitButton`
5. **OTP Verification Modal (Bottom Sheet on Mobile)**:
   - `OTPCodeInputBox` (6 individual auto-focus digit boxes)
   - `OTPTimer` (30-second resend countdown)
   - `ResendOTPButton`
   - `VerifyOTPButton`
6. **Forgot Password Modal**:
   - `RecoveryEmailOrPhoneInput`
   - `SendResetLinkButton`
   - `BackToLoginButton`

---

## 4. Data Fields, Types & Validations

| Field | Type | Mandatory | Validation Rules | Description |
| :--- | :--- | :--- | :--- | :--- |
| `auth_identifier` | String | Yes | Valid email format OR 10-digit mobile (+91) | Login username |
| `password` | Password | Conditional | Min 8 chars, 1 uppercase, 1 number, 1 special char | Account password |
| `otp_code` | String | Conditional | Exactly 6 numeric digits | One-time SMS/Email token |
| `full_name` | String | Yes (Sign Up) | Min 3 chars, alphabetic | Surveyor legal name |
| `firm_name` | String | Yes (Sign Up) | Min 2 chars | Survey firm / Company name |
| `sla_license_no` | String | Yes (Sign Up) | Format: `SLA-[0-9]{4,8}` or alphanumeric | Surveyor license number |
| `sla_category` | Enum | Yes (Sign Up) | Fellow / Associate / Licentiate / Trainee | License grade |
| `terms_accepted` | Boolean | Yes (Sign Up) | Must be `true` | Legal terms consent |

---

## 5. Security, Offline Authentication & Session Rules
- **On-Device Encrypted Session Token**: Once signed in online, an encrypted session token is stored in the device’s secure hardware keychain (iOS Keychain / Android Keystore).
- **Offline Biometric Unlock**: If the surveyor opens the app in a basement or remote site with zero cellular network, they can authenticate locally using FaceID / Fingerprint / PIN to access all cached surveys and continue field work.
- **Auto-Lock Timeout**: App automatically locks after 15 minutes of inactivity in the background; unlocks instantly with biometrics.

---

## 6. AI & Smart Assistant Integration
- **SLA License Auto-Verification**: AI parses the entered SLA license format and suggests standard categories and profile templates.
- **Smart Autofill**: Remembers last-used firm name, surveyor ID, and device credentials for rapid single-tap sign-in.

---

## 7. Action Triggers & Navigation
- **Successful Sign In / Sign Up / Biometric Unlock**: Directs user to `01_dashboard`.
- **Click "Forgot Password"**: Opens password recovery workflow.
- **Click "Create Account"**: Switches view to registration form.
