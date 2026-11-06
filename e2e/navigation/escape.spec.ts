import { expect, test } from '@playwright/test';

import {
  families,
  functional,
  haskell,
  haskellNotes,
  languages,
  mlFamily,
  paradigms,
} from '../shared/boards';
import { enterBoardsInPath, expectBoard, jumpToLinkedCard } from './helpers';

test.describe('escape', () => {
  test('after entering a board, goes back the way it came', async ({
    page,
  }) => {
    await page.goto(languages.url);
    await enterBoardsInPath({ page, path: [families, mlFamily, haskell] });

    await page.keyboard.press('Escape');

    await expectBoard({
      page,
      board: mlFamily,
      ancestors: [languages, families],
    });
    // Going up would land on the same board, but only going back lets the
    // browser go forward again.
    await page.goForward();
    await expectBoard({
      page,
      board: haskell,
      ancestors: [languages, families, mlFamily],
    });
  });

  test('after a linked card jump, goes back to the board jumped from', async ({
    page,
  }) => {
    await page.goto(languages.url);
    await enterBoardsInPath({ page, path: [families, mlFamily] });
    await jumpToLinkedCard({ page, card: haskell, board: functional });

    await page.keyboard.press('Escape');

    await expectBoard({
      page,
      board: mlFamily,
      ancestors: [languages, families],
    });
  });

  test('on a board opened directly, goes up to its primary parent', async ({
    page,
  }) => {
    await page.goto(haskell.url);

    await page.keyboard.press('Escape');

    await expectBoard({
      page,
      board: functional,
      ancestors: [languages, paradigms],
    });
  });

  test('after going up a breadcrumb, goes up again rather than back', async ({
    page,
  }) => {
    await page.goto(languages.url);
    await enterBoardsInPath({
      page,
      path: [families, mlFamily, haskell, haskellNotes],
    });
    await page
      .getByRole('navigation', { name: 'Breadcrumbs' })
      .getByRole('link', { name: mlFamily.label, exact: true })
      .click();

    await page.keyboard.press('Escape');

    await expectBoard({ page, board: families, ancestors: [languages] });
  });

  test('on the root board, does nothing', async ({ page }) => {
    await page.goto(languages.url);

    await page.keyboard.press('Escape');

    await expectBoard({ page, board: languages, ancestors: [] });
  });

  test('closes an open menu before anything else', async ({ page }) => {
    await page.goto(haskell.url);
    await page
      .getByRole('navigation', { name: 'Breadcrumbs' })
      .getByRole('button', { name: 'Appears in 2 boards' })
      .click();
    const menu = page.locator('#linked-self');
    await expect(menu).toBeVisible();

    await page.keyboard.press('Escape');

    await expect(menu).toBeHidden();
    await expectBoard({
      page,
      board: haskell,
      ancestors: [languages, paradigms, functional],
    });
    await page.keyboard.press('Escape');
    await expectBoard({
      page,
      board: functional,
      ancestors: [languages, paradigms],
    });
  });
});
