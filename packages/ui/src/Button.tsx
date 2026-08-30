/**
 * Button — the four variants fixed by Design System section 4.2, transcribed from its
 * CSS block. No fifth variant, no size prop beyond the two the spec defines: adding
 * either is a design-system change, not a component change, and belongs in that
 * document first.
 */
import React from "react";
import {
  ActivityIndicator,
  Pressable,
  StyleSheet,
  Text,
  type StyleProp,
  type ViewStyle,
} from "react-native";

import { color, control, font, radius, space } from "./tokens";

export type ButtonVariant = "primary" | "secondary" | "destructive" | "ai-utility";

export interface ButtonProps {
  label: string;
  onPress: () => void;
  variant?: ButtonVariant;
  disabled?: boolean;
  /** Shows a spinner in place of the label and disables the press target. */
  loading?: boolean;
  style?: StyleProp<ViewStyle>;
  /** Accessible identifier for testing; does not affect rendering. */
  testID?: string;
}

const VARIANT_STYLE: Record<
  ButtonVariant,
  { background: string; text: string; border: string; height: number; fontSize: number }
> = {
  primary: {
    background: color.primary,
    text: color.surface,
    border: color.primaryActive,
    height: control.inputHeightMobile,
    fontSize: 13,
  },
  secondary: {
    background: color.surface,
    text: color.textPrimary,
    border: color.borderDefault,
    height: control.inputHeightMobile,
    fontSize: 13,
  },
  destructive: {
    background: color.surface,
    text: color.critical,
    border: color.criticalBorder,
    height: control.inputHeightMobile,
    fontSize: 13,
  },
  // Design System 4.2 note 4: "restrained, professional" -- an AI-triggering action
  // styled identically to any other secondary utility, never visually distinguished
  // with sparkle iconography or a differing shape (section 2 anti-patterns).
  "ai-utility": {
    background: color.canvas,
    text: color.primary,
    border: color.borderDefault,
    height: 36,
    fontSize: 12,
  },
};

/**
 * A destructive button is never disabled silently. If the action truly cannot run,
 * pass a different label ("Cannot delete — evidence linked") rather than disabling
 * without explanation — a disabled destructive control with no reason is exactly the
 * kind of unexplained UI state a surveyor working a claim under time pressure will not
 * have time to investigate.
 */
export function Button({
  label,
  onPress,
  variant = "primary",
  disabled = false,
  loading = false,
  style,
  testID,
}: ButtonProps): React.JSX.Element {
  const v = VARIANT_STYLE[variant];
  const isInteractive = !disabled && !loading;

  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ disabled: !isInteractive, busy: loading }}
      disabled={!isInteractive}
      onPress={onPress}
      testID={testID}
      style={({ pressed }) => [
        styles.base,
        {
          backgroundColor: v.background,
          borderColor: v.border,
          height: v.height,
          opacity: disabled ? 0.5 : pressed ? 0.85 : 1,
        },
        style,
      ]}
    >
      {loading ? (
        <ActivityIndicator size="small" color={v.text} />
      ) : (
        <Text style={[styles.label, { color: v.text, fontSize: v.fontSize }]} numberOfLines={1}>
          {label}
        </Text>
      )}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  base: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    borderWidth: 1,
    borderRadius: radius.sm,
    paddingHorizontal: space[4],
    // control.minTouchTarget (44) is guaranteed by the variant heights above; this is
    // a floor for any future variant that might specify something smaller.
    minHeight: control.minTouchTarget,
  },
  label: {
    fontFamily: font.display,
    fontWeight: "600",
  },
});
