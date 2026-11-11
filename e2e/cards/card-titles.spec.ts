import { expect, test, type Page } from '@playwright/test';

import { haskell, monoids } from '../shared/boards';
import { boundingBox } from '../shared/helpers';

test.describe('card titles', () => {
  test("a note's label shows above it", async ({ page }) => {
    await page.goto(haskell.url);

    const title = page.getByText('Laziness', { exact: true });
    const text = page.getByText(/^Haskell is lazy/);

    await expect(title).toBeVisible();
    const [titleBox, textBox] = await Promise.all([
      boundingBox({ of: title }),
      boundingBox({ of: text }),
    ]);
    expect(titleBox.y + titleBox.height).toBeLessThanOrEqual(textBox.y);
  });

  test('a cut-off title shows whole in a tooltip on hover', async ({
    page,
  }) => {
    await page.goto(monoids.url);

    await cutOffTitle({ page }).hover();

    await expect(page.getByRole('tooltip')).toHaveText(CUT_OFF_LABEL);
  });

  test("a tooltip's title can be selected and copied", async ({ page }) => {
    await page.goto(monoids.url);
    await cutOffTitle({ page }).hover();
    const tooltip = page.getByRole('tooltip');

    await tooltip.hover();
    await tooltip.click({ clickCount: 3 });
    await page.keyboard.press('ControlOrMeta+c');

    expect(await page.evaluate(() => navigator.clipboard.readText())).toBe(
      CUT_OFF_LABEL
    );
  });

  test('a title that fits shows no tooltip', async ({ page }) => {
    await page.goto(monoids.url);

    await page
      .getByText(
        'Strings under concatenation, with the empty string as the identity.',
        { exact: true }
      )
      .hover();

    await expect(page.getByRole('tooltip')).toBeHidden();
  });
});

// An image's label on Monoids, too long for its card.
const CUT_OFF_LABEL =
  'A monoid is a set with an associative operation and an identity ' +
  'element. Addition over the integers,';

const cutOffTitle = ({ page }: { page: Page }) =>
  page.locator('.allume-card-title').getByText(CUT_OFF_LABEL, { exact: true });
