import { describe, expect, it } from 'vitest';

import { initialMenuPosition, menuPosition } from './linked-card-menus';

const windowSize = { width: 1280, height: 720 };
const menu = { width: 220, height: 150 };
const button = { x: 100, y: 200, width: 24, height: 24 };

describe('initialMenuPosition', () => {
  it('is 6 px below the button, at its left', () => {
    expect(initialMenuPosition({ button })).toEqual({ x: 100, y: 230 });
  });

  it("keeps 16 px from the window's left", () => {
    const atEdge = { ...button, x: 4 };

    expect(initialMenuPosition({ button: atEdge }).x).toBe(16);
  });
});

describe('menuPosition', () => {
  it('is 6 px below the button, at its left', () => {
    expect(menuPosition({ button, menu, windowSize })).toEqual({
      x: 100,
      y: 230,
    });
  });

  it("moves left to keep 16 px from the window's right", () => {
    const nearRight = { ...button, x: 1200 };

    expect(menuPosition({ button: nearRight, menu, windowSize }).x).toBe(1044);
  });

  it("keeps 16 px from the window's left", () => {
    const atEdge = { ...button, x: 4 };

    expect(menuPosition({ button: atEdge, menu, windowSize }).x).toBe(16);
  });

  it('stays below when it just fits, 16 px above the bottom', () => {
    // Its bottom is at 548 + 6 + 150 = 704, 16 px above the window's.
    const low = { ...button, y: 524 };

    expect(menuPosition({ button: low, menu, windowSize }).y).toBe(554);
  });

  it("goes 6 px above the button when there's no room below", () => {
    const lower = { ...button, y: 600 };

    expect(menuPosition({ button: lower, menu, windowSize }).y).toBe(444);
  });

  it('keeps 16 px from the top when there is no room above either', () => {
    const tall = { width: 220, height: 700 };

    expect(menuPosition({ button, menu: tall, windowSize }).y).toBe(16);
  });
});
