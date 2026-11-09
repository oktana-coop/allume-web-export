import { expect, test, type Locator, type Page } from '@playwright/test';

import { expectZoomLevel } from '../camera/helpers';
import { functional, languages, paradigms } from '../shared/boards';
import {
  boardCard,
  boundingBox,
  enterBoard,
  expectHeading,
  viewport,
} from '../shared/helpers';
import { embedBoard, siteBox } from './helpers';

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

  test('fills its box, its bar above its viewport', async ({ page }) => {
    const sitePage = await embedBoard({ page, board: languages });

    await page.goto(sitePage);

    const box = await boundingBox({ of: siteBox({ page }) });
    const bar = await boundingBox({ of: page.locator('.allume-bar') });
    expect(bar).toMatchObject({ x: box.x, y: box.y, width: box.width });
    expect(await boundingBox({ of: viewport({ page }) })).toEqual({
      x: box.x,
      y: bar.y + bar.height,
      width: box.width,
      height: box.height - bar.height,
    });
  });

  test('frames the whole board in its box on a first visit', async ({
    page,
  }) => {
    const sitePage = await embedBoard({ page, board: languages });

    await page.goto(sitePage);

    const box = await boundingBox({ of: siteBox({ page }) });
    for (const card of await viewport({ page })
      .locator('[id^="card-"]')
      .all()) {
      const frame = await boundingBox({ of: card });
      // Scaling leaves rounding errors of less than a pixel.
      expect(frame.x).toBeGreaterThan(box.x - 1);
      expect(frame.y).toBeGreaterThan(box.y - 1);
      expect(frame.x + frame.width).toBeLessThan(box.x + box.width + 1);
      expect(frame.y + frame.height).toBeLessThan(box.y + box.height + 1);
    }
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

  test("keeps the site's element styles off its own", async ({ page }) => {
    await page.goto(functional.url);
    const own = await elementStyles({ page });
    const sitePage = await embedBoard({ page, board: functional });

    await page.goto(sitePage);

    expect(await elementStyles({ page })).toEqual(own);
  });
});

/**
 * The computed styles of the view's elements that the site's rules for its own
 * elements reach, for the properties those rules set. The font family is left
 * out, since the view takes the page's.
 */
const elementStyles = ({ page }: { page: Page }) =>
  Promise.all([
    // body, which the view's text inherits from, p, and the reset's margins
    computedStyles({
      element: viewport({ page }).locator('.allume-text-block p').first(),
      properties: [
        'font-size',
        'line-height',
        'color',
        'margin-top',
        'margin-bottom',
      ],
    }),
    // h1
    computedStyles({
      element: page.getByRole('heading', { level: 1 }),
      properties: ['font-size', 'font-weight'],
    }),
    // a
    computedStyles({
      element: page
        .getByRole('navigation', { name: 'Breadcrumbs' })
        .getByRole('link')
        .first(),
      properties: ['color', 'text-decoration-line'],
    }),
    // img
    computedStyles({
      element: viewport({ page }).locator('img').first(),
      properties: ['display', 'vertical-align', 'max-width', 'height'],
    }),
    // svg
    computedStyles({
      element: viewport({ page }).locator('svg').first(),
      properties: ['display', 'vertical-align'],
    }),
    // button, and the reset's padding and border
    computedStyles({
      element: page.getByRole('button', { name: 'Zoom in' }),
      properties: [
        'background-color',
        'color',
        'font-size',
        'line-height',
        'padding-top',
        'border-top-width',
      ],
    }),
  ]);

const computedStyles = ({
  element,
  properties,
}: {
  element: Locator;
  properties: string[];
}) =>
  element.evaluate(
    (element, properties) =>
      Object.fromEntries(
        properties.map((property) => [
          property,
          getComputedStyle(element).getPropertyValue(property),
        ])
      ),
    properties
  );
