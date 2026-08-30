/**
 * KernelSampleScreen — sprint_0002 task 4's "sample screen" deliverable.
 *
 * Exercises all three design-kernel components together against a realistic worked
 * example (the physical-schema.md section 30.2 loss-quantification figures) so the
 * tokens can be verified rendering correctly end to end, not just in isolation.
 *
 * This is NOT part of the app's navigation (apps/mobile/src/app/App.tsx keeps its
 * canonical 5-tab structure — CLAUDE.md section 14 constraint 13 is not a tab budget to
 * spend on a dev sample). It exists to be rendered by a test (see
 * __tests__/KernelSampleScreen.test.tsx) and, once Storybook or an equivalent tool is
 * introduced, as its story.
 */
import React from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";

import { Button } from "../Button";
import { TextField } from "../TextField";
import { CurrencyText } from "../CurrencyText";
import { color, space, typeScale } from "../tokens";

export function KernelSampleScreen(): React.JSX.Element {
  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.pageTitle}>Design Kernel Sample</Text>

      <View style={styles.section}>
        <Text style={styles.sectionHeader}>Buttons</Text>
        <Button label="Save & Continue" onPress={() => {}} variant="primary" />
        <Button label="Back" onPress={() => {}} variant="secondary" />
        <Button label="Delete Item" onPress={() => {}} variant="destructive" />
        <Button label="Draft Narrative with Field Notes" onPress={() => {}} variant="ai-utility" />
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionHeader}>Form controls</Text>
        <TextField
          label="Insured Name"
          value="Rajesh Textiles Pvt Ltd"
          onChangeText={() => {}}
          required
        />
        <TextField
          label="Policy Number"
          value=""
          onChangeText={() => {}}
          error="Must be at least 6 alphanumeric characters"
        />
        <TextField label="GPS Latitude" value="23.033863" onChangeText={() => {}} numericDisplay />
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionHeader}>
          Currency — worked example (physical-schema.md 30.2)
        </Text>
        <CurrencyText amount="1000000.00" />
        <CurrencyText amount="-200000.00" negativeIsCritical />
        <CurrencyText amount="497500.00" variant="total" />
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { backgroundColor: color.canvas },
  content: { padding: space[4] },
  pageTitle: {
    fontFamily: typeScale.pageTitle.family,
    fontSize: typeScale.pageTitle.size,
    lineHeight: typeScale.pageTitle.lineHeight,
    fontWeight: typeScale.pageTitle.weight,
    color: color.textPrimary,
    marginBottom: space[4],
  },
  section: { marginBottom: space[6], gap: space[3] },
  sectionHeader: {
    fontFamily: typeScale.sectionHeader.family,
    fontSize: typeScale.sectionHeader.size,
    lineHeight: typeScale.sectionHeader.lineHeight,
    fontWeight: typeScale.sectionHeader.weight,
    color: color.textPrimary,
    marginBottom: space[2],
  },
});
