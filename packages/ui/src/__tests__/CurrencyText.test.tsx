import React from "react";
import { render, screen } from "@testing-library/react-native";

import { CurrencyText } from "../CurrencyText";
import { color } from "../tokens";

function flatten(style: unknown): Record<string, unknown> {
  return Object.assign({}, ...[style].flat(Infinity).filter(Boolean));
}

describe("CurrencyText", () => {
  it("renders the ADR-0009-worked-example net recommended figure with Indian grouping", () => {
    // physical-schema.md section 30.2's worked example: Net Recommended 4,97,500.00
    render(<CurrencyText amount="497500.00" />);
    expect(screen.getByText("₹4,97,500.00")).toBeTruthy();
  });

  it("renders crore-scale amounts with correct lakh/crore grouping, not Western thousands", () => {
    render(<CurrencyText amount="10000000.00" />);
    expect(screen.getByText("₹1,00,00,000.00")).toBeTruthy();
  });

  it("is right-aligned and monospace, per design system section 3.2", () => {
    render(<CurrencyText amount="1234.50" />);

    const style = flatten(screen.getByText("₹1,234.50").props.style);
    expect(style.textAlign).toBe("right");
    expect(style.fontFamily).toBe("JetBrains Mono");
  });

  it("uses the larger Financial Total scale (15px/700) for variant='total'", () => {
    render(<CurrencyText amount="497500.00" variant="total" />);

    const style = flatten(screen.getByText("₹4,97,500.00").props.style);
    expect(style.fontSize).toBe(15);
    expect(style.fontWeight).toBe("700");
  });

  it("uses the smaller Financial line-item scale (13px/500) by default", () => {
    render(<CurrencyText amount="497500.00" />);

    const style = flatten(screen.getByText("₹4,97,500.00").props.style);
    expect(style.fontSize).toBe(13);
    expect(style.fontWeight).toBe("500");
  });

  it("renders a negative deduction in the critical colour only when negativeIsCritical is set", () => {
    render(<CurrencyText amount="-25000.00" negativeIsCritical />);

    const style = flatten(screen.getByText("-₹25,000.00").props.style);
    expect(style.color).toBe(color.critical);
  });

  it("does not apply the critical colour to a negative amount by default", () => {
    render(<CurrencyText amount="-25000.00" />);

    const style = flatten(screen.getByText("-₹25,000.00").props.style);
    expect(style.color).not.toBe(color.critical);
  });
});
