import { AppRegistry } from "react-native";

import App from "./src/app/App";
import { name as appName } from "./app.json";

// The registered name must match MainActivity.getMainComponentName() on Android and the
// moduleName passed to the React root view on iOS. Changing it here alone gives a blank
// screen on device with no JavaScript error.
AppRegistry.registerComponent(appName, () => App);
