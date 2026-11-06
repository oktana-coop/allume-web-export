import { expect, test, type Page } from '@playwright/test';

import { haskell, ocaml, ocamlNotes } from '../shared/boards';
import { boardCard } from '../shared/helpers';
import { cardCenter, drag, scrollBoard } from './helpers';

// OCaml opens at 100%, so the board moves as far as the mouse does. Its Notes
// card is its leftmost.
test.describe('panning', () => {
  test('scrolling pans the board', async ({ page }) => {
    await page.goto(ocaml.url);
    const before = await cardCenter({ page, board: ocamlNotes });

    await scrollBoard({ page, x: 100, y: 50 });

    const after = await cardCenter({ page, board: ocamlNotes });
    expect(after.x).toBeCloseTo(before.x - 100, 0);
    expect(after.y).toBeCloseTo(before.y - 50, 0);
  });

  test('dragging pans the board', async ({ page }) => {
    await page.goto(ocaml.url);
    const before = await cardCenter({ page, board: ocamlNotes });

    // Below OCaml's cards, on the right.
    await drag({ page, from: { x: 1200, y: 600 }, by: { x: -150, y: -80 } });

    const after = await cardCenter({ page, board: ocamlNotes });
    expect(after.x).toBeCloseTo(before.x - 150, 0);
    expect(after.y).toBeCloseTo(before.y - 80, 0);
  });

  test('dragging from a board card pans rather than entering it', async ({
    page,
  }) => {
    await page.goto(ocaml.url);
    const before = await cardCenter({ page, board: ocamlNotes });

    await drag({ page, from: before, by: { x: 150, y: 80 } });

    const after = await cardCenter({ page, board: ocamlNotes });
    expect(after.x).toBeCloseTo(before.x + 150, 0);
    expect(after.y).toBeCloseTo(before.y + 80, 0);
    await expect(page).toHaveURL(ocaml.url);
  });

  test('a mouse drag on a text card selects its text rather than panning', async ({
    page,
  }) => {
    await page.goto(haskell.url);
    const text = page.getByText('Haskell is lazy');
    const before = await text.boundingBox();

    await drag({
      page,
      from: { x: before!.x + 5, y: before!.y + 10 },
      by: { x: 200, y: 0 },
    });

    expect(await page.evaluate(() => getSelection()?.toString())).not.toBe('');
    expect(await text.boundingBox()).toEqual(before);
  });

  test('panning stops at an edge, with some of the board still in view', async ({
    page,
  }) => {
    await page.clock.install();
    await page.goto(ocaml.url);

    await scrollToEdge({ page });

    await expect(boardCard({ page, board: ocamlNotes })).toBeInViewport();
    const atEdge = await cardCenter({ page, board: ocamlNotes });
    await scrollToEdge({ page });
    expect(await cardCenter({ page, board: ocamlNotes })).toEqual(atEdge);
  });

  test('pushing past an edge stretches the board, which then springs back', async ({
    page,
  }) => {
    await page.clock.install();
    await page.goto(ocaml.url);
    await scrollToEdge({ page });
    const atEdge = await cardCenter({ page, board: ocamlNotes });

    await scrollBoard({ page, x: -40, y: 0 });

    const stretched = await cardCenter({ page, board: ocamlNotes });
    expect(stretched.x).toBeGreaterThan(atEdge.x + 1);
    await settle({ page });
    expect(await cardCenter({ page, board: ocamlNotes })).toEqual(atEdge);
  });

  test("trackpad momentum past an edge doesn't push, so the board bounces back", async ({
    page,
  }) => {
    await page.clock.install();
    await page.goto(ocaml.url);
    await scrollToEdge({ page });
    const atEdge = await cardCenter({ page, board: ocamlNotes });

    // Momentum: scrolling that slows down over half a second, a frame apart.
    for (let speed = 40; speed >= 10; speed--) {
      await scrollBoard({ page, x: -speed, y: 0 });
      await page.clock.runFor(16);
    }

    expect(await cardCenter({ page, board: ocamlNotes })).toEqual(atEdge);
  });

  test.describe('with reduced motion', () => {
    test.use({ reducedMotion: 'reduce' });

    test('the board stops at an edge without stretching', async ({ page }) => {
      await page.clock.install();
      await page.goto(ocaml.url);
      await scrollToEdge({ page });
      const atEdge = await cardCenter({ page, board: ocamlNotes });

      await scrollBoard({ page, x: -40, y: 0 });

      expect(await cardCenter({ page, board: ocamlNotes })).toEqual(atEdge);
    });
  });
});

/**
 * Scrolls left until the board's left edge stops it, and lets the board
 * settle.
 */
const scrollToEdge = async ({ page }: { page: Page }) => {
  await scrollBoard({ page, x: -5000, y: 0 });
  await settle({ page });
};

/**
 * Runs the page's clock, installed by the test, long enough for a stretched
 * board to spring back.
 */
const settle = async ({ page }: { page: Page }) => page.clock.runFor(1000);
