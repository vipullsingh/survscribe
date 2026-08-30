/**
 * @survscribe/ui -- shared design-system primitives.
 *
 * `sprint_0002` design kernel: tokens plus three base controls (Button, TextField,
 * CurrencyText) built directly against Design System v2.0.0-Enterprise sections 3-4.
 * Everything else -- data tables, evidence cards, the stage tracker, modals -- is built
 * against real screens starting `sprint_0003`, once the auth screens (the only ones
 * with delivered SVG artboards) are implemented.
 */
export * from "./tokens";
export * from "./Button";
export * from "./TextField";
export * from "./CurrencyText";
export { KernelSampleScreen } from "./samples/KernelSampleScreen";
