import { registerRootComponent } from "expo";

import App from "./src/app/App";

// registerRootComponent calls AppRegistry.registerComponent("main", () => App) and,
// in a native build, also wires the app into Expo's runtime. It replaces the bare
// React Native index.js + app.json name registration.
registerRootComponent(App);
