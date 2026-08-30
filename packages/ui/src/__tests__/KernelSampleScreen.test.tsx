import React from "react";
import { render, screen } from "@testing-library/react-native";

import { KernelSampleScreen } from "../samples/KernelSampleScreen";
import { color } from "../tokens";

function flatten(style: unknown): Record<string, unknown> {
  return Object.assign({}, ...[style].flat(Infinity).filter(Boolean));
}

/**
 * sprint_0002 task 4's acceptance criterion, checked directly: "packages/ui tokens are
 * consumable from apps/mobile [...]; a sample screen renders the primary blue, the type
 * scale, and a monospace right-aligned rupee figure correctly." This suite renders the
 * actual sample screen (which imports every design-kernel component the same way a real
 * app screen would) and asserts each of those three things against the real, resolved
 * style objects RNTL exposes -- the closest verifiable proxy to a screenshot available
 * without an iOS simulator or Android emulator (neither exists in this environment).
 */
describe("KernelSampleScreen — design kernel end-to-end", () => {
  it("renders the primary-blue button (#1E3A8A, D30)", () => {
    render(<KernelSampleScreen />);

    const style = flatten(screen.getByRole("button", { name: "Save & Continue" }).props.style);
    expect(style.backgroundColor).toBe(color.primary);
    expect(color.primary).toBe("#1E3A8A");
  });

  it("renders the page title in the Plus Jakarta Sans / 20px type-scale row", () => {
    render(<KernelSampleScreen />);

    const style = flatten(screen.getByText("Design Kernel Sample").props.style);
    expect(style.fontFamily).toBe("Plus Jakarta Sans");
    expect(style.fontSize).toBe(20);
    expect(style.fontWeight).toBe("700");
  });

  it("renders a monospace, right-aligned rupee figure with correct Indian grouping", () => {
    render(<KernelSampleScreen />);

    const figure = screen.getByText("₹4,97,500.00");
    const style = flatten(figure.props.style);
    expect(style.fontFamily).toBe("JetBrains Mono");
    expect(style.textAlign).toBe("right");
  });

  it("consumes required and error affordances on a real form field", () => {
    render(<KernelSampleScreen />);

    expect(screen.getByText("*")).toBeTruthy();
    expect(screen.getByText("Must be at least 6 alphanumeric characters")).toBeTruthy();
  });
});
