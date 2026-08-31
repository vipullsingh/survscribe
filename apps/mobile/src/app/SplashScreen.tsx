/**
 * Animated splash screen shown while the app loads.
 *
 * Displays the SurvScribe logo with a fade-in + scale animation, followed by
 * a smooth crossfade into the main application. The splash plays for a minimum
 * of 2 seconds so the branding is always visible even on fast devices.
 */
import React, { useEffect, useRef } from "react";
import { Animated, Dimensions, Image, StyleSheet, Text, View } from "react-native";
import { color, font } from "@survscribe/ui";

const { width } = Dimensions.get("window");

interface Props {
  /** Called when the splash animation completes and the app should show. */
  onFinish: () => void;
}

export function SplashScreen({ onFinish }: Props): React.JSX.Element {
  const logoScale = useRef(new Animated.Value(0.6)).current;
  const logoOpacity = useRef(new Animated.Value(0)).current;
  const textOpacity = useRef(new Animated.Value(0)).current;
  const containerOpacity = useRef(new Animated.Value(1)).current;

  useEffect(() => {
    // Phase 1: Logo appears with scale + fade
    Animated.parallel([
      Animated.spring(logoScale, {
        toValue: 1,
        friction: 5,
        tension: 60,
        useNativeDriver: false,
      }),
      Animated.timing(logoOpacity, {
        toValue: 1,
        duration: 600,
        useNativeDriver: false,
      }),
    ]).start(() => {
      // Phase 2: Text fades in
      Animated.timing(textOpacity, {
        toValue: 1,
        duration: 400,
        useNativeDriver: false,
      }).start(() => {
        // Phase 3: Hold, then fade out
        setTimeout(() => {
          Animated.timing(containerOpacity, {
            toValue: 0,
            duration: 400,
            useNativeDriver: false,
          }).start(onFinish);
        }, 800);
      });
    });
  }, [logoScale, logoOpacity, textOpacity, containerOpacity, onFinish]);

  return (
    <Animated.View style={[styles.container, { opacity: containerOpacity }]}>
      <Animated.View
        style={[
          styles.logoWrap,
          {
            opacity: logoOpacity,
            transform: [{ scale: logoScale }],
          },
        ]}
      >
        <Image source={require("../../assets/logo.png")} style={styles.logo} resizeMode="contain" />
      </Animated.View>

      <Animated.View style={[styles.textWrap, { opacity: textOpacity }]}>
        <Text style={styles.title}>SurvScribe</Text>
        <Text style={styles.subtitle}>AI-Assisted Insurance Surveying</Text>
      </Animated.View>

      {/* Subtle loading indicator */}
      <Animated.View style={[styles.loadingWrap, { opacity: textOpacity }]}>
        <View style={styles.loadingBar}>
          <LoadingIndicator />
        </View>
      </Animated.View>
    </Animated.View>
  );
}

/** A simple pulsing loading dot row. */
function LoadingIndicator(): React.JSX.Element {
  const dot1 = useRef(new Animated.Value(0.3)).current;
  const dot2 = useRef(new Animated.Value(0.3)).current;
  const dot3 = useRef(new Animated.Value(0.3)).current;

  useEffect(() => {
    const animate = (dot: Animated.Value, delay: number) =>
      Animated.loop(
        Animated.sequence([
          Animated.delay(delay),
          Animated.timing(dot, {
            toValue: 1,
            duration: 400,
            useNativeDriver: false,
          }),
          Animated.timing(dot, {
            toValue: 0.3,
            duration: 400,
            useNativeDriver: false,
          }),
        ]),
      );

    animate(dot1, 0).start();
    animate(dot2, 200).start();
    animate(dot3, 400).start();
  }, [dot1, dot2, dot3]);

  return (
    <View style={styles.dots}>
      <Animated.View style={[styles.dot, { opacity: dot1 }]} />
      <Animated.View style={[styles.dot, { opacity: dot2 }]} />
      <Animated.View style={[styles.dot, { opacity: dot3 }]} />
    </View>
  );
}

const LOGO_SIZE = width * 0.35;

const styles = StyleSheet.create({
  container: {
    // StyleSheet.absoluteFillObject was removed in React Native 0.87; absoluteFill is a
    // registered style ID and cannot be spread into a style object.
    position: "absolute",
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: color.surface,
    zIndex: 999,
  },
  logoWrap: {
    marginBottom: 24,
  },
  logo: {
    width: LOGO_SIZE,
    height: LOGO_SIZE,
    borderRadius: LOGO_SIZE * 0.15,
  },
  textWrap: {
    alignItems: "center",
  },
  title: {
    fontFamily: font.display,
    fontSize: 28,
    fontWeight: "700",
    color: color.primary,
    letterSpacing: 1,
  },
  subtitle: {
    fontFamily: font.body,
    fontSize: 14,
    color: color.textSecondary,
    marginTop: 6,
    letterSpacing: 0.5,
  },
  loadingWrap: {
    position: "absolute",
    bottom: 80,
    alignItems: "center",
  },
  loadingBar: {
    alignItems: "center",
  },
  dots: {
    flexDirection: "row",
    gap: 8,
  },
  dot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: color.primary,
  },
});
