# Screen Specification: 00_auth_login

## 1. Screen Objective & Context
- **Screen Name**: Surveyor Authentication & Login
- **Stage Mapping**: Security & Access Gateway (Screen 00-A)
- **Purpose**: Provides a dedicated, secure, and rapid entry point for registered Claim Surveyors. Supports credential login (Email/Password), Mobile Number + 6-digit SMS OTP, native hardware Biometric Unlock (FaceID / TouchID / Fingerprint), Password Recovery, and Offline Session Access for remote field work.
- **Inter-Screen Navigation**: Seamlessly switchable with `00_auth_signup` via "New Surveyor? Create Account" link.

---

## 2. Layout & UI Architecture

### 2.1 Primary Mobile App View (iOS & Android) - Core Mobile Experience
- **Sleek Mobile Sign-In Interface**:
  - **Top Branding Section**: Animated SurveyAssist logo, app moniker (*"Intelligent Claim Surveying & Loss Assessment"*), and Real-time Connectivity Badge (*Green: Online / Amber: Offline Mode Ready*).
  - **Auth Mode Switcher (Pills)**: `[ Email & Password ]` | `[ Mobile OTP ]`.
  - **Email & Password Mode Form**:
    - Floating label input for Registered Email / Username.
    - Secure Password input with eye-icon visibility toggle.
    - "Remember Me on this Device" toggle.
    - "Forgot Password?" recovery link.
  - **Mobile OTP Mode Form**:
    - Mobile Number input with country code picker (`+91` default).
    - "Send Verification Code" CTA.
    - 6-digit auto-advancing OTP input sheet with 30-second resend countdown timer.
  - **Primary Action Button**: Full-width, high-contrast **"Sign In to Workspace"** CTA.
  - **Biometric Quick Unlock**:
    - Dedicated circular button with FaceID / Fingerprint icon: *"Unlock with Biometrics"*.
    - Prompts native OS biometric authentication for instantaneous $< 1\text{s}$ sign-in.
  - **Bottom Switcher Bar**: *"Don't have an account? **Register as Surveyor**"* (routes to `00_auth_signup`).
  - **Offline Status Banner**: When cellular signal is unavailable, banner indicates: *"Offline Mode Active — Sign in using Biometrics or device PIN to access cached surveys."*

### 2.2 Responsive Desktop Web View
- **Split-Screen Desktop Layout**:
  - **Left Showcase Panel (50% width)**: Deep blue gradient branding showcase highlighting key SurveyAssist capabilities (Offline-first capture, Zero-hallucination AI report generator, 15-stage workflow, and `.docx` export).
  - **Right Authentication Card (50% width)**: Centered login card with Email/Password input, Mobile OTP option, Remember Me checkbox, and "Create an Account" link.

---

## 3. Detailed UI Component Hierarchy
1. **Branding & Header**:
   - `AppLogoBrand`
   - `TaglineText`
   - `NetworkStatusBadge` (Online / Offline)
2. **Login Form Components**:
   - `LoginModeTabs` (*Password* vs *Mobile OTP*)
   - `EmailOrPhoneInput` (With format auto-detection)
   - `PasswordInput` (With show/hide toggle)
   - `RememberMeCheckbox`
   - `ForgotPasswordLink`
   - `PrimarySignInButton`
3. **Biometric Unlock Action**:
   - `BiometricAuthButton` (FaceID / Fingerprint icon with instant OS trigger)
4. **OTP Verification Modal (Bottom Sheet on Mobile)**:
   - `OTPDigitBoxes` (6 individual auto-focus boxes)
   - `ResendCountdownTimer` (30s)
   - `ResendOTPButton`
   - `VerifyAndProceedButton`
5. **Forgot Password Sheet**:
   - `RecoveryIdentifierInput` (Email / Phone)
   - `SendResetLinkButton`
   - `BackToLoginButton`
6. **Footer Switcher**:
   - `NavigateToSignUpLink` (Opens `00_auth_signup`)

---

## 4. Data Fields, Types & Validations

| Field | Type | Mandatory | Validation Rules | Description |
| :--- | :--- | :--- | :--- | :--- |
| `auth_identifier` | String | Yes | Valid email format OR 10-digit mobile (+91) | Surveyor login ID |
| `password` | Password | Conditional | Min 8 chars | Password (if password mode) |
| `otp_code` | String | Conditional | Exactly 6 numeric digits | SMS OTP (if OTP mode) |
| `remember_me` | Boolean | No | Defaults to `true` | Persist login session |

---

## 5. Security & Offline Session Rules
- **Encrypted Session Key**: Stored in device hardware secure element (iOS Keychain / Android Keystore).
- **Offline Field Access**: Biometric/PIN unlock allows full access to local SQLite claim data when operating in no-network zones.
- **Auto-Lock Timer**: App locks after 15 minutes of background inactivity; unlocks instantly via biometrics.

---

## 6. Action Triggers & Navigation
- **Click "Sign In" / Biometric Success**: Authenticates user and routes to `01_dashboard`.
- **Click "Register as Surveyor"**: Navigates to `00_auth_signup`.
- **Click "Forgot Password"**: Opens password reset sheet.
