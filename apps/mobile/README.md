# SurvScribe Mobile Application (`apps/mobile`)

React Native + TypeScript application for iOS and Android.

## Architecture Highlights

- **Framework**: bare React Native 0.87.1 / React 19.2.3 (ADR-0011). The `ios/` and
  `android/` projects are **committed source**, not build output — there is no
  `prebuild` step, so a native change that is not committed is lost.
- **Layout**: Feature-first structure (`src/features/<feature>/{api,components,hooks,screens,store,types}`)
  + `src/infrastructure/` + `src/shared/`.
- **Navigation**: React Navigation v7 (bottom tabs) — `src/app/App.tsx`. The five tabs
  are fixed by Design System §6.1 and are a spec contract, not a placeholder set.
- **Database** (future): WatermelonDB over SQLite encrypted via SQLCipher (AES-256).
  Under bare React Native this is an ordinary autolinked native module: install it, then
  **rebuild** the app — a Metro reload is not enough.
- **Draft Engine** (future, post-MVP): client-side TypeScript `.docx` generator for
  offline preliminary and final survey report drafts.

## Prerequisites

- **Node ≥ 22.13.0** (React Native 0.87.1 requires `^22.13.0 || ^24.3.0 || >= 26`).
- **JDK 17** and the Android SDK for Android builds.
- **macOS + Xcode + CocoaPods** for iOS builds. Run `bundle install && bundle exec pod install`
  in `ios/` on first checkout.

## Environment

Copy `.env.example` to `.env`. `react-native-dotenv` inlines these values into the bundle
at build time and exposes them through the virtual `@env` module (see `babel.config.js`
and `src/core/env.ts`). Because they are inlined, **editing `.env` requires restarting
Metro with `--reset-cache`**.

Never put a secret here — the bundle ships to devices, so anything in it is published
(ADR-0008).

## Development Setup

```bash
# Start Metro (port 8082: 8081 collides with a local Apache service)
pnpm --filter @survscribe/mobile start

# Build + run on a connected Android device / emulator
pnpm --filter @survscribe/mobile android

# Build + run on an iOS simulator (macOS only)
pnpm --filter @survscribe/mobile ios
```

From the repo root, `pnpm run dev:android` wraps the Android launcher script (boots an
emulator if none is running), `pnpm run dev:studio` opens `android/` in Android Studio,
and `pnpm run dev:all` starts the Go backend and Metro together.

## Monorepo note

This package lives in a pnpm workspace running with `node-linker=hoisted` (see the
repository-root `.npmrc`), which React Native's Gradle and CocoaPods autolinking require.
Dependencies therefore install into the **workspace root** `node_modules`, not
`apps/mobile/node_modules`. `android/settings.gradle` and `android/app/build.gradle` set
their React Native paths explicitly for that reason — do not "simplify" them back to the
stock template values.
