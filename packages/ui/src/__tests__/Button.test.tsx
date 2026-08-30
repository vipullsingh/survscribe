import React from "react";
import { fireEvent, render, screen } from "@testing-library/react-native";

import { Button } from "../Button";
import { color } from "../tokens";

function flatten(style: unknown): Record<string, unknown> {
  return Object.assign({}, ...[style].flat(Infinity).filter(Boolean));
}

describe("Button", () => {
  it("calls onPress when tapped", () => {
    const onPress = jest.fn();
    render(<Button label="Save & Continue" onPress={onPress} />);

    fireEvent.press(screen.getByRole("button", { name: "Save & Continue" }));

    expect(onPress).toHaveBeenCalledTimes(1);
  });

  it("renders the primary variant in the design system's primary blue (#1E3A8A)", () => {
    render(<Button label="Submit" onPress={jest.fn()} variant="primary" testID="btn" />);

    const style = flatten(screen.getByTestId("btn").props.style);
    expect(style.backgroundColor).toBe(color.primary);
    expect(style.height).toBe(44); // design system 4.2: 44px primary/secondary/destructive
  });

  it("renders the ai-utility variant at the restrained 36px height, not the standard 44px", () => {
    render(
      <Button
        label="Draft Narrative with Field Notes"
        onPress={jest.fn()}
        variant="ai-utility"
        testID="btn"
      />,
    );

    const style = flatten(screen.getByTestId("btn").props.style);
    expect(style.height).toBe(36);
    expect(style.backgroundColor).toBe(color.canvas);
  });

  it("does not call onPress while loading, and shows a spinner instead of the label", () => {
    const onPress = jest.fn();
    render(<Button label="Submitting" onPress={onPress} loading testID="btn" />);

    fireEvent.press(screen.getByTestId("btn"));

    expect(onPress).not.toHaveBeenCalled();
    expect(screen.queryByText("Submitting")).toBeNull();
  });

  it("does not call onPress while disabled", () => {
    const onPress = jest.fn();
    render(<Button label="Delete" onPress={onPress} disabled testID="btn" />);

    fireEvent.press(screen.getByTestId("btn"));

    expect(onPress).not.toHaveBeenCalled();
  });

  it("marks a destructive button with the critical text colour", () => {
    render(<Button label="Delete Item" onPress={jest.fn()} variant="destructive" />);

    const label = screen.getByText("Delete Item");
    const style = flatten(label.props.style);
    expect(style.color).toBe(color.critical);
  });
});
