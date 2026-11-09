import { expect, test, type Page } from '@playwright/test';

import { functional, haskell, languages } from '../shared/boards';

test.describe('copy buttons', () => {
  // The clipboard is the browser's, so the tests a worker runs share it.
  test.beforeEach(async ({ page }) => {
    await page.goto(languages.url);
    await page.evaluate(() => navigator.clipboard.writeText(''));
  });

  test("a note's button copies its text", async ({ page }) => {
    await page.goto(haskell.url);

    await copyButton({ page, text: 'Haskell is lazy' }).click();

    await expectClipboard({
      page,
      text:
        'Haskell is lazy: an expression is evaluated only when its value is needed.\n\n' +
        'This makes infinite lists practical, as in take 5 [1..].',
    });
  });

  test("a text block's button copies it with a line per paragraph", async ({
    page,
  }) => {
    await page.goto(functional.url);

    await copyButton({ page, text: 'Pure functions' }).click();

    await expectClipboard({
      page,
      text:
        'Pure functions\n' +
        'Same input, same output, no side effects.\n' +
        'Laziness\n' +
        'Evaluate only what is needed.',
    });
  });

  test("a comment's button copies its text, without its author or date", async ({
    page,
  }) => {
    await page.goto(haskell.url);

    await copyButton({ page, text: 'Yes, the type classes PDF' }).click();

    await expectClipboard({
      page,
      text: 'Yes, the type classes PDF in Reading covers them.',
    });
  });

  test('the button reads "Copied" for a moment, then "Copy text" again', async ({
    page,
  }) => {
    await page.clock.install();
    await page.goto(haskell.url);
    const button = boardItem({ page, text: 'Haskell is lazy' }).getByRole(
      'button'
    );

    await button.click();

    await expect(button).toHaveAccessibleName('Copied');
    await page.clock.runFor(1500);
    await expect(button).toHaveAccessibleName('Copy text');
  });

  test('copying again keeps "Copied" for a moment from the second copy', async ({
    page,
  }) => {
    await page.clock.install();
    await page.goto(haskell.url);
    const button = boardItem({ page, text: 'Haskell is lazy' }).getByRole(
      'button'
    );
    // Each copy is waited for, since copying is asynchronous: the first by its
    // label, and the second by its text arriving in the emptied clipboard.
    await button.click();
    await expect(button).toHaveAccessibleName('Copied');
    await page.clock.runFor(1000);
    await page.evaluate(() => navigator.clipboard.writeText(''));

    await button.click();
    await expect
      .poll(() => page.evaluate(() => navigator.clipboard.readText()))
      .not.toBe('');
    await page.clock.runFor(1000);

    await expect(button).toHaveAccessibleName('Copied');
    await page.clock.runFor(500);
    await expect(button).toHaveAccessibleName('Copy text');
  });

  test('without the Clipboard API, copying still works', async ({ page }) => {
    // As on a site served over plain HTTP, where browsers refuse the API.
    await page.addInitScript(() => {
      navigator.clipboard.writeText = () =>
        Promise.reject(new DOMException('Refused', 'NotAllowedError'));
    });
    await page.goto(haskell.url);

    await copyButton({ page, text: 'Yes, the type classes PDF' }).click();

    await expectClipboard({
      page,
      text: 'Yes, the type classes PDF in Reading covers them.',
    });
  });
});

/**
 * The card, text block or comment on the current page's board that shows the
 * text.
 */
const boardItem = ({ page, text }: { page: Page; text: string }) =>
  page.locator('.allume-canvas > *', { hasText: text });

/** The copy button of the item on the board that shows the text. */
const copyButton = ({ page, text }: { page: Page; text: string }) =>
  boardItem({ page, text }).getByRole('button', { name: 'Copy text' });

/**
 * Checks the clipboard holds the text, waiting for the copying, which is
 * asynchronous.
 */
const expectClipboard = async ({ page, text }: { page: Page; text: string }) =>
  expect
    .poll(() => page.evaluate(() => navigator.clipboard.readText()))
    .toBe(text);
