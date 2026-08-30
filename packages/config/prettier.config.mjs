/**
 * Shared Prettier configuration.
 *
 * printWidth 100 rather than the default 80: the codebase carries long insurance-domain
 * identifiers (`underinsurance_deduction`, `PreliminarySurveyReport`) that wrap badly at 80.
 */
export default {
  printWidth: 100,
  tabWidth: 2,
  semi: true,
  singleQuote: false,
  trailingComma: "all",
  bracketSpacing: true,
  arrowParens: "always",
  endOfLine: "lf",
};
