# SurvScribe Mobile Application (`apps/mobile`)

React Native + TypeScript application for iOS and Android.

## Architecture Highlights
- **Layout**: Feature-first structure (`src/features/<feature>/{api,components,hooks,screens,store,types}`) + `src/infrastructure/` + `src/shared/`.
- **Database**: WatermelonDB over SQLite encrypted via SQLCipher (AES-256).
- **Draft Engine**: Client-side TypeScript `.docx` generator for offline preliminary and final survey report drafts.

## Development Setup
```bash
# Run iOS simulator
pnpm --filter mobile run ios

# Run Android emulator
pnpm --filter mobile run android
```
