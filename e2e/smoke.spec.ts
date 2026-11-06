import { expect, test } from '@playwright/test';

import { paradigms } from './shared/boards';

test('the site opens on the exported board', async ({ page }) => {
  await page.goto('/');

  await expect(page).toHaveTitle('Languages');
  await expect(page.getByRole('heading', { level: 1 })).toHaveText('Languages');
});

test('a board card opens its board', async ({ page }) => {
  await page.goto('/');

  await page.getByRole('link', { name: 'Paradigms', exact: true }).click();

  await expect(page).toHaveURL(paradigms.url);
  await expect(page).toHaveTitle('Paradigms | Languages');
  await expect(page.getByRole('heading', { level: 1 })).toHaveText('Paradigms');
});
