import { describe, expect, it } from 'vitest';

import { relativeDate } from './comment-dates';

const WRITTEN = Date.parse('2026-10-28T10:45:00Z');

const SECOND = 1000;
const MINUTE = 60 * SECOND;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;

describe('relativeDate', () => {
  it.each([
    { age: '30 seconds', elapsed: 30 * SECOND, reads: 'this minute' },
    { age: '5 minutes', elapsed: 5 * MINUTE, reads: '5 minutes ago' },
    { age: '3 hours', elapsed: 3 * HOUR, reads: '3 hours ago' },
    { age: 'a day', elapsed: DAY, reads: 'yesterday' },
    { age: '6 days', elapsed: 6 * DAY, reads: '6 days ago' },
    { age: '2 weeks', elapsed: 14 * DAY, reads: '2 weeks ago' },
    { age: '2 months', elapsed: 60 * DAY, reads: '2 months ago' },
    // Only whole units count, so 23 months are a year.
    { age: '23 months', elapsed: 690 * DAY, reads: 'last year' },
    { age: '3 years', elapsed: 3 * 365 * DAY, reads: '3 years ago' },
  ])('reads "$reads" $age after it was written', ({ elapsed, reads }) => {
    expect(relativeDate({ written: WRITTEN, now: WRITTEN + elapsed })).toBe(
      reads
    );
  });

  it("is null for a date that isn't a time", () => {
    const written = Date.parse('not a date');

    expect(relativeDate({ written, now: WRITTEN })).toBeNull();
  });
});
