import { expect, type Locator, type Page } from '@playwright/test';

import { type Board } from '../shared/boards';
import {
  enterBoard,
  expectHeading,
  openLinkedCardMenu,
} from '../shared/helpers';

/**
 * Enters each board in the path in turn, each through its card on the one
 * before.
 */
export const enterBoardsInPath = async ({
  page,
  path,
}: {
  page: Page;
  path: Board[];
}) => {
  for (const board of path) {
    await enterBoard({ page, board });
  }
};

/**
 * Opens the "Appears in N boards" menu of a board's card, follows it to
 * another board the card is on, and waits for that board's page, at the card.
 */
export const jumpToLinkedCard = async ({
  page,
  card,
  board,
}: {
  page: Page;
  card: Board;
  board: Board;
}) => {
  const menu = await openLinkedCardMenu({ page, card });
  await menu.getByRole('link', { name: board.label, exact: true }).click();
  await expect(page).toHaveURL(`${board.url}#card-${card.id}`);
};

/**
 * Checks that the page is the board's, with its heading, and that the
 * breadcrumbs link to the ancestors, from the root.
 */
export const expectBoard = async ({
  page,
  board,
  ancestors,
}: {
  page: Page;
  board: Board;
  ancestors: Board[];
}) => {
  const links = page
    .getByRole('navigation', { name: 'Breadcrumbs' })
    .getByRole('link');

  await expect(page).toHaveURL((url) => url.pathname === board.url);
  await expectHeading({ page, board });
  await expect(links).toHaveText(ancestors.map((ancestor) => ancestor.label));
  expect(await linkURLs({ links })).toEqual(
    ancestors.map((ancestor) => ancestor.url)
  );
};

/**
 * The URLs the links lead to, from the site's root, such as
 * `/haskell-zkdb1w.html`, to compare with boards' URLs. The browser resolves
 * them, since the pages link relatively and the viewer's breadcrumbs
 * absolutely.
 */
const linkURLs = async ({ links }: { links: Locator }) =>
  links.evaluateAll((elements) =>
    elements.map(
      (element) => new URL((element as HTMLAnchorElement).href).pathname
    )
  );
