# Screen Specification: 00_auth_login

## 1. Screen Objective & Context
- **Screen Name**: Surveyor Authentication & Login
- **Stage Mapping**: Security & Access Gateway (Screen 00-A)
- **Purpose**: Provides a dedicated, secure, and rapid entry point for registered Claim Surveyors. Supports universal identifier login (**Email Address, Username, or Mobile Phone Number**), Password authentication, one-tap **Login with OTP** (triggering either Phone OTP or Email OTP modal popups), native hardware Biometric Unlock (FaceID / TouchID / Fingerprint), Password Recovery, and Offline Session Access for remote field work.
- **Inter-Screen Navigation**: Seamlessly switchable with `00_auth_signup` via "Don't have an account? Register as Surveyor" link.

---

## 2. Layout & UI Architecture

### 2.1 Primary Mobile App View (iOS & Android) - Core Mobile Experience
- **Sleek Mobile Sign-In Interface**:
  - **Top Branding Section**: Animated SurvScribe logo, app moniker (*"Intelligent Claim Surveying & Loss Assessment"*), and Real-time Connectivity Badge (*Green: Online / Amber: Offline Mode Ready*).
  - **Universal Identifier Input**: Single flexible input field accepting **Email Address**, **Custom Username**, or **Mobile Phone Number** (no SLA license number required for login).
  - **Password Input**: Secure password field with eye show/hide toggle.
  - **Remember Me & Forgot Password**: Checkbox with quick password recovery link.
  - **Primary Action CTA**: Full-width **"Sign In with Password"** button with gradient styling.
  - **Secondary Action: Login with OTP**: Dedicated CTA opening the OTP verification modal sheet (supports Phone SMS OTP and Email OTP).
  - **Biometric Quick Unlock**: One-tap FaceID / TouchID button for $< 1\text{s}$ instant biometric authentication.
  - **Bottom Switcher Bar**: *"Don't have an account? **Register as Surveyor**"* (routes to `00_auth_signup`).
  - **Offline Status Banner**: When cellular signal is unavailable, banner indicates: *"Offline Mode Active — Sign in using Biometrics or device PIN to access cached surveys."*

### 2.2 Dual OTP Verification Modals (Mobile Bottom Sheets)
1. **Modal 1: Verify Phone OTP**:
   - Displays recipient phone number (e.g. `+91 98201 •••••`).
   - 6 individual auto-advancing digit boxes.
   - 30-second live resend countdown timer with "Resend SMS OTP" button.
   - "Verify & Enter Workspace" primary CTA.
   - "Wrong mobile number? Change Phone" deep link.
2. **Modal 2: Verify Email OTP**:
   - Displays recipient work email (e.g. `s••••••@lossadjuster.in`).
   - 6 individual auto-advancing digit boxes with violet focus glow.
   - 45-second live resend countdown timer with "Resend Email OTP" button.
   - "Verify Email & Sign In" primary CTA.
   - "Didn't receive email? Check Spam or Edit" deep link.

---

## 3. Detailed UI Component Hierarchy
1. **Branding & Header**:
   - `AppLogoBrand`
   - `TaglineText`
   - `NetworkStatusBadge` (Online / Offline)
2. **Login Form Components**:
   - `UniversalIdentifierInput` (Accepts Email, Username, or Mobile with auto-detection)
   - `PasswordInput` (With show/hide eye toggle)
   - `RememberMeCheckbox`
   - `ForgotPasswordLink`
   - `PrimaryPasswordSignInButton`
   - `LoginWithOTPButton` (Triggers OTP verification modal)
3. **Biometric Unlock Action**:
   - `BiometricAuthButton` (FaceID / Fingerprint icon with instant OS trigger)
4. **Verify Phone OTP Modal (Bottom Sheet on Mobile)**:
   - `PhoneOTPHeader` (Shows masked mobile number)
   - `OTPDigitBoxes` (6 individual auto-focus boxes)
   - `ResendCountdownTimer` (30s)
   - `ResendPhoneOTPButton`
   - `VerifyPhoneOTPButton`
   - `ChangePhoneNumberLink`
5. **Verify Email OTP Modal (Bottom Sheet on Mobile)**:
   - `EmailOTPHeader` (Shows masked email address)
   - `EmailOTPDigitBoxes` (6 individual auto-focus boxes)
   - `ResendEmailCountdownTimer` (45s)
   - `ResendEmailOTPButton`
   - `VerifyEmailOTPButton`
   - `ChangeEmailLink`
6. **Forgot Password Sheet**:
   - `RecoveryIdentifierInput` (Email / Phone)
   - `SendResetLinkButton`
   - `BackToLoginButton`
7. **Footer Switcher**:
   - `NavigateToSignUpLink` (Opens `00_auth_signup`)

---

## 4. Data Fields, Types & Validations

| Field | Type | Mandatory | Validation Rules | Description |
| :--- | :--- | :--- | :--- | :--- |
| `login_identifier` | String | Yes | Valid email format OR 10-digit mobile (+91) OR alphanumeric username | Surveyor login ID |
| `password` | Password | Conditional | Min 8 chars | Password (if password mode) |
| `phone_otp_code` | String | Conditional | Exactly 6 numeric digits | SMS OTP (if Phone OTP mode) |
| `email_otp_code` | String | Conditional | Exactly 6 numeric digits | Email OTP (if Email OTP mode) |
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
