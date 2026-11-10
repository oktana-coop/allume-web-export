import { expect, test } from '@playwright/test';

import {
  families,
  functional,
  haskell,
  haskellNotes,
  mlFamily,
} from '../shared/boards';
import {
  boardCard,
  enterBoard,
  expectCardCentered,
  scrollBoard,
} from '../shared/helpers';
import { expectFullyInView, expectZoomLevel } from './helpers';

test.describe('starting view', () => {
  test('a first visit opens the board at 100% from its top left', async ({
    page,
  }) => {
    // Haskell is too wide to fit at 100%, and Notes is its top left card.
    await page.goto(haskell.url);

    await expectZoomLevel({ page, level: '100%' });
    await expectFullyInView({ card: boardCard({ page, board: haskellNotes }) });
  });

  test("a first visit frames the titles of the board's top cards", async ({
    page,
  }) => {
    // ML family's card is at the top of Families, with its title above it.
    await page.goto(families.url);

    await expectFullyInView({
      card: boardCard({ page, board: mlFamily }).getByText(mlFamily.label, {
        exact: true,
      }),
    });
  });

  test("shows the board even when the viewer doesn't run", async ({ page }) => {
    await page.route('**/allume.js', (route) => route.abort());

    await page.goto(haskell.url);

    // Hidden at first, waiting for the viewer to set the camera.
    await expect(boardCard({ page, board: haskellNotes })).toBeHidden();
    await expect(boardCard({ page, board: haskellNotes })).toBeVisible({
      timeout: 5_000,
    });
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

  test('changing the URL to a card on the open board centers the card', async ({
    page,
  }) => {
    await page.goto(functional.url);
    await scrollBoard({ page, x: 300, y: 200 });

    // The same page, so only its hash changes, without loading it again.
    await page.goto(`${functional.url}#card-${haskell.id}`);

    await expectCardCentered({ page, board: haskell });
  });
});
