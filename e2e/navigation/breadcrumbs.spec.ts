import { test } from '@playwright/test';

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

test.describe('breadcrumbs', () => {
  test('a board opened directly shows its primary ancestors', async ({
    page,
  }) => {
    await page.goto(haskell.url);

    await expectBoard({
      page,
      board: haskell,
      ancestors: [languages, paradigms, functional],
    });
  });

  test('entering a board adds it after the board it was entered from', async ({
    page,
  }) => {
    await page.goto(languages.url);

    await enterBoardsInPath({ page, path: [families, mlFamily, haskell] });

    await expectBoard({
      page,
      board: haskell,
      ancestors: [languages, families, mlFamily],
    });
  });

  test('going up a breadcrumb keeps the ones before it', async ({ page }) => {
    await page.goto(languages.url);
    await enterBoardsInPath({
      page,
      path: [families, mlFamily, haskell, haskellNotes],
    });

    await page
      .getByRole('navigation', { name: 'Breadcrumbs' })
      .getByRole('link', { name: haskell.label, exact: true })
      .click();

    await expectBoard({
      page,
      board: haskell,
      ancestors: [languages, families, mlFamily],
    });
  });

  test('going back to a board shows the breadcrumbs it was entered with', async ({
    page,
  }) => {
    await page.goto(languages.url);
    await enterBoardsInPath({
      page,
      path: [families, mlFamily, haskell, haskellNotes],
    });

    await page.goBack();

    await expectBoard({
      page,
      board: haskell,
      ancestors: [languages, families, mlFamily],
    });
  });

  test('a linked card jump shows the primary ancestors of the board it lands on', async ({
    page,
  }) => {
    await page.goto(languages.url);
    await enterBoardsInPath({ page, path: [families, mlFamily] });

    await jumpToLinkedCard({ page, card: haskell, board: functional });

    await expectBoard({
      page,
      board: functional,
      ancestors: [languages, paradigms],
    });
  });

  test('a board opened in a new tab shows its primary ancestors', async ({
    page,
  }) => {
    await page.goto(languages.url);
    await enterBoardsInPath({ page, path: [families, mlFamily] });

    const [tab] = await Promise.all([
      page.context().waitForEvent('page'),
      page
        .getByRole('main')
        .getByRole('link', { name: haskell.label, exact: true })
        .click({ modifiers: ['ControlOrMeta'] }),
    ]);

    await expectBoard({
      page: tab,
      board: haskell,
      ancestors: [languages, paradigms, functional],
    });
  });
});
