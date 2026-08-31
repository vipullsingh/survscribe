// Metro configuration.
//
// This app lives in a pnpm workspace, so Metro must watch the repository root and be
// told about both node_modules trees. Without that it cannot resolve @survscribe/types
// or @survscribe/ui, which live outside the app under packages/.
const path = require("node:path");
const { getDefaultConfig, mergeConfig } = require("@react-native/metro-config");

const projectRoot = __dirname;
const workspaceRoot = path.resolve(projectRoot, "../..");

/** @type {import('@react-native/metro-config').MetroConfig} */
const config = {
  watchFolders: [workspaceRoot],
  resolver: {
    nodeModulesPaths: [
      path.resolve(projectRoot, "node_modules"),
      path.resolve(workspaceRoot, "node_modules"),
    ],
    // Gradle rewrites these directories constantly during a build. Metro's fallback
    // watcher crashes with ENOENT when it tries to watch a class file that has just been
    // deleted, so they are excluded from the module graph and the watch set.
    blockList: [/.*\/node_modules\/.*\/build\/.*/, /.*\/node_modules\/.*\/classes\/.*/],
  },
};

module.exports = mergeConfig(getDefaultConfig(projectRoot), config);
