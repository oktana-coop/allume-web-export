import { expect, test, type Page } from '@playwright/test';

import { haskell, haskellNotes, ocaml, ocamlNotes } from '../shared/boards';
import {
  boardCard,
  cardCenter,
  scrollBoard,
  viewCenter,
} from '../shared/helpers';
import { expectZoomLevel } from './helpers';

// OCaml opens at 100%, so its zoom levels are round numbers. Haskell is too
// wide to fit at 100%, so fitting it differs from 100%.
test.describe('zoom', () => {
  test('+ and = zoom in by a quarter, and - zooms back out', async ({
    page,
  }) => {
    await page.goto(ocaml.url);

    await page.keyboard.press('+');
    await expectZoomLevel({ page, level: '125%' });
    await page.keyboard.press('=');
    await expectZoomLevel({ page, level: '156%' });
    await page.keyboard.press('-');
    await expectZoomLevel({ page, level: '125%' });
  });

  test('0 shows the board at 100%', async ({ page }) => {
    await page.goto(haskell.url);

    await page.keyboard.press('0');

    await expectZoomLevel({ page, level: '100%' });
  });

  test('with Ctrl or Cmd, the keys zoom the board too', async ({ page }) => {
    await page.goto(ocaml.url);

    await page.keyboard.press('ControlOrMeta+=');
    await expectZoomLevel({ page, level: '125%' });
    await page.keyboard.press('ControlOrMeta+-');
    await expectZoomLevel({ page, level: '100%' });
    await page.keyboard.press('ControlOrMeta+=');
    await page.keyboard.press('ControlOrMeta+0');
    await expectZoomLevel({ page, level: '100%' });
  });

  test('Shift+1 frames the whole board, as on a first visit', async ({
    page,
  }) => {
    await page.goto(haskell.url);
    const card = boardCard({ page, board: haskellNotes });
    const firstVisit = await card.boundingBox();
    await page.keyboard.press('+');
    await scrollBoard({ page, x: 100, y: 50 });

    await page.keyboard.press('Shift+Digit1');

    expect(await card.boundingBox()).toEqual(firstVisit);
  });

  test('the toolbar zooms in and out like + and -', async ({ page }) => {
    await page.goto(ocaml.url);

    await zoomButton({ page, name: 'Zoom in' }).click();
    await expectZoomLevel({ page, level: '125%' });
    await zoomButton({ page, name: 'Zoom out' }).click();
    await expectZoomLevel({ page, level: '100%' });
  });

  test("the toolbar's Fit frames the whole board, as on a first visit", async ({
    page,
  }) => {
    await page.goto(haskell.url);
    const card = boardCard({ page, board: haskellNotes });
    const firstVisit = await card.boundingBox();
    await page.keyboard.press('+');
    await scrollBoard({ page, x: 100, y: 50 });

    await zoomButton({ page, name: 'Fit' }).click();

    expect(await card.boundingBox()).toEqual(firstVisit);
  });

  test('zooming keeps the middle of the view in place', async ({ page }) => {
    await page.goto(ocaml.url);
    const view = await viewCenter({ page });
    const before = await cardCenter({ page, board: ocamlNotes });

    await page.keyboard.press('+');

    // The card moves away from the middle as much as it grows.
    const after = await cardCenter({ page, board: ocamlNotes });
    expect(after.x - view.x).toBeCloseTo((before.x - view.x) * 1.25, 0);
    expect(after.y - view.y).toBeCloseTo((before.y - view.y) * 1.25, 0);
  });

  test('zooming in stops at 400%', async ({ page }) => {
    await page.goto(ocaml.url);

    await pressTimes({ page, key: '+', times: 10 });

    await expectZoomLevel({ page, level: '400%' });
  });

  test('zooming out stops at 50%', async ({ page }) => {
    await page.goto(ocaml.url);

    await pressTimes({ page, key: '-', times: 10 });

    await expectZoomLevel({ page, level: '50%' });
  });

  test.describe('in a small window', () => {
    test.use({ viewport: { width: 640, height: 480 } });

    test('zooming out stops below 50% when the board only fits smaller', async ({
      page,
    }) => {
      // Haskell fits a 640 × 480 window at 41%.
      await page.goto(haskell.url);

      await pressTimes({ page, key: '-', times: 10 });

      await expectZoomLevel({ page, level: '41%' });
    });
  });

  test('Ctrl+scroll, as a trackpad pinch sends it, zooms at the pointer', async ({
    page,
  }) => {
    await page.goto(ocaml.url);
    const card = await cardCenter({ page, board: ocamlNotes });

    await page.mouse.move(card.x, card.y);
    await page.keyboard.down('Control');
    await page.mouse.wheel(0, -50);
    await page.keyboard.up('Control');

    // A pinch's steps are capped at 50 pixels, and each zooms by e^(pixels/100).
    await expectZoomLevel({ page, level: '165%' });
    const after = await cardCenter({ page, board: ocamlNotes });
    expect(after.x).toBeCloseTo(card.x, 0);
    expect(after.y).toBeCloseTo(card.y, 0);
  });
});

const zoomButton = ({ page, name }: { page: Page; name: string }) =>
  page
    .getByRole('toolbar', { name: 'Zoom' })
    .getByRole('button', { name, exact: true });

const pressTimes = async ({
  page,
  key,
  times,
}: {
  page: Page;
  key: string;
  times: number;
}) => {
  for (let time = 0; time < times; time++) {
    await page.keyboard.press(key);
  }
};
