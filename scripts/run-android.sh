#!/usr/bin/env bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "================================================"
echo "   SurvScribe Android App Launcher              "
echo "================================================"

# 1. Check ADB Devices
echo -e "\n[1/2] Checking Android Devices..."
if command -v adb &> /dev/null; then
  DEVICES=$(adb devices | grep -w "device" || true)
  if [ -n "$DEVICES" ]; then
    echo "Found active Android device / emulator."
  else
    echo "No active Android device detected. Launch an emulator from Android Studio or connect via USB."
  fi
else
  echo "Warning: 'adb' not found in PATH."
fi

# 2. Build and run the Expo app on Android
# `expo run:android` prebuilds the native project (gitignored) and builds with Gradle.
echo -e "\n[2/2] Building and launching the Expo app on Android..."
cd "$PROJECT_ROOT/apps/mobile"
npx expo run:android
