import { expect, type Locator, type Page } from '@playwright/test';

import { type Point } from '../shared/helpers';

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

/** Drags the mouse from the point on the screen, by the distances. */
export const drag = async ({
  page,
  from,
  by,
}: {
  page: Page;
  from: Point;
  by: Point;
}) => {
  await page.mouse.move(from.x, from.y);
  await page.mouse.down();
  await page.mouse.move(from.x + by.x, from.y + by.y, { steps: 5 });
  await page.mouse.up();
};
