/**
 * A named placeholder for a tab whose feature has not been built yet.
 *
 * It states which sprint owns the screen rather than showing "Coming soon", so that
 * anyone opening the app during development can see what is missing and where it comes
 * from. Design system section 7.3 forbids lorem ipsum; this is the same principle
 * applied to an empty state.
 */
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { color, font, space } from "@survscribe/ui";

interface Props {
  title: string;
  detail: string;
}

export function PlaceholderScreen({ title, detail }: Props): React.JSX.Element {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>{title}</Text>
      <Text style={styles.detail}>{detail}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: color.canvas,
    paddingHorizontal: space[6],
  },
  title: {
    fontFamily: font.display,
    fontSize: 20,
    fontWeight: "600",
    color: color.textPrimary,
    marginBottom: space[2],
  },
  detail: {
    fontFamily: font.body,
    fontSize: 14,
    lineHeight: 20,
    color: color.textSecondary,
    textAlign: "center",
  },
});
