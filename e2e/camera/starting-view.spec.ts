import { expect, test } from '@playwright/test';

import { functional, haskell, haskellNotes } from '../shared/boards';
import {
  boardCard,
  enterBoard,
  expectCardCentered,
  scrollBoard,
} from '../shared/helpers';
import { expectFullyInView, expectZoomLevel } from './helpers';

test.describe('starting view', () => {
  test('a first visit frames the whole board', async ({ page }) => {
    // Haskell is too wide to fit at 100%.
    await page.goto(haskell.url);

    const cards = await page.getByRole('main').locator('[id^="card-"]').all();
    expect(cards).toHaveLength(5);
    for (const card of cards) {
      await expectFullyInView({ card });
    }
  });

  test('a board reopens where it was left in the session', async ({ page }) => {
    await page.goto(haskell.url);
    await page.keyboard.press('+');
    await scrollBoard({ page, x: 100, y: 50 });
    const card = boardCard({ page, board: haskellNotes });
    const leftAt = await card.boundingBox();

    await page
      .getByRole('navigation', { name: 'Breadcrumbs' })
      .getByRole('link', { name: functional.label, exact: true })
      .click();
    await enterBoard({ page, board: haskell });

    expect(await card.boundingBox()).toEqual(leftAt);
  });

  test('each board keeps its own camera', async ({ page }) => {
    await page.goto(haskell.url);
    await page.keyboard.press('+');

    await enterBoard({ page, board: haskellNotes });

    // How a first visit opens Notes, which fits at 100%.
    await expectZoomLevel({ page, level: '100%' });
  });

  test('a link to a card centers the card, rather than where the board was left', async ({
    page,
  }) => {
    await page.goto(functional.url);
    await scrollBoard({ page, x: 300, y: 200 });
    await enterBoard({ page, board: haskell });

    await page.goto(`${functional.url}#card-${haskell.id}`);

    await expectCardCentered({ page, board: haskell });
  });
});
