/**
 * Shared flat ESLint configuration for the SurvScribe workspace.
 *
 * Deliberately small. Rules earn their place by catching a defect this project can
 * actually ship, not by matching a style preference -- Prettier owns formatting.
 */
import js from "@eslint/js";
import tseslint from "typescript-eslint";

/** Runtime globals available in Node scripts and config files. */
const nodeGlobals = {
  process: "readonly",
  console: "readonly",
  Buffer: "readonly",
  URL: "readonly",
  __dirname: "readonly",
  __filename: "readonly",
  module: "writable",
  require: "readonly",
  exports: "writable",
  setTimeout: "readonly",
  clearTimeout: "readonly",
  setInterval: "readonly",
  clearInterval: "readonly",
};

/** Runtime globals available in the React Native app. */
const reactNativeGlobals = {
  console: "readonly",
  process: "readonly",
  fetch: "readonly",
  Response: "readonly",
  Request: "readonly",
  Headers: "readonly",
  URL: "readonly",
  URLSearchParams: "readonly",
  AbortController: "readonly",
  AbortSignal: "readonly",
  setTimeout: "readonly",
  clearTimeout: "readonly",
  setInterval: "readonly",
  clearInterval: "readonly",
  __DEV__: "readonly",
};

export default tseslint.config(
  {
    ignores: [
      "**/node_modules/**",
      "**/dist/**",
      "**/build/**",
      "**/coverage/**",
      "**/ios/**",
      "**/android/**",
      // Generated from the OpenAPI contract; lint findings are fixed in the generator.
      "**/src/schema.d.ts",
    ],
  },

  js.configs.recommended,
  ...tseslint.configs.recommended,

  {
    // TypeScript checks for undefined identifiers itself, with full type information and
    // without needing a hand-maintained globals list. Leaving no-undef on for .ts files
    // duplicates that badly: it cannot see type-only names and reports false positives on
    // every platform global. typescript-eslint's own guidance is to turn it off here.
    files: ["**/*.ts", "**/*.tsx"],
    rules: { "no-undef": "off" },
  },

  {
    files: ["**/*.{js,mjs,cjs}"],
    languageOptions: { globals: nodeGlobals },
    rules: {
      // babel.config.js and metro.config.js are consumed by CommonJS tooling and cannot
      // be ES modules.
      "@typescript-eslint/no-require-imports": "off",
    },
  },

  {
    files: ["apps/mobile/**/*.{ts,tsx}", "src/**/*.{ts,tsx}"],
    languageOptions: { globals: reactNativeGlobals },
  },

  {
    // Build and maintenance scripts legitimately report progress on stdout.
    files: ["**/scripts/**"],
    languageOptions: { globals: nodeGlobals },
    rules: { "no-console": "off" },
  },

  {
    rules: {
      "@typescript-eslint/no-unused-vars": [
        "error",
        { argsIgnorePattern: "^_", varsIgnorePattern: "^_" },
      ],
      "@typescript-eslint/consistent-type-imports": [
        "error",
        { prefer: "type-imports", fixStyle: "separate-type-imports" },
      ],
      // no-floating-promises would be valuable here -- a dropped promise in the offline
      // sync queue silently loses a surveyor's work -- but it requires type-aware
      // linting (parserOptions.project), which is a separate change. Tracked in ADR-0007.
      eqeqeq: ["error", "always", { null: "ignore" }],
      "no-console": ["warn", { allow: ["warn", "error"] }],
    },
  },
);
