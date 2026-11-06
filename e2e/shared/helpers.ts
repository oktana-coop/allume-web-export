import { expect, type Page } from '@playwright/test';

import { type Board } from './boards';

/**
 * The board's card on the current page's board. Other cards' previews also
 * show it, but without the `card-` id that only the board's own cards have.
 */
export const boardCard = ({ page, board }: { page: Page; board: Board }) =>
  page.locator(`#card-${board.id}`);

/**
 * Enters a board through its card on the current board, and waits for its
 * page.
 */
export const enterBoard = async ({
  page,
  board,
}: {
  page: Page;
  board: Board;
}) => {
  await page
    .getByRole('main')
    .getByRole('link', { name: board.label, exact: true })
    .click();
  await expect(page).toHaveURL(board.url);
};

/**
 * Checks the page's heading is the board's label. A linked board's heading
 * also holds its menu, hidden until opened, so only the visible text counts.
 */
export const expectHeading = async ({
  page,
  board,
}: {
  page: Page;
  board: Board;
}) =>
  expect(page.getByRole('heading', { level: 1 })).toHaveText(board.label, {
    useInnerText: true,
  });
