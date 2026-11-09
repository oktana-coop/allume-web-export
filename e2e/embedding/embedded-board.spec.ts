import { expect, test } from '@playwright/test';

import { expectZoomLevel } from '../camera/helpers';
import { languages, paradigms } from '../shared/boards';
import { boardCard, enterBoard, expectHeading } from '../shared/helpers';
import { embedBoard } from './helpers';

test.describe("a board's view in a site's page", () => {
  test('sets itself up', async ({ page }) => {
    const sitePage = await embedBoard({ page, board: languages });
    await page.goto(sitePage);

    await page.keyboard.press('0');
    await page.getByRole('button', { name: 'Zoom in' }).click();

    await expectZoomLevel({ page, level: '125%' });
  });

  test('leads to the boards its cards are for', async ({ page }) => {
    const sitePage = await embedBoard({ page, board: languages });
    await page.goto(sitePage);

    await enterBoard({ page, board: paradigms });

    await expectHeading({ page, board: paradigms });
  });

  test("keeps its styles off the site's page", async ({ page }) => {
    const sitePage = await embedBoard({ page, board: languages });

    await page.goto(sitePage);

    await expect(page.locator('body')).toHaveCSS(
      'background-color',
      'rgba(0, 0, 0, 0)'
    );
  });

  test("keeps the site's classes off its cards", async ({ page }) => {
    const sitePage = await embedBoard({ page, board: languages });

    await page.goto(sitePage);

    // The site's rule for its own .card class would give them a border.
    await expect(boardCard({ page, board: paradigms })).toHaveCSS(
      'border-top-width',
      '0px'
    );
  });
});
