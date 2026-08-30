# @survscribe/ui

Shared React Native component library implementing [`Visual Theme & Design System.md`](../../documentation/Visual%20Theme%20&%20Design%20System.md) v2.0.0-Enterprise. The design system document is the authority; this package is its executable form.

## Status — `sprint_0002` design kernel

Tokens (`src/tokens.ts`) plus three base controls, built directly against Design System sections 3–4:

- **`Button`** — the four variants fixed by section 4.2 (`primary`, `secondary`, `destructive`, `ai-utility`), transcribed from its CSS block.
- **`TextField`** — the form control fixed by section 4.1: 44px height, default/focus/read-only border treatment, helper/error line.
- **`CurrencyText`** — the ₹ display fixed by sections 3.1–3.2: monospace, right-aligned, Indian lakh/crore grouping, two type-scale rows (line item vs. total).

Everything else — data tables, evidence cards, the 15-stage tracker, modals, the audit-finding box — is built against real screens starting `sprint_0003`, once the auth screens (the only ones with delivered SVG artboards) are implemented.

## Verifying the kernel without a simulator

No iOS simulator or Android emulator is available in this development environment, so "does it render correctly" is answered with [React Native Testing Library](https://callstack.github.io/react-native-testing-library/) assertions against resolved styles, not a screenshot. `src/samples/KernelSampleScreen.tsx` renders every component together against a realistic worked example (the `physical-schema.md` §30.2 loss-quantification figures), and `src/__tests__/KernelSampleScreen.test.tsx` asserts the primary blue, the type scale, and monospace right-aligned rupee formatting directly — this is the "sample screen" `sprint_0002`'s acceptance criteria ask for.

```bash
pnpm --filter @survscribe/ui test
```

## Known gap: the focus-ring shadow

Design System §4.1 specifies a focus state of `1.5px solid #1E3A8A` border **plus** a `0 0 0 3px rgba(30, 58, 138, 0.1)` outer ring. `TextField` implements the border change; the ring itself does not have a direct React Native style primitive (no CSS `box-shadow`-as-outline equivalent) and needs either a platform-specific shadow view or a library such as Reanimated to draw an animated outer ring. This is noted in `TextField.tsx` rather than silently dropped, and is left for whichever sprint first builds a screen where the ring's absence is visible enough to matter.

## A note on this package's Jest config

`jest.config.cjs` sets `transformIgnorePatterns: []` rather than the "react-native" preset's default. The preset's own pattern assumes a flat, hoisted `node_modules` layout; under pnpm every package actually resolves through `node_modules/.pnpm/<name>@<version>/node_modules/<name>/...`, so the preset's regex matches (and wrongly excludes from transform) the **outer** `node_modules/` segment before it ever reaches the inner one that names the package — on every OS, not only Windows. Transforming everything is the correct fix at this package's current size; revisit if the test suite grows large enough for the extra transform cost to matter.
