import { expect, test, type Page } from '@playwright/test';

import { functional, haskell, mlFamily } from '../shared/boards';
import { enterBoard } from '../shared/helpers';

test.describe('linked card menus', () => {
  test("the heading's menu marks the board the breadcrumbs came from", async ({
    page,
  }) => {
    await page.goto(mlFamily.url);
    await enterBoard({ page, board: haskell });

    const menu = await openHeadingMenu({ page });

    await expect(menu.locator('a[aria-current="true"]')).toHaveText([
      mlFamily.label,
    ]);
  });

  test("the heading's menu of a board opened directly marks its primary parent", async ({
    page,
  }) => {
    await page.goto(haskell.url);

    const menu = await openHeadingMenu({ page });

    await expect(menu.locator('a[aria-current="true"]')).toHaveText([
      functional.label,
    ]);
  });
});

/** Opens the menu of the boards the current board is on, in its heading. */
const openHeadingMenu = async ({ page }: { page: Page }) => {
  await page
    .getByRole('navigation', { name: 'Breadcrumbs' })
    .getByRole('button', { name: /^Appears in \d+ boards$/ })
    .click();
  const menu = page.locator('#linked-self');
  await expect(menu).toBeVisible();

  return menu;
};
