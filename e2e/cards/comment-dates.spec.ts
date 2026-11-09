import { expect, test } from '@playwright/test';

import { logic } from '../shared/boards';

// When Logic's comment was written, in the sample export.
const WRITTEN = Date.parse('2026-10-28T10:45:00Z');

const SECOND = 1000;
const MINUTE = 60 * SECOND;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;

const cases = [
  { age: '30 seconds', elapsed: 30 * SECOND, reads: 'this minute' },
  { age: '5 minutes', elapsed: 5 * MINUTE, reads: '5 minutes ago' },
  { age: '3 hours', elapsed: 3 * HOUR, reads: '3 hours ago' },
  { age: 'a day', elapsed: DAY, reads: 'yesterday' },
  { age: '2 weeks', elapsed: 14 * DAY, reads: '2 weeks ago' },
  { age: '2 months', elapsed: 60 * DAY, reads: '2 months ago' },
  // Only whole units count, so 23 months are a year.
  { age: '23 months', elapsed: 690 * DAY, reads: 'last year' },
];

test.describe('comment dates', () => {
  for (const { age, elapsed, reads } of cases) {
    test(`a comment written ${age} ago reads "${reads}"`, async ({ page }) => {
      await page.clock.setFixedTime(WRITTEN + elapsed);

      await page.goto(logic.url);

      await expect(
        page
          .locator('.allume-canvas > .allume-comment', {
            hasText: 'Datalog would fit here',
          })
          .locator('time')
      ).toHaveText(reads);
    });
  }
});
