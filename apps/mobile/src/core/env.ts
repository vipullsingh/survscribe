/**
 * Runtime configuration for the mobile app.
 *
 * Expo inlines only variables prefixed `EXPO_PUBLIC_` into the JavaScript bundle at
 * build time (via babel-preset-expo). Nothing secret belongs here: a React Native
 * bundle is readable on any device it ships to, so an API key placed in this file is a
 * published API key. Credentials for SMS, email, maps, LLM and OCR providers stay on
 * the backend, which is why the app talks to those services only through our own API
 * (ADR-0002, ADR-0008).
 */

export type AppEnvironment = "development" | "staging" | "production";

interface Env {
  environment: AppEnvironment;
  apiBaseUrl: string;
  /** Fail fast rather than hang on a dead network in the field. */
  requestTimeoutMs: number;
}

const DEFAULTS: Env = {
  environment: "development",
  // Android emulators reach the host machine at 10.0.2.2, not localhost.
  apiBaseUrl: "http://10.0.2.2:8080/api/v1",
  requestTimeoutMs: 20_000,
};

export const env: Env = {
  ...DEFAULTS,
  environment:
    (process.env.EXPO_PUBLIC_SURVSCRIBE_ENV as AppEnvironment | undefined) ?? DEFAULTS.environment,
  apiBaseUrl: process.env.EXPO_PUBLIC_SURVSCRIBE_API_BASE_URL ?? DEFAULTS.apiBaseUrl,
};

export const isProduction = env.environment === "production";
