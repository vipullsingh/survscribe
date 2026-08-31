// Expo Metro config.
//
// This app lives in a pnpm workspace, so Metro must watch the repository root and be
// told about both node_modules trees. Without that it cannot resolve @survscribe/types
// or @survscribe/ui, which are symlinked from packages/ and live outside the app.
const path = require("node:path");
const { getDefaultConfig } = require("expo/metro-config");

const projectRoot = __dirname;
const workspaceRoot = path.resolve(projectRoot, "../..");

const config = getDefaultConfig(projectRoot);

config.watchFolders = [workspaceRoot];
config.resolver.nodeModulesPaths = [
  path.resolve(projectRoot, "node_modules"),
  path.resolve(workspaceRoot, "node_modules"),
];
// pnpm uses a symlinked, non-hoisted store; Metro must follow the symlinks.
config.resolver.unstable_enableSymlinks = true;
config.resolver.disableHierarchicalLookup = false;

// Ignore volatile build directories in node_modules from being watched/bundled.
// This prevents the ENOENT crash when Metro's fallback watcher tries to watch deleted gradle class files.
config.resolver.blockList = [
  /.*\/node_modules\/.*\/build\/.*/,
  /.*\/node_modules\/.*\/classes\/.*/,
];

module.exports = config;
