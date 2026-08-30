const path = require("node:path");
const { getDefaultConfig, mergeConfig } = require("@react-native/metro-config");

// This app lives in a pnpm workspace, so Metro must be told to watch the repository
// root. Without watchFolders it cannot resolve @survscribe/types or @survscribe/ui,
// which are symlinked from packages/ and live outside the app directory.
const workspaceRoot = path.resolve(__dirname, "../..");

module.exports = mergeConfig(getDefaultConfig(__dirname), {
  watchFolders: [workspaceRoot],
  resolver: {
    // pnpm's nested store means the default single-node_modules assumption is wrong.
    nodeModulesPaths: [
      path.resolve(__dirname, "node_modules"),
      path.resolve(workspaceRoot, "node_modules"),
    ],
    disableHierarchicalLookup: false,
  },
});
