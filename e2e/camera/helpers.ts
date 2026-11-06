import { expect, type Locator, type Page } from '@playwright/test';

import { type Board } from '../shared/boards';
import { boardCard } from '../shared/helpers';

type Point = { x: number; y: number };

/** Checks the zoom level the toolbar shows, such as `125%`. */
export const expectZoomLevel = async ({
  page,
  level,
}: {
  page: Page;
  level: string;
}) =>
  expect(
    page.getByRole('toolbar', { name: 'Zoom' }).getByRole('status')
  ).toHaveText(level);

/**
 * Checks the whole card is in view, give or take rounding. Scaling the board
 * leaves rounding errors, such as a card 0.9999998 in view, so a thousandth of
 * its area may be out: a sliver less than a pixel wide on any card that fits in
 * the view.
 */
export const expectFullyInView = async ({ card }: { card: Locator }) =>
  expect(card).toBeInViewport({ ratio: 0.999 });

/** The middle of the board's card, on the screen. */
export const cardCenter = async ({
  page,
  board,
}: {
  page: Page;
  board: Board;
}) => center({ of: boardCard({ page, board }) });

/** The middle of the view that shows the board, below the header. */
export const viewCenter = async ({ page }: { page: Page }) =>
  center({ of: page.getByRole('main') });

/**
 * Scrolls by the amounts, with the mouse over the middle of the view. The mouse
 * starts at the top left, over the header, where scrolling doesn't reach the
 * board.
 */
export const scrollBoard = async ({
  page,
  x,
  y,
}: {
  page: Page;
  x: number;
  y: number;
}) => {
  const middle = await viewCenter({ page });

  await page.mouse.move(middle.x, middle.y);
  await page.mouse.wheel(x, y);
};

const center = async ({ of: element }: { of: Locator }): Promise<Point> => {
  const box = await element.boundingBox();
  if (!box) throw new Error(`${element} isn't shown`);

  return { x: box.x + box.width / 2, y: box.y + box.height / 2 };
};
