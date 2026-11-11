import { describe, expect, it } from 'vitest';

import { tooltipPosition, tooltipWidth } from './title-tooltips';

const windowSize = { width: 1280, height: 720 };
const tooltip = { width: 300, height: 40 };
const title = { x: 100, y: 200, width: 400, height: 18 };

describe('tooltipPosition', () => {
  it('is right above the title, at its left', () => {
    expect(tooltipPosition({ title, tooltip, windowSize })).toEqual({
      x: 100,
      y: 160,
    });
  });

  it('is right below the title without room above it', () => {
    const nearTop = { ...title, y: 30 };

    expect(tooltipPosition({ title: nearTop, tooltip, windowSize }).y).toBe(48);
  });

  it("moves left to keep 16 px from the window's right", () => {
    const nearRight = { ...title, x: 1100 };

    expect(tooltipPosition({ title: nearRight, tooltip, windowSize }).x).toBe(
      964
    );
  });

  it("keeps 16 px from the window's left", () => {
    const atEdge = { ...title, x: 4 };

    expect(tooltipPosition({ title: atEdge, tooltip, windowSize }).x).toBe(16);
  });
});

describe('tooltipWidth', () => {
  it("is the card's width", () => {
    expect(
      tooltipWidth({ card: { width: 500, height: 300 }, windowSize })
    ).toBe(500);
  });

  it('is at least 240 px, for a card zoomed out', () => {
    expect(tooltipWidth({ card: { width: 90, height: 60 }, windowSize })).toBe(
      240
    );
  });

  it('stays 16 px inside the window', () => {
    expect(
      tooltipWidth({ card: { width: 2000, height: 600 }, windowSize })
    ).toBe(1248);
  });
});
