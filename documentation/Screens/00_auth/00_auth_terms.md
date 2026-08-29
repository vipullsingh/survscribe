# Screen Specification: 00_auth_terms

## 1. Screen Objective & Context
- **Screen Name**: Terms of Service & Privacy Policy
- **Stage Mapping**: Security & Onboarding Gateway (Screen 00-C)
- **Purpose**: Displays the mandatory legal agreements (Terms of Service, Privacy Policy, and Regulatory Disclaimers) required for licensed Insurance Surveyors to use the SurvScribe platform. It ensures users understand data localization, encryption, and liability boundaries before creating their account.
- **Inter-Screen Navigation**: Accessible as a modal or full-screen view from `00_auth_signup`. Navigates back to `00_auth_signup` upon closing or accepting.

---

## 2. Layout & UI Architecture

### 2.1 Primary Mobile App View (iOS & Android)
- **Document Reading Interface**:
  - **Sticky Header**: Clean top app bar with a "Close" (X) or "Back" icon on the left, and the title **"Terms & Privacy Policy"**.
  - **Scrollable Content Canvas**: A comfortable, highly readable typography layout optimized for long-form legal text.
    - **Header Title**: "SurvScribe Enterprise EULA"
    - **Last Updated Date**: Prominently displayed.
    - **Section 1**: Platform Usage & Liability (Clarifying that SurvScribe is an assistive tool, not the adjudicator of claims).
    - **Section 2**: Data Privacy & Encryption (Detailing local AES-256 caching and secure transmission).
    - **Section 3**: Regulatory Compliance (IRDAI standards, surveyor obligations).
  - **Sticky Bottom Action Bar**: A floating, elevated bar at the bottom containing a primary **"Accept & Continue"** button and a secondary **"Decline"** text link.

---

## 3. Detailed UI Component Hierarchy
1. **HeaderBar**:
   - `CloseIconButton`
   - `ScreenTitle`
2. **ScrollableLegalText**:
   - `DocumentTitle`
   - `LastUpdatedMetadata`
   - `SectionHeading`
   - `LegalParagraph` (Standard body text)
   - `EmphasisBox` (For key clauses like Liability)
3. **StickyFooterAction**:
   - `GradientFade` (To indicate more scrollable content above the footer)
   - `AcceptTermsButton`
   - `DeclineLink`

---

## 4. Visual Language & Polish
- Uses the same unboxed, premium SaaS aesthetic. 
- Legal text must not look like an afterthought—it should use comfortable line height (150%), readable contrast (`#334155`), and clear hierarchical typographic scales.
