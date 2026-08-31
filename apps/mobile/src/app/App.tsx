/**
 * Application root.
 *
 * A navigation shell only. It establishes the canonical 5-tab bottom navigation from the
 * design system so that stage screens have somewhere to mount, and nothing more --
 * feature screens arrive from sprint_0003 onward.
 *
 * On launch, an animated splash screen is shown for ~2 seconds while the app
 * initialises. All tabs currently display a "Coming Soon" screen until the
 * corresponding sprint ships the real feature.
 */
import React, { useState } from "react";
import { StatusBar } from "expo-status-bar";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { NavigationContainer } from "@react-navigation/native";
import { createBottomTabNavigator } from "@react-navigation/bottom-tabs";
import { color, font } from "@survscribe/ui";

import { SplashScreen } from "./SplashScreen";
import { ComingSoonScreen } from "./ComingSoonScreen";

export type RootTabParamList = {
  Dashboard: undefined;
  Claims: undefined;
  "Field Studio": undefined;
  Reports: undefined;
  Profile: undefined;
};

const Tab = createBottomTabNavigator<RootTabParamList>();

/**
 * The five tabs are fixed by the design system (section 6.1) and reconciled with
 * 01_dashboard.md. They are not a placeholder set: navigation labels appear in screen
 * specs and in user documentation, so changing them is a spec change, not a code change.
 */
export default function App(): React.JSX.Element {
  const [showSplash, setShowSplash] = useState(true);

  return (
    <SafeAreaProvider>
      <StatusBar style="dark" />
      {showSplash ? (
        <SplashScreen onFinish={() => setShowSplash(false)} />
      ) : (
        <NavigationContainer>
          <Tab.Navigator
            screenOptions={{
              headerStyle: { backgroundColor: color.surface },
              headerTitleStyle: { fontFamily: font.display, color: color.textPrimary },
              tabBarActiveTintColor: color.primary,
              tabBarInactiveTintColor: color.textMuted,
              tabBarStyle: {
                backgroundColor: color.surface,
                borderTopColor: color.borderSubtle,
                // Touch targets never drop below 44pt (design system section 6.1).
                minHeight: 56,
              },
            }}
          >
            <Tab.Screen name="Dashboard">
              {() => (
                <ComingSoonScreen
                  title="Dashboard"
                  description="Your claim pipeline across the 15 stages, at a glance."
                />
              )}
            </Tab.Screen>
            <Tab.Screen name="Claims">
              {() => (
                <ComingSoonScreen
                  title="Claims"
                  description="Search, filter, and manage claim assignments and intake."
                />
              )}
            </Tab.Screen>
            <Tab.Screen name="Field Studio">
              {() => (
                <ComingSoonScreen
                  title="Field Studio"
                  description="Capture evidence, photos, and annotate damage registers on-site."
                />
              )}
            </Tab.Screen>
            <Tab.Screen name="Reports">
              {() => (
                <ComingSoonScreen
                  title="Reports"
                  description="Assemble PSR and FSR reports with AI-assisted drafting."
                />
              )}
            </Tab.Screen>
            <Tab.Screen name="Profile">
              {() => (
                <ComingSoonScreen
                  title="Profile"
                  description="Surveyor credentials, SLA licence details, and active sessions."
                />
              )}
            </Tab.Screen>
          </Tab.Navigator>
        </NavigationContainer>
      )}
    </SafeAreaProvider>
  );
}
