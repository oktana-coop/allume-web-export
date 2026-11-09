import { expect, test } from '@playwright/test';

import { functional, paradigms } from './shared/boards';
import { expectZoomLevel } from './camera/helpers';

test('the site opens on the exported board', async ({ page }) => {
  await page.goto('/');

  await expect(page).toHaveTitle('Languages');
  await expect(page.getByRole('heading', { level: 1 })).toHaveText('Languages');
});

test("a board's page starts tabbing at its breadcrumbs", async ({ page }) => {
  await page.goto(functional.url);

  await page.keyboard.press('Tab');

  await expect(
    page
      .getByRole('navigation', { name: 'Breadcrumbs' })
      .getByRole('link', { name: 'Languages' })
  ).toBeFocused();
});

test("a board's page keeps its keys after a click on its bar", async ({
  page,
}) => {
  await page.goto('/');

  await page.getByRole('heading', { level: 1 }).click();
  await page.keyboard.press('0');

  await expectZoomLevel({ page, level: '100%' });
});

test('a board card opens its board', async ({ page }) => {
  await page.goto('/');

  await page.getByRole('link', { name: 'Paradigms', exact: true }).click();

  await expect(page).toHaveURL(paradigms.url);
  await expect(page).toHaveTitle('Paradigms | Languages');
  await expect(page.getByRole('heading', { level: 1 })).toHaveText('Paradigms');
});
