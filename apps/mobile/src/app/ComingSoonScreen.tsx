/**
 * "Coming Soon" screen used as placeholder for all tabs.
 *
 * A polished, brand-consistent screen that tells the user which feature is
 * in development and when they can expect it. Uses the SurvScribe logo and
 * the design-system color palette.
 */
import React, { useEffect, useRef } from "react";
import { Animated, Dimensions, Image, StyleSheet, Text, View } from "react-native";
import { color, font, space } from "@survscribe/ui";

const { width } = Dimensions.get("window");

interface Props {
  /** Name of the feature / tab. */
  title: string;
  /** Short description of what the feature will do. */
  description?: string;
}

export function ComingSoonScreen({ title, description }: Props): React.JSX.Element {
  const fadeAnim = useRef(new Animated.Value(0)).current;
  const slideAnim = useRef(new Animated.Value(20)).current;

  useEffect(() => {
    Animated.parallel([
      Animated.timing(fadeAnim, {
        toValue: 1,
        duration: 500,
        useNativeDriver: false,
      }),
      Animated.timing(slideAnim, {
        toValue: 0,
        duration: 500,
        useNativeDriver: false,
      }),
    ]).start();
  }, [fadeAnim, slideAnim]);

  return (
    <View style={styles.container}>
      {/* Decorative top stripe */}
      <View style={styles.topStripe} />

      <Animated.View
        style={[
          styles.content,
          {
            opacity: fadeAnim,
            transform: [{ translateY: slideAnim }],
          },
        ]}
      >
        {/* Logo */}
        <View style={styles.logoContainer}>
          <Image
            source={require("../../assets/logo.png")}
            style={styles.logo}
            resizeMode="contain"
          />
        </View>

        {/* Badge */}
        <View style={styles.badge}>
          <Text style={styles.badgeText}>COMING SOON</Text>
        </View>

        {/* Feature title */}
        <Text style={styles.title}>{title}</Text>

        {/* Description */}
        {description ? <Text style={styles.description}>{description}</Text> : null}

        {/* Separator */}
        <View style={styles.separator} />

        {/* Info text */}
        <Text style={styles.infoText}>
          We're building something great. This feature is currently under active development and
          will be available in an upcoming release.
        </Text>

        {/* Feature pills */}
        <View style={styles.pillRow}>
          <View style={styles.pill}>
            <Text style={styles.pillDot}>●</Text>
            <Text style={styles.pillText}>Offline First</Text>
          </View>
          <View style={styles.pill}>
            <Text style={styles.pillDot}>●</Text>
            <Text style={styles.pillText}>AI Assisted</Text>
          </View>
          <View style={styles.pill}>
            <Text style={styles.pillDot}>●</Text>
            <Text style={styles.pillText}>Enterprise</Text>
          </View>
        </View>
      </Animated.View>

      {/* Bottom branding */}
      <View style={styles.bottomBranding}>
        <Text style={styles.brandText}>SurvScribe</Text>
        <Text style={styles.versionText}>v1.0.0 • Preview</Text>
      </View>
    </View>
  );
}

const LOGO_SIZE = width * 0.18;

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: color.canvas,
    alignItems: "center",
  },
  topStripe: {
    width: "100%",
    height: 3,
    backgroundColor: color.primary,
  },
  content: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: space[6],
  },
  logoContainer: {
    width: LOGO_SIZE + 24,
    height: LOGO_SIZE + 24,
    borderRadius: (LOGO_SIZE + 24) * 0.2,
    backgroundColor: color.primarySubtle,
    alignItems: "center",
    justifyContent: "center",
    marginBottom: space[5],
  },
  logo: {
    width: LOGO_SIZE,
    height: LOGO_SIZE,
  },
  badge: {
    backgroundColor: color.primary,
    paddingHorizontal: 16,
    paddingVertical: 6,
    borderRadius: 20,
    marginBottom: space[4],
  },
  badgeText: {
    fontFamily: font.display,
    fontSize: 11,
    fontWeight: "700",
    color: color.surface,
    letterSpacing: 2,
  },
  title: {
    fontFamily: font.display,
    fontSize: 24,
    fontWeight: "700",
    color: color.textPrimary,
    textAlign: "center",
    marginBottom: space[2],
  },
  description: {
    fontFamily: font.body,
    fontSize: 14,
    lineHeight: 20,
    color: color.textSecondary,
    textAlign: "center",
    maxWidth: 300,
  },
  separator: {
    width: 40,
    height: 2,
    backgroundColor: color.borderDefault,
    marginVertical: space[5],
    borderRadius: 1,
  },
  infoText: {
    fontFamily: font.body,
    fontSize: 13,
    lineHeight: 20,
    color: color.textMuted,
    textAlign: "center",
    maxWidth: 280,
    marginBottom: space[5],
  },
  pillRow: {
    flexDirection: "row",
    gap: 12,
  },
  pill: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: color.surface,
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: color.borderSubtle,
    gap: 6,
  },
  pillDot: {
    fontSize: 6,
    color: color.primary,
  },
  pillText: {
    fontFamily: font.body,
    fontSize: 11,
    color: color.textSecondary,
    fontWeight: "500",
  },
  bottomBranding: {
    paddingBottom: 32,
    alignItems: "center",
  },
  brandText: {
    fontFamily: font.display,
    fontSize: 14,
    fontWeight: "600",
    color: color.primary,
    letterSpacing: 0.5,
  },
  versionText: {
    fontFamily: font.body,
    fontSize: 11,
    color: color.textMuted,
    marginTop: 2,
  },
});
