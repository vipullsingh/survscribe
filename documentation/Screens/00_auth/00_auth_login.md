# Screen Specification: 00_auth_login

## 1. Screen Objective & Context
- **Screen Name**: Surveyor Authentication & Login
- **Stage Mapping**: Security & Access Gateway (Screen 00-A)
- **Purpose**: Provides a dedicated, secure, and rapid entry point for registered Claim Surveyors. Supports universal identifier login (**Email Address, Username, or Mobile Phone Number**), Password authentication, one-tap **Login with OTP** (triggering either Phone OTP or Email OTP modal popups), Password Recovery, and Offline Session Access for remote field work.
- **Inter-Screen Navigation**: Seamlessly switchable with `00_auth_signup` via "Don't have an account? Register as Surveyor" link.

---

## 2. Layout & UI Architecture

### 2.1 Primary Mobile App View (iOS & Android) - Core Mobile Experience
- **Refined Enterprise Sign-In Interface**:
  - **Top Branding Section**: Crisp SurvScribe shield/checkmark emblem, product name (*"SurvScribe"*), uppercase domain descriptor (*"INSURANCE SURVEY & LOSS ASSESSMENT"*), and real-time connectivity status pill (*"Secure Workspace"*).
  - **Segmented Auth Switcher**: Clean dual-mode switcher (**Password** | **One-Time OTP**) eliminating duplicate action buttons.
  - **Universal Identifier Input**: Single flexible input field accepting **Email Address**, **Custom Username**, or **Mobile Phone Number**.
  - **Password Input**: Secure password field with eye show/hide toggle.
  - **Remember Device & Forgot Password**: Checkbox with quick password recovery link.
  - **Primary Action CTA**: Confident, solid Deep Cobalt **"Sign In →"** button.
  - **Secondary Registration Link**: Understated text link: *"New to SurvScribe? **Register as a Surveyor**"* (routes to `00_auth_signup`).
  - **Statutory & Regulatory Footnote**: Clear, readable disclaimer defining the platform's non-adjudicating role.

### 2.2 Dual OTP Verification Modals (Mobile Bottom Sheets)
1. **Modal 1: Verify Phone OTP**:
   - Displays recipient phone number (e.g. `+91 98201 •••••`).
   - 6 individual auto-advancing digit boxes.
   - 30-second live resend countdown timer with "Resend SMS OTP" button.
   - "Verify & Open Workspace" primary CTA.
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
   - `SegmentedAuthSwitcher` (Password | One-Time OTP)
   - `UniversalIdentifierInput` (Accepts Email, Username, or Mobile with auto-detection)
   - `PasswordInput` (With show/hide eye toggle)
   - `RememberDeviceCheckbox`
   - `ForgotPasswordLink`
   - `PrimarySignInButton` ("Sign In →")
3. **Verify Phone OTP Modal (Bottom Sheet on Mobile)**:
   - `PhoneOTPHeader` (Shows masked mobile number)
   - `OTPDigitBoxes` (6 individual auto-focus boxes)
   - `ResendCountdownTimer` (30s)
   - `ResendPhoneOTPButton`
   - `VerifyPhoneOTPButton`
   - `ChangePhoneNumberLink`
4. **Verify Email OTP Modal (Bottom Sheet on Mobile)**:
   - `EmailOTPHeader` (Shows masked email address)
   - `EmailOTPDigitBoxes` (6 individual auto-focus boxes)
   - `ResendEmailCountdownTimer` (45s)
   - `ResendEmailOTPButton`
   - `VerifyEmailOTPButton`
   - `ChangeEmailLink`
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
| `login_identifier` | String | Yes | Valid email format OR 10-digit mobile (+91) OR alphanumeric username | Surveyor login ID |
| `password` | Password | Conditional | Min 8 chars | Password (if password mode) |
| `phone_otp_code` | String | Conditional | Exactly 6 numeric digits | SMS OTP (if Phone OTP mode) |
| `email_otp_code` | String | Conditional | Exactly 6 numeric digits | Email OTP (if Email OTP mode) |
| `remember_me` | Boolean | No | Defaults to `true` | Persist login session |

---

## 5. Security & Offline Session Rules
- **Encrypted Session Key**: Stored in device hardware secure element (iOS Keychain / Android Keystore).
- **Offline Field Access**: Encrypted local SQLite session permits full offline claim creation and editing in remote areas.
- **Auto-Lock Timer**: App locks after 15 minutes of background inactivity.

---

## 6. Action Triggers & Navigation
- **Click "Sign In" / OTP Verification**: Authenticates user and routes to `01_dashboard`.
- **Click "Register as Surveyor"**: Navigates to `00_auth_signup`.
- **Click "Forgot Password"**: Opens password reset sheet.

---

## 7. Figma-Importable Vector Screen Files

All screens in this directory are structured as native standalone vector artboards ready for direct drag-and-drop import into Figma:

| Screen / Modal File | Artboard Dimensions | Target Platform | Description |
| :--- | :--- | :--- | :--- |
| **[00_auth_login.svg](designs/00_auth_login.svg)** | `375 × 812` (iOS) | Mobile Primary | Primary Surveyor Sign In screen with Universal Input, Password, and OTP login triggers |
| **[00_auth_login_modal_phone_otp.svg](designs/00_auth_login_modal_phone_otp.svg)** | `375 × 812` (iOS) | Mobile Bottom Sheet | Verify Phone SMS OTP modal with 6-digit auto-advancing PIN boxes and 30s timer |
| **[00_auth_login_modal_email_otp.svg](designs/00_auth_login_modal_email_otp.svg)** | `375 × 812` (iOS) | Mobile Bottom Sheet | Verify Work Email OTP modal with 6-digit encrypted token inputs and 45s timer |
| **[00_auth_login_forgot_password.svg](designs/00_auth_login_forgot_password.svg)** | `375 × 812` (iOS) | Mobile Recovery | Password reset and account recovery workflow |



