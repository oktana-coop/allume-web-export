import { expect, type Locator, type Page } from '@playwright/test';

import { type Board } from './boards';

export type Point = { x: number; y: number };

/** The part of the page that shows the board's canvas, below the bar. */
export const viewport = ({ page }: { page: Page }) =>
  page.locator('.allume-viewport');

/**
 * The board's card on the current page's board. Other cards' previews also
 * show it, but without the `card-` id that only the board's own cards have.
 */
export const boardCard = ({ page, board }: { page: Page; board: Board }) =>
  page.locator(`#card-${board.id}`);

/**
 * Waits for the page a link led to, until the viewer has set it up. The URL
 * changes as the page starts loading, before the viewer's script at its end
 * has run, so a key pressed then would go unheard.
 */
export const expectArrivalAt = async ({
  page,
  url,
}: {
  page: Page;
  url: string;
}) => {
  await expect(page).toHaveURL(url);
  await page.waitForLoadState('domcontentloaded');
};

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
  await viewport({ page })
    .getByRole('link', { name: board.label, exact: true })
    .click();
  await expectArrivalAt({ page, url: board.url });
};

/** The "Appears in N boards" button of a board's card on the current board. */
export const linkedCardButton = ({ page, card }: { page: Page; card: Board }) =>
  boardCard({ page, board: card }).getByRole('button', {
    name: /^Appears in \d+ boards$/,
  });

/**
 * Opens a menu with its button, and returns the menu. The viewer places an open
 * menu on its `toggle` event, which comes after the click, so this waits for
 * the event too, listening from before the click.
 */
export const openMenu = async ({
  button,
  menu,
}: {
  button: Locator;
  menu: Locator;
}) => {
  const toggle = await menu.evaluateHandle((element) => ({
    fired: new Promise<void>((resolve) =>
      element.addEventListener('toggle', () => resolve(), { once: true })
    ),
  }));

  await button.click();
  await toggle.evaluate(({ fired }) => fired);
  await expect(menu).toBeVisible();

  return menu;
};

/**
 * Opens the "Appears in N boards" menu of a board's card on the current board,
 * and returns the menu.
 */
export const openLinkedCardMenu = async ({
  page,
  card,
}: {
  page: Page;
  card: Board;
}) =>
  openMenu({
    button: linkedCardButton({ page, card }),
    menu: page.locator(`#allume-linked-${card.id}`),
  });

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

/**
 * The element's bounding box, as Playwright gives it, failing if the element
 * isn't shown.
 */
export const boundingBox = async ({ of: element }: { of: Locator }) => {
  const box = await element.boundingBox();
  if (!box) throw new Error(`${element} isn't shown`);

  return box;
};

/** The center of the board's card, on the screen. */
export const cardCenter = async ({
  page,
  board,
}: {
  page: Page;
  board: Board;
}) => center({ of: boardCard({ page, board }) });

/** The center of the viewport. */
export const viewportCenter = async ({ page }: { page: Page }) =>
  center({ of: viewport({ page }) });

export const expectCardCentered = async ({
  page,
  board,
}: {
  page: Page;
  board: Board;
}) => {
  const card = await cardCenter({ page, board });
  const center = await viewportCenter({ page });

  expect(card.x).toBeCloseTo(center.x, 0);
  expect(card.y).toBeCloseTo(center.y, 0);
};

/**
 * Scrolls by the amounts, with the mouse over the viewport's center. The mouse
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
  const middle = await viewportCenter({ page });

  await page.mouse.move(middle.x, middle.y);
  await page.mouse.wheel(x, y);
};

export const center = async ({
  of: element,
}: {
  of: Locator;
}): Promise<Point> => {
  const box = await boundingBox({ of: element });

  return { x: box.x + box.width / 2, y: box.y + box.height / 2 };
};
