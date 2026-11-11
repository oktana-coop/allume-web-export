import { expect, test } from '@playwright/test';

import { functional } from '../shared/boards';

test.describe('text blocks', () => {
  test("a text block's heading reads as a heading", async ({ page }) => {
    await page.goto(functional.url);

    await expect(
      page.getByRole('heading', { name: 'Functional programming', level: 3 })
    ).toBeVisible();
  });
});
