import { expect, test, type Locator, type Page } from '@playwright/test';

import { logic } from '../shared/boards';
import { boundingBox } from '../shared/helpers';

// Logic's note is shorter than its text.
test.describe('note scrolling', () => {
  test('a note shorter than its text scrolls once clicked, rather than the board', async ({
    page,
  }) => {
    await page.goto(logic.url);
    const note = logicNote({ page });
    await note.click();
    const before = await boundingBox({ of: note });

    await page.mouse.wheel(0, 200);

    await expect.poll(() => shows({ note, edge: 'end' })).toBe(true);
    expect(await boundingBox({ of: note })).toEqual(before);
  });

  test('scrolling over a note not clicked pans the board', async ({ page }) => {
    await page.goto(logic.url);
    const note = logicNote({ page });
    await note.hover();
    const before = await boundingBox({ of: note });

    await page.mouse.wheel(0, 100);

    const after = await boundingBox({ of: note });
    expect(after.y).toBeCloseTo(before.y - 100, 0);
    expect(await shows({ note, edge: 'end' })).toBe(false);
  });

  test('a press elsewhere scrolls the note back to its top, and the board pans again', async ({
    page,
  }) => {
    await page.goto(logic.url);
    const note = await scrolledToItsEnd({ page });

    // On the empty canvas, below Logic's cards.
    await page.mouse.click(1100, 600);

    await expectLeft({ page, note });
  });

  test('Escape scrolls the note back to its top, and the board pans again', async ({
    page,
  }) => {
    await page.goto(logic.url);
    const note = await scrolledToItsEnd({ page });

    await page.keyboard.press('Escape');

    await expectLeft({ page, note });
  });
});

const logicNote = ({ page }: { page: Page }) =>
  page.getByText(/^In logic programming/);

/** Clicks Logic's note and scrolls it to its end, and returns it. */
const scrolledToItsEnd = async ({ page }: { page: Page }) => {
  const note = logicNote({ page });
  await note.click();
  await page.mouse.wheel(0, 200);
  await expect.poll(() => shows({ note, edge: 'end' })).toBe(true);

  return note;
};

/** Checks the note shows its top again, and scrolling over it pans. */
const expectLeft = async ({ page, note }: { page: Page; note: Locator }) => {
  await expect.poll(() => shows({ note, edge: 'start' })).toBe(true);

  await note.hover();
  const before = await boundingBox({ of: note });
  await page.mouse.wheel(0, 100);
  expect((await boundingBox({ of: note })).y).toBeCloseTo(before.y - 100, 0);
};

/** Whether the note's first or last character shows within the note. */
const shows = async ({
  note,
  edge,
}: {
  note: Locator;
  edge: 'start' | 'end';
}) =>
  note.evaluate((element, edge) => {
    const text = element.firstChild as Text;
    const end = text.data.trimEnd().length;
    const range = document.createRange();
    range.setStart(text, edge === 'start' ? 0 : end - 1);
    range.setEnd(text, edge === 'start' ? 1 : end);

    const character = range.getBoundingClientRect();
    const box = element.getBoundingClientRect();
    return character.top >= box.top && character.bottom <= box.bottom;
  }, edge);
