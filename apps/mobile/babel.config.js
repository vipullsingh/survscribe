module.exports = {
  presets: ["module:@react-native/babel-preset"],
  plugins: [
    // Bare React Native does not populate `process.env` in the bundle, so build-time
    // configuration is inlined here instead. This is a Babel plugin with no native module
    // behind it, which keeps it out of the Gradle/CocoaPods autolinking path entirely.
    //
    // Only non-secret values belong in .env: a React Native bundle is readable on any
    // device it ships to (ADR-0008).
    [
      "module:react-native-dotenv",
      {
        moduleName: "@env",
        path: ".env",
        safe: false,
        allowUndefined: true,
      },
    ],
  ],
};
