import React from "react";
import { fireEvent, render, screen } from "@testing-library/react-native";

import { TextField } from "../TextField";
import { color } from "../tokens";

function flatten(style: unknown): Record<string, unknown> {
  return Object.assign({}, ...[style].flat(Infinity).filter(Boolean));
}

describe("TextField", () => {
  it("renders the label and calls onChangeText as the surveyor types", async () => {
    const onChangeText = jest.fn();
    await render(<TextField label="Insured Name" value="" onChangeText={onChangeText} />);

    await fireEvent.changeText(screen.getByLabelText("Insured Name"), "Rajesh Textiles Pvt Ltd");

    expect(onChangeText).toHaveBeenCalledWith("Rajesh Textiles Pvt Ltd");
    expect(screen.getByText("Insured Name")).toBeTruthy();
  });

  it("shows a required marker only when required is true", async () => {
    await render(<TextField label="Policy Number" value="" onChangeText={jest.fn()} required />);
    expect(screen.getByText("*")).toBeTruthy();
  });

  it("prefers the error message over helper text, and does not show both", async () => {
    await render(
      <TextField
        label="Mobile Number"
        value="123"
        onChangeText={jest.fn()}
        helperText="10-digit number"
        error="Must be a valid +91 mobile number"
      />,
    );

    expect(screen.getByText("Must be a valid +91 mobile number")).toBeTruthy();
    expect(screen.queryByText("10-digit number")).toBeNull();
  });

  it("is not editable when readOnly, matching the design system's locked-field treatment", async () => {
    await render(
      <TextField label="Claim Ref" value="SS-2026-00101" onChangeText={jest.fn()} readOnly />,
    );

    expect(screen.getByLabelText("Claim Ref").props.editable).toBe(false);
  });

  it("renders numericDisplay fields right-aligned in the monospace face", async () => {
    await render(
      <TextField label="GPS Latitude" value="23.033863" onChangeText={jest.fn()} numericDisplay />,
    );

    const style = flatten(screen.getByLabelText("GPS Latitude").props.style);
    expect(style.textAlign).toBe("right");
    expect(style.fontFamily).toBe("JetBrains Mono");
  });

  it("renders the error text in the critical colour, not the neutral helper colour", async () => {
    await render(<TextField label="Excess" value="" onChangeText={jest.fn()} error="Required" />);

    const style = flatten(screen.getByText("Required").props.style);
    expect(style.color).toBe(color.critical);
  });
});
