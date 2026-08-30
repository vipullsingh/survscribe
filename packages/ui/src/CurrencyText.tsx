/**
 * CurrencyText — the rupee display fixed by Design System sections 3.1 and 3.2:
 * a neutral ₹ prefix chip, tabular monospace figures, right-aligned, Indian
 * lakh/crore grouping. Financial and Financial Total map to the two type-scale rows.
 */
import React from "react";
import { StyleSheet, Text, View } from "react-native";

import { color, formatInr, typeScale, type Decimal } from "./tokens";

export interface CurrencyTextProps {
  /**
   * A decimal string, e.g. "497500.00" — never a JS number. `NUMERIC(15,2)` does not
   * survive a round trip through an IEEE-754 double, and this component only ever
   * displays a value that has already been computed by the deterministic engine or
   * read verbatim from `@survscribe/types`, where every rupee field is typed as a
   * decimal string for exactly this reason.
   */
  amount: Decimal;
  /** Financial (line-item rows) or FinancialTotal (subtotals, Net Recommended). */
  variant?: "financial" | "total";
  /** Negative amounts (a deduction, a debit) render in the critical colour. */
  negativeIsCritical?: boolean;
}

export function CurrencyText({
  amount,
  variant = "financial",
  negativeIsCritical = false,
}: CurrencyTextProps): React.JSX.Element {
  const scale = variant === "total" ? typeScale.financialTotal : typeScale.financial;
  const isNegative = amount.trimStart().startsWith("-");

  return (
    <View style={styles.row}>
      <Text
        style={[
          styles.text,
          {
            fontFamily: scale.family,
            fontSize: scale.size,
            lineHeight: scale.lineHeight,
            fontWeight: scale.weight,
            color: isNegative && negativeIsCritical ? color.critical : color.textPrimary,
          },
        ]}
        // "tnum"/"zero" tabular-figure OpenType features (Design System 3.2). React
        // Native does not expose font-feature-settings directly; JetBrains Mono is
        // itself a fixed-width face, so digits already align without this hint on
        // every platform that renders the font at all. Noted, not silently assumed.
        accessibilityRole="text"
        accessibilityLabel={`Amount ${amount}`}
      >
        {formatInr(amount)}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    alignItems: "flex-end",
  },
  text: {
    textAlign: "right",
  },
});
