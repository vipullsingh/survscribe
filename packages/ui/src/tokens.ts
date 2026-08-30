/**
 * SurvScribe design tokens.
 *
 * Transcribed from `documentation/Visual Theme & Design System.md` v2.0.0-Enterprise.
 * That document is the authority; this file is its machine-readable form. When the two
 * disagree, the document wins and this file is wrong.
 *
 * The design system's anti-pattern list (section 2) is an acceptance gate, not advice:
 * no gradients or glow, no neon, no radius above 20px, no floating widgets or chatbots,
 * no glassmorphism, no "sparkle" AI iconography, no gamified steppers.
 */

/** Canonical primary blue (D30). The logo SVGs keep `#1E40AF` as a brand-mark shade. */
export const color = {
  primary: "#1E3A8A",
  primaryHover: "#1E40AF",
  primaryActive: "#172554",
  primarySubtle: "#EFF6FF",

  canvas: "#F8FAFC",
  surface: "#FFFFFF",

  textPrimary: "#0F172A",
  textSecondary: "#475569",
  textMuted: "#94A3B8",

  borderSubtle: "#E2E8F0",
  borderDefault: "#CBD5E1",
  borderStrong: "#94A3B8",

  /**
   * Status colours are strict (design system section 12.3): green means verified, amber
   * means warning, red means a critical blocker. They carry no other meaning, and nothing
   * else may borrow them for emphasis.
   */
  success: "#059669",
  successBg: "#F0FDF4",
  successBorder: "#BBF7D0",

  warning: "#D97706",
  warningBg: "#FFFBEB",
  warningBorder: "#FDE68A",

  critical: "#DC2626",
  criticalBg: "#FEF2F2",
  criticalBorder: "#FECACA",

  link: "#2563EB",
} as const;

/** Discrepancy audit box (design system section 5). */
export const auditBox = {
  background: color.warningBg,
  border: color.warningBorder,
  text: "#92400E",
} as const;

/** Watermark banner burnt into evidence photos (FR-6.2). */
export const watermark = {
  background: "rgba(15, 23, 42, 0.85)",
  text: "#FFFFFF",
} as const;

export const font = {
  /** Headings and labels. */
  display: "Plus Jakarta Sans",
  /** Body copy. */
  body: "Inter",
  /**
   * Every financial figure, policy number, GPS coordinate and serial number. Monospace
   * is not decoration here: a rupee column that does not align is a column a surveyor
   * cannot check by eye.
   */
  mono: "JetBrains Mono",
} as const;

/**
 * Typography scale (design system section 3.2). Each entry is
 * `[fontFamily, fontSize, lineHeight, fontWeight]`, matching the spec table exactly —
 * transcribed, not approximated.
 */
export const typeScale = {
  pageTitle: { family: font.display, size: 20, lineHeight: 28, weight: "700" },
  sectionHeader: { family: font.display, size: 16, lineHeight: 24, weight: "700" },
  cardTitle: { family: font.display, size: 14, lineHeight: 20, weight: "600" },
  fieldLabel: { family: font.display, size: 12, lineHeight: 16, weight: "600" },
  body: { family: font.body, size: 13, lineHeight: 18, weight: "400" },
  bodySmall: { family: font.body, size: 11, lineHeight: 16, weight: "400" },
  badge: { family: font.body, size: 11, lineHeight: 14, weight: "600" },
  financial: { family: font.mono, size: 13, lineHeight: 18, weight: "500" },
  financialTotal: { family: font.mono, size: 15, lineHeight: 20, weight: "700" },
  forensicMono: { family: font.mono, size: 11, lineHeight: 14, weight: "400" },
} as const;

/** 8pt grid with a 4pt sub-unit. */
export const space = {
  1: 4,
  2: 8,
  3: 12,
  4: 16,
  5: 20,
  6: 24,
  7: 32,
  8: 40,
} as const;

export const radius = {
  xs: 4,
  sm: 6,
  md: 8,
  lg: 12,
} as const;

/** Icon sizes. Lucide / Heroicons outline, 1.5px stroke, no filled variants. */
export const iconSize = {
  sm: 16,
  md: 20,
  lg: 24,
} as const;

export const control = {
  /** Touch targets are never below 44pt on mobile (design system section 6.1). */
  inputHeightMobile: 44,
  inputHeightDesktop: 38,
  minTouchTarget: 44,
  focusRingWidth: 3,
  focusBorderWidth: 1.5,
} as const;

/** Canonical 5-tab bottom navigation (design system section 6.1, reconciled with 01_dashboard.md). */
export const BOTTOM_NAV = ["Dashboard", "Claims", "Field Studio", "Reports", "Profile"] as const;

/** The 15 workflow stages, in order. Screen folder NN maps to stage NN-1 for screens 02-16. */
export const STAGES = [
  "Appointment & Claim Intake",
  "Policy & Coverage Review",
  "Insured Contact & Schedule",
  "Risk Location Verification",
  "Cause Investigation",
  "Damage Inspection Studio",
  "Ownership & Document Locker",
  "Preliminary Survey Report",
  "Follow-up Investigation",
  "Document Verification & Audit",
  "Loss Assessment & Quantification",
  "Salvage & Disposal Manager",
  "Coverage & Liability Opinion",
  "Final Survey Report",
  "Internal Review & Submission",
] as const;

/** Stage tracker marks (design system section 12.4). */
export const stageMark = {
  completed: { glyph: "✓", color: color.success },
  active: { glyph: "●", color: color.primary },
  upcoming: { glyph: "○", color: color.textMuted },
} as const;

/**
 * A rupee amount as it crosses every boundary in this codebase: a decimal string, never
 * a JS number. Mirrors `Decimal` in `@survscribe/types` — defined again here rather than
 * imported so `packages/ui` does not need a dependency on `@survscribe/types` for one
 * type alias. Keep the two in sync if either changes.
 */
export type Decimal = string;

/**
 * Format a rupee amount for display: Indian lakh/crore digit grouping, two decimals,
 * always rendered in `font.mono` and right-aligned.
 *
 * Takes a decimal STRING, never a number. `NUMERIC(15,2)` does not survive a round trip
 * through an IEEE-754 double, and FR-15.1 gate 1 requires Section F to reconcile to the
 * rupee. Parsing to a float to format it would defeat that at the last step.
 */
export function formatInr(amount: Decimal): string {
  const negative = amount.trimStart().startsWith("-");
  const [rawInt = "0", rawFrac = ""] = amount.replace(/^-/, "").split(".");
  const paise = (rawFrac + "00").slice(0, 2);

  // Indian grouping: last three digits, then pairs.
  const last3 = rawInt.slice(-3);
  const rest = rawInt.slice(0, -3);
  const grouped = rest ? rest.replace(/\B(?=(\d{2})+(?!\d))/g, ",") + "," + last3 : last3;

  return `${negative ? "-" : ""}₹${grouped}.${paise}`;
}
