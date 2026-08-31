/**
 * Types for the virtual `@env` module produced by react-native-dotenv.
 *
 * Every value is optional: a missing .env is a normal state (CI, a fresh clone, a
 * release build configured elsewhere), and src/core/env.ts falls back to defaults rather
 * than failing to boot.
 */
declare module "@env" {
  export const SURVSCRIBE_ENV: string | undefined;
  export const SURVSCRIBE_API_BASE_URL: string | undefined;
}
