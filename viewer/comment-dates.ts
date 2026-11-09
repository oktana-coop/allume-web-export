// Comment dates read like Allume's ("last year", "5 months ago"), counted
// when the page is viewed. Like Allume, only whole units count: 23 months
// ago is "last year".

type Unit = [Intl.RelativeTimeFormatUnit, number];

const MINUTE = 60 * 1000;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;
const SMALLEST: Unit = ['minute', MINUTE];
const UNITS: Unit[] = [
  ['year', 365 * DAY],
  ['month', 30 * DAY],
  ['week', 7 * DAY],
  ['day', DAY],
  ['hour', HOUR],
  SMALLEST,
];

const relativeTime = new Intl.RelativeTimeFormat('en', { numeric: 'auto' });

export function makeCommentDatesRelative(root: ParentNode) {
  const now = Date.now();
  for (const time of root.querySelectorAll<HTMLTimeElement>(
    '.allume-comment time'
  )) {
    const date = relativeDate({ written: Date.parse(time.dateTime), now });
    if (date) time.textContent = date;
  }
}

/**
 * How long ago something was written, in the largest whole unit up to a year,
 * or null if `written` isn't a time.
 */
export function relativeDate({
  written,
  now,
}: {
  written: number;
  now: number;
}): string | null {
  const elapsed = now - written;
  if (!Number.isFinite(elapsed)) return null;

  const [unit, length] =
    UNITS.find(([, length]) => elapsed >= length) ?? SMALLEST;
  return relativeTime.format(-Math.trunc(elapsed / length), unit);
}
