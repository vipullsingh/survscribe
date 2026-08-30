/**
 * Application root.
 *
 * A navigation shell only. It establishes the canonical 5-tab bottom navigation from the
 * design system so that stage screens have somewhere to mount, and nothing more --
 * feature screens arrive from sprint_0003 onward.
 */
import React from "react";
import { StatusBar } from "expo-status-bar";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { NavigationContainer } from "@react-navigation/native";
import { createBottomTabNavigator } from "@react-navigation/bottom-tabs";
import { color, font } from "@survscribe/ui";

import { PlaceholderScreen } from "./PlaceholderScreen";

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
  return (
    <SafeAreaProvider>
      <StatusBar style="dark" />
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
              <PlaceholderScreen
                title="Dashboard"
                detail="Claim pipeline across the 15 stages. Built in sprint_0005."
              />
            )}
          </Tab.Screen>
          <Tab.Screen name="Claims">
            {() => (
              <PlaceholderScreen
                title="Claims"
                detail="Claim list and appointment intake. Built in sprint_0006."
              />
            )}
          </Tab.Screen>
          <Tab.Screen name="Field Studio">
            {() => (
              <PlaceholderScreen
                title="Field Studio"
                detail="Evidence capture and the damage register. Built in sprint_0008."
              />
            )}
          </Tab.Screen>
          <Tab.Screen name="Reports">
            {() => (
              <PlaceholderScreen
                title="Reports"
                detail="PSR and FSR assembly. Built in sprint_0009 and sprint_0013."
              />
            )}
          </Tab.Screen>
          <Tab.Screen name="Profile">
            {() => (
              <PlaceholderScreen
                title="Profile"
                detail="Surveyor profile, SLA licence details and sessions. Built in sprint_0003."
              />
            )}
          </Tab.Screen>
        </Tab.Navigator>
      </NavigationContainer>
    </SafeAreaProvider>
  );
}
