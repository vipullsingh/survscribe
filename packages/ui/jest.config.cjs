/**
 * The "react-native" Jest preset's default `transformIgnorePatterns` assumes a flat,
 * hoisted node_modules layout. Under pnpm, every package actually lives beneath
 * node_modules/.pnpm/<name>@<version>/node_modules/<name>/..., so the preset's pattern
 * matches (and wrongly ignores-for-transform) the OUTER "node_modules/" segment before
 * ever reaching the inner one that names the package — on every OS, not just Windows.
 * The practical fix for a component library with a handful of test files is simply to
 * stop ignoring anything: transform every required module, including node_modules.
 * This would be too slow for a large app's full suite; it is not a concern at this
 * package's current size.
 */
module.exports = {
  preset: "react-native",
  transformIgnorePatterns: [],
};
