// Needed only so Jest (via @react-native/jest-preset) can transform react-native's own
// Flow-typed source files when running this package's component tests in isolation.
module.exports = {
  presets: ["module:@react-native/babel-preset"],
};
