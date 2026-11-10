import { expect, test, type Page } from '@playwright/test';

import { languages, paradigms, type Board } from '../shared/boards';
import { boardCard } from '../shared/helpers';

test.describe('board previews', () => {
  test("a board card shows its board's preview", async ({ page }) => {
    await page.goto(languages.url);

    const preview = shownPreview({ page, board: paradigms });

    await expect(preview).toHaveCount(1);
    await expect
      .poll(() =>
        preview.evaluate((image) => (image as HTMLImageElement).naturalWidth)
      )
      .toBeGreaterThan(0);
  });

  test("a board card's preview follows the page into dark mode", async ({
    page,
  }) => {
    await page.goto(languages.url);
    await expect(shownPreview({ page, board: paradigms })).toHaveAttribute(
      'src',
      /-light\.jpg$/
    );

    // As a site's theme switch would.
    await page.addStyleTag({
      content: ':root { color-scheme: dark !important; }',
    });

    await expect(shownPreview({ page, board: paradigms })).toHaveAttribute(
      'src',
      /-dark\.jpg$/
    );
  });
});

/** The preview the board's card shows, of those drawn in each theme. */
const shownPreview = ({ page, board }: { page: Page; board: Board }) =>
  boardCard({ page, board }).locator('img:visible');
