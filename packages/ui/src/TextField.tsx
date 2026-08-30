/**
 * TextField — the form control fixed by Design System section 4.1: 44px height, a
 * default/focus/read-only border treatment, and an optional helper line beneath.
 */
import React, { useState } from "react";
import { StyleSheet, Text, TextInput, View, type TextInputProps } from "react-native";

import { color, control, font, radius, space } from "./tokens";

export interface TextFieldProps extends Pick<
  TextInputProps,
  | "value"
  | "onChangeText"
  | "onBlur"
  | "onFocus"
  | "placeholder"
  | "keyboardType"
  | "secureTextEntry"
  | "autoCapitalize"
  | "maxLength"
  | "multiline"
  | "testID"
> {
  label: string;
  /** Shown beneath the field. Rendered in the error colour when `error` is set. */
  helperText?: string;
  error?: string;
  required?: boolean;
  readOnly?: boolean;
  /** Renders monospace, right-aligned — for figures, GPS coordinates, serials. */
  numericDisplay?: boolean;
}

export function TextField({
  label,
  helperText,
  error,
  required = false,
  readOnly = false,
  numericDisplay = false,
  value,
  onFocus,
  onBlur,
  ...inputProps
}: TextFieldProps): React.JSX.Element {
  const [focused, setFocused] = useState(false);
  const hasError = Boolean(error);

  return (
    <View style={styles.container}>
      <Text style={styles.label} accessibilityRole="text">
        {label}
        {required ? <Text style={styles.requiredMark}> *</Text> : null}
      </Text>

      <View
        style={[
          styles.inputWrapper,
          focused && !hasError && styles.inputWrapperFocused,
          hasError && styles.inputWrapperError,
          readOnly && styles.inputWrapperReadOnly,
        ]}
      >
        <TextInput
          value={value}
          editable={!readOnly}
          accessibilityLabel={label}
          accessibilityState={{ disabled: readOnly }}
          style={[
            styles.input,
            numericDisplay && styles.inputNumeric,
            readOnly && styles.inputReadOnly,
          ]}
          placeholderTextColor={color.textMuted}
          onFocus={(e) => {
            setFocused(true);
            onFocus?.(e);
          }}
          onBlur={(e) => {
            setFocused(false);
            onBlur?.(e);
          }}
          {...inputProps}
        />
      </View>

      {(helperText || error) && (
        <Text style={hasError ? styles.errorText : styles.helperText}>{error ?? helperText}</Text>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginBottom: space[4],
  },
  label: {
    fontFamily: font.display,
    fontSize: 12,
    fontWeight: "600",
    color: color.textSecondary,
    marginBottom: space[1],
  },
  requiredMark: {
    color: color.critical,
  },
  inputWrapper: {
    height: control.inputHeightMobile,
    borderWidth: 1,
    borderColor: color.borderDefault,
    borderRadius: radius.sm,
    backgroundColor: color.surface,
    paddingHorizontal: space[3],
    justifyContent: "center",
  },
  inputWrapperFocused: {
    borderWidth: control.focusBorderWidth,
    borderColor: color.primary,
    // Design System 4.1: 0 0 0 3px rgba(30, 58, 138, 0.1) focus ring. React Native has
    // no CSS box-shadow-as-ring primitive; a real ring requires a platform-specific
    // overlay (e.g. a shadow view or Reanimated), which is out of scope for the tokens
    // pass. Recorded here rather than silently dropped -- see packages/ui/README.md.
    borderStyle: "solid",
  },
  inputWrapperError: {
    borderWidth: control.focusBorderWidth,
    borderColor: color.critical,
  },
  inputWrapperReadOnly: {
    backgroundColor: color.canvas,
  },
  input: {
    fontFamily: font.body,
    fontSize: 13,
    color: color.textPrimary,
    padding: 0,
  },
  inputNumeric: {
    fontFamily: font.mono,
    textAlign: "right",
  },
  inputReadOnly: {
    color: color.textSecondary,
  },
  helperText: {
    fontFamily: font.body,
    fontSize: 11,
    color: color.textMuted,
    marginTop: space[1],
  },
  errorText: {
    fontFamily: font.body,
    fontSize: 11,
    color: color.critical,
    marginTop: space[1],
  },
});
