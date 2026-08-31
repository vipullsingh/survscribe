# ADR-0011 — Mobile runtime: bare React Native, not Expo

- **Status:** Accepted
- **Date:** 2026-09-01
- **Supersedes:** ADR-0001 D59 (the 2026-08-30 bare React Native → Expo migration)
- **Amends:** ADR-0007 §1 (toolchain versions), ADR-0008 §3 (mobile build-time configuration)
- **Does not change:** D19 (mobile client is React Native + TypeScript), D20 (WatermelonDB over SQLite with SQLCipher), D24 (desktop web deferred post-MVP)

---

## 1. Context

On 2026-08-30 the mobile app was migrated from bare React Native to Expo SDK 57 on owner
instruction (`CLAUDE.md` §18 **D59**, §19.5). That migration was completed at the file
level but **never executed**: `CLAUDE.md` §15 item 14 records that the Expo CLI was never
run at all — `expo start`, `expo prebuild`, `expo run:android` and `expo-doctor` were all
skipped because the development environment's Node was 20.17, below Expo SDK 57's
required ≥ 20.19.4. The app has never launched on a simulator or emulator, so
`sprint_0001`'s acceptance criterion ("runs on iOS simulator and Android emulator")
has stayed open since the bootstrap.

The owner reports sustained friction with Expo Go in day-to-day work. That friction is
not incidental — it follows from what this product actually needs:

- **`CR-NF2` / D20** requires WatermelonDB over SQLite encrypted with SQLCipher.
- **`CR-W9` / FR-6.2** requires camera capture with an indelible watermark overlay
  (timestamp, GPS, claim ref, surveyor ID) burnt into the image.
- **`CR-A12` / ADR-0003 §3** requires the session token to live in the iOS Keychain /
  Android Keystore, with a device-passcode unlock path.

None of these can run in Expo Go. Every one of them would have required an Expo config
plugin plus a custom development build — that is, the Expo managed workflow's main
benefit (no native project, no native toolchain) would have been given up on the very
first feature sprint that touches the offline store. Continuous Native Generation also
means `ios/` and `android/` are build output rather than source, which is the wrong
posture for an app whose native configuration — camera and location permissions,
Keychain/Keystore entitlements, SQLCipher linkage, deep-link schemes for the Stage 3
`whatsapp:` / `tel:` dispatch — must be reviewable in version control.

Nothing product-facing was at stake in this reversal: no feature is implemented
(`CLAUDE.md` §2.2). What existed was a navigation shell, a splash screen and an API
client, none of which is Expo-specific.

## 2. Decision

**The mobile app runs on bare React Native. Expo is removed entirely from the
repository.**

1. **React Native 0.87.1** (current `latest`), **React 19.2.3**, generated from
   `@react-native-community/cli` with package name `com.survscribe.mobile`.
2. **`apps/mobile/android/` and `apps/mobile/ios/` are committed source.** They come out
   of `.gitignore`; only their build output (`android/build/`, `android/app/build/`,
   `android/.gradle/`, `ios/Pods/`, `ios/build/`, …) stays ignored. There is no
   `prebuild` step to regenerate them, so a native edit that is not committed is lost.
3. **React Navigation v7** replaces v6. v6 targets React 18; v7 is the line that supports
   React 19. The dynamic API (`NavigationContainer`, `createBottomTabNavigator`) is
   unchanged, so the canonical 5-tab shell (Design System §6.1) is untouched.
4. **Build-time configuration moves to `react-native-dotenv`**, replacing Expo's
   `EXPO_PUBLIC_*` inlining. Variables are now `SURVSCRIBE_ENV` and
   `SURVSCRIBE_API_BASE_URL`, imported from the virtual `@env` module. This is a Babel
   plugin with no native module behind it, deliberately: configuration must not add a
   second thing that can fail inside Gradle or CocoaPods.
5. **pnpm runs with `node-linker=hoisted`** (repository-root `.npmrc`). React Native's
   Gradle autolinking, CocoaPods, and `@react-native/jest-preset` all assume a flat
   `node_modules`; pnpm's default symlinked store breaks them as opaque native build
   failures. Because dependencies now install at the workspace root rather than in
   `apps/mobile/node_modules`, the Gradle paths in `android/settings.gradle` and
   `android/app/build.gradle` are set explicitly and carry a comment saying why.
6. **`packages/ui` is aligned to RN 0.87 / React 19**, which requires
   `@testing-library/react-native` v14 and its `test-renderer` peer in place of the
   deprecated `react-test-renderer`.

## 3. Consequences

### Accepted costs

- **The native projects are now maintained by hand.** An RN upgrade means diffing the
  new template against `android/` and `ios/` rather than re-running `prebuild`. This is
  the ordinary bare-RN cost and is the direct price of point 2 above.
- **The branded app icon and native splash are lost for now.** Expo's `app.json` `icon`,
  `adaptiveIcon` and `splash` blocks have no bare-RN equivalent; the launcher icon
  reverts to the stock React Native icon and the pre-JavaScript splash is a plain
  background. The animated in-app splash (`src/app/SplashScreen.tsx`) is unaffected.
  Restoring branded native assets from `assets/logo.png` is tracked follow-up work.
- **The `survscribe` deep-link scheme is dropped.** Nothing consumes it yet; it belongs
  in `AndroidManifest.xml` and `Info.plist` when Stage 3's dispatch links land.
- **`node-linker=hoisted` allows phantom dependencies workspace-wide.** A package can now
  import something it does not declare and still resolve. The workspace is five packages
  and the trade was made knowingly, in exchange for removing a whole class of native
  build failure.
- **No Expo services.** EAS Build, EAS Update / over-the-air updates and Expo's managed
  credentials are not available. None was in use or planned; report dispatch and sync go
  through the SurvScribe backend.

### Gained

- The offline store (D20) becomes an ordinary autolinked native module — no config
  plugin, no custom dev build.
- Native permissions, entitlements and linkage are reviewable in pull requests.
- The Android build was executed and verified on a real emulator, closing an acceptance
  criterion that had been open since `sprint_0001`.

## 4. Alternatives considered

- **Stay on Expo with a custom development build.** Technically workable, and it keeps
  EAS. Rejected: it pays the full cost of the bare workflow (native toolchain, native
  builds, per-module config plugins) while keeping Expo's abstraction between the project
  and the native config it must own — and the D59 setup had never actually been run, so
  there was no working state to preserve.
- **Keep pnpm's default isolated linker and patch every native path.** More faithful to
  pnpm, but it puts `require.resolve`-derived paths into Gradle and CocoaPods on a
  toolchain the team is already fighting. Rejected in favour of the flat layout those
  tools expect.
- **Move `apps/mobile` out of the pnpm workspace entirely.** Maximum build isolation, but
  it breaks the single-install workflow and the Turbo `lint`/`typecheck`/`test` pipeline,
  and `@survscribe/types` / `@survscribe/ui` would need `file:` links. Rejected as
  disproportionate.

## 5. Verification

Run on 2026-09-01, in this repository, on Node 24.19.0:

| Check | Result |
| :-- | :-- |
| `pnpm install` under `node-linker=hoisted` | Clean |
| `pnpm run format:check` / `lint` / `typecheck` / `test` | All exit 0 across 5 JS/TS packages |
| `packages/ui` design-kernel suite | 23 / 23 assertions pass on RN 0.87 / React 19 / RNTL 14 |
| `npx react-native config` | Resolves `react-native` at the workspace root; autolinks `react-native-screens` and `react-native-safe-area-context` |
| Android debug build + emulator run | See `CLAUDE.md` §19.6 for the recorded outcome |

**Not verified:** the iOS build. `apps/mobile/ios/` is generated and committed, but
CocoaPods installation and an Xcode build require macOS, which this environment does not
have. This remains open alongside `CLAUDE.md` §15 item 15 (GitHub Actions has still never
executed the CI workflow).
