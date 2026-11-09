import { expect, test, type Page } from '@playwright/test';

import * as boards from './shared/boards';
import { boardCard, expectHeading } from './shared/helpers';

// The tests name the sample export's boards through `shared/boards.ts`, so
// these check that it still matches the site built from the export.
test.describe("the sample export's boards", () => {
  test('languages is the root board, at its URL', async ({ page }) => {
    await page.goto(boards.languages.url);

    await expectHeading({ page, board: boards.languages });
    await expect(primaryParentLink({ page })).toHaveCount(0);
  });

  for (const [name, board] of Object.entries(boards).filter(
    ([, board]) => board !== boards.languages
  )) {
    test(`the ${name} card opens the board at its URL`, async ({ page }) => {
      await page.goto(board.url);
      await primaryParentLink({ page }).click();

      await boardCard({ page, board }).locator('a.allume-panel').click();

      await expect(page).toHaveURL(board.url);
      await expectHeading({ page, board });
    });
  }
});

const primaryParentLink = ({ page }: { page: Page }) =>
  page.getByRole('navigation', { name: 'Breadcrumbs' }).locator('a[rel="up"]');
