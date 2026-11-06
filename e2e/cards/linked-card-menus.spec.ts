import { expect, test, type Locator, type Page } from '@playwright/test';

import { functional, haskell, mlFamily, paradigms } from '../shared/boards';
import {
  boundingBox,
  enterBoard,
  expectCardCentered,
  linkedCardButton,
  openLinkedCardMenu,
  openMenu,
  scrollBoard,
} from '../shared/helpers';

// Haskell's card on Functional is also on ML family.
test.describe('linked card menus', () => {
  test("a card's menu lists the boards it's on, marking the current one", async ({
    page,
  }) => {
    await page.goto(functional.url);

    const menu = await openLinkedCardMenu({ page, card: haskell });

    await expect(menu.getByRole('link')).toHaveText([
      functional.label,
      mlFamily.label,
    ]);
    await expect(markedLinks({ menu })).toHaveText([functional.label]);
  });

  test('choosing another board opens it centered on the card', async ({
    page,
  }) => {
    await page.goto(functional.url);
    const menu = await openLinkedCardMenu({ page, card: haskell });

    await menu.getByRole('link', { name: mlFamily.label, exact: true }).click();

    await expect(page).toHaveURL(`${mlFamily.url}#card-${haskell.id}`);
    await expectCardCentered({ page, board: haskell });
  });

  test('choosing the current board centers the card, without a history entry', async ({
    page,
  }) => {
    await page.goto(paradigms.url);
    await enterBoard({ page, board: functional });
    const menu = await openLinkedCardMenu({ page, card: haskell });

    await menu
      .getByRole('link', { name: functional.label, exact: true })
      .click();

    await expect(menu).toBeHidden();
    await expect(page).toHaveURL(`${functional.url}#card-${haskell.id}`);
    await expectCardCentered({ page, board: haskell });
    // Back leaves the board, rather than undoing the centering.
    await page.goBack();
    await expect(page).toHaveURL(paradigms.url);
  });

  test('a menu opens below its button', async ({ page }) => {
    await page.goto(functional.url);
    const button = await boundingBox({
      of: linkedCardButton({ page, card: haskell }),
    });

    const menu = await openLinkedCardMenu({ page, card: haskell });

    const box = await boundingBox({ of: menu });
    expect(box.y).toBeGreaterThanOrEqual(button.y + button.height);
  });

  test('a menu without room below opens above its button', async ({ page }) => {
    await page.goto(functional.url);
    // Pans the button down to 60 pixels above the bottom of the window.
    const view = await boundingBox({ of: page.getByRole('main') });
    const before = await boundingBox({
      of: linkedCardButton({ page, card: haskell }),
    });
    await scrollBoard({
      page,
      x: 0,
      y: before.y - (view.y + view.height - 60),
    });
    const button = await boundingBox({
      of: linkedCardButton({ page, card: haskell }),
    });

    const menu = await openLinkedCardMenu({ page, card: haskell });

    const box = await boundingBox({ of: menu });
    expect(box.y + box.height).toBeLessThanOrEqual(button.y);
  });

  test('scrolling the board closes an open menu', async ({ page }) => {
    await page.goto(functional.url);
    const menu = await openLinkedCardMenu({ page, card: haskell });

    await scrollBoard({ page, x: 0, y: 50 });

    await expect(menu).toBeHidden();
  });

  test("the heading's menu lists the boards the current board is on", async ({
    page,
  }) => {
    await page.goto(haskell.url);

    const menu = await openHeadingMenu({ page });

    await expect(menu.getByRole('link')).toHaveText([
      functional.label,
      mlFamily.label,
    ]);
  });

  test("the heading's menu marks the board the breadcrumbs came from", async ({
    page,
  }) => {
    await page.goto(mlFamily.url);
    await enterBoard({ page, board: haskell });

    const menu = await openHeadingMenu({ page });

    await expect(markedLinks({ menu })).toHaveText([mlFamily.label]);
  });

  test("the heading's menu of a board opened directly marks its primary parent", async ({
    page,
  }) => {
    await page.goto(haskell.url);

    const menu = await openHeadingMenu({ page });

    await expect(markedLinks({ menu })).toHaveText([functional.label]);
  });
});

/** Opens the menu of the boards the current board is on, in its heading. */
const openHeadingMenu = async ({ page }: { page: Page }) =>
  openMenu({
    button: page
      .getByRole('navigation', { name: 'Breadcrumbs' })
      .getByRole('button', { name: /^Appears in \d+ boards$/ }),
    menu: page.locator('#linked-self'),
  });

/** The menu's links marked as the current board. */
const markedLinks = ({ menu }: { menu: Locator }) =>
  menu.locator('a[aria-current="true"]');
