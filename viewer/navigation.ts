import {
  breadcrumbLinks,
  parentLink,
  parseBreadcrumbs,
  readBreadcrumbs,
  showBreadcrumbs,
  currentBoard,
  type Breadcrumb,
  type Breadcrumbs,
} from './breadcrumbs';
import { isRecord } from './guards';
import { takeSession, writeSession } from './session';

/** How a page was reached. */
export type Arrival = 'down' | 'across' | 'up';

/**
 * How the page at the path is reached, recorded by the page whose link was
 * followed, with the breadcrumbs it shows, unless they're its main path.
 */
export type ArrivalRecord = {
  path: string;
  how: Arrival;
  breadcrumbs?: Breadcrumbs;
};

/** What a page keeps in its history entry. */
export type HistoryState = { arrival?: Arrival; breadcrumbs?: Breadcrumbs };

/** A followed link, by where it is on the page. */
export type FollowedLink =
  | { kind: 'breadcrumb'; index: number }
  | { kind: 'heading menu' }
  | { kind: 'linked card menu' }
  | { kind: 'board card' };

const ARRIVAL_KEY = 'arrival';

/**
 * Breadcrumbs follow the path taken, like in Allume: entering a board extends
 * the breadcrumbs it was entered from, and going up a breadcrumb keeps the
 * ones before it. Arriving any other way shows the board's main path.
 *
 * Escape goes back the way we came after entering a board or jumping to a
 * linked card. Otherwise, after going up or arriving from elsewhere, it goes
 * up to the last breadcrumb.
 */
export function setUpNavigation(root: HTMLElement) {
  const breadcrumbsElement = root.querySelector('.allume-breadcrumbs');

  // Following a link records how the next page is reached. That page keeps it
  // in its history entry, so the breadcrumbs survive going back to it.
  const recorded = takeSession({ key: ARRIVAL_KEY, parse: parseArrivalRecord });
  if (recorded?.path === location.pathname) {
    const { how, breadcrumbs } = recorded;
    history.replaceState({ ...history.state, arrival: how, breadcrumbs }, '');
  }

  const { breadcrumbs } = parseHistoryState(history.state);
  if (breadcrumbs) showBreadcrumbs({ breadcrumbsElement, breadcrumbs });

  const recordFollowing = (link: HTMLAnchorElement) => {
    const followed = followedLink({ breadcrumbsElement, link });
    if (!followed) return;

    const arrival = arrivalFor({
      link: followed,
      breadcrumbs: readBreadcrumbs(breadcrumbsElement),
      current: currentBoard(breadcrumbsElement),
    });

    const path = new URL(link.href).pathname;
    writeSession({ key: ARRIVAL_KEY, value: { path, ...arrival } });
  };

  root.addEventListener('click', (event) => {
    const link = (event.target as Element).closest<HTMLAnchorElement>(
      'a[href]'
    );

    // Modified clicks open a new tab or window, with nowhere to go back to.
    const modified =
      event.metaKey || event.ctrlKey || event.shiftKey || event.altKey;
    if (!link || link.target || modified || event.defaultPrevented) return;

    recordFollowing(link);
  });

  addEventListener('keydown', (event) => {
    const modified = event.altKey || event.ctrlKey || event.metaKey;
    if (event.key !== 'Escape' || modified) return;

    // An open menu takes Escape for itself.
    if (document.querySelector(':popover-open')) return;

    const parent = parentLink(breadcrumbsElement);
    const target = escapeTarget({
      arrival: parseHistoryState(history.state).arrival,
      hasParent: parent !== null,
    });

    if (target === 'back') {
      history.back();
    } else if (target === 'up' && parent) {
      recordFollowing(parent);
      location.href = parent.href;
    } else {
      return;
    }

    event.preventDefault();
  });
}

/**
 * How following the link reaches the next page, and the breadcrumbs it shows
 * there: a breadcrumb goes up, keeping the ones before it; the heading's
 * linked card menu goes up, to the board's main path; a linked card menu goes
 * across; and a board card goes down, adding the current board to the
 * breadcrumbs.
 */
export function arrivalFor({
  link,
  breadcrumbs,
  current,
}: {
  link: FollowedLink;
  breadcrumbs: Breadcrumbs;
  current: Breadcrumb;
}): { how: Arrival; breadcrumbs?: Breadcrumbs } {
  switch (link.kind) {
    case 'breadcrumb':
      return { how: 'up', breadcrumbs: breadcrumbs.slice(0, link.index) };
    case 'heading menu':
      return { how: 'up' };
    case 'linked card menu':
      return { how: 'across' };
    case 'board card':
      return { how: 'down', breadcrumbs: [...breadcrumbs, current] };
  }
}

/**
 * Where Escape goes: back the way the page was reached, down or across, or
 * else up to its parent, if it has one.
 */
export function escapeTarget({
  arrival,
  hasParent,
}: {
  arrival: Arrival | undefined;
  hasParent: boolean;
}): 'back' | 'up' | null {
  if (arrival === 'down' || arrival === 'across') return 'back';
  return hasParent ? 'up' : null;
}

/** The arrival in the value, if it has a path, a way, and valid breadcrumbs. */
export function parseArrivalRecord(value: unknown): ArrivalRecord | null {
  if (!isRecord(value)) return null;

  const { path, how, breadcrumbs } = value;
  if (typeof path !== 'string' || !isArrival(how)) return null;
  if (breadcrumbs === undefined) return { path, how };

  const parsed = parseBreadcrumbs(breadcrumbs);
  return parsed && { path, how, breadcrumbs: parsed };
}

/**
 * The arrival and the breadcrumbs in the value, leaving out what isn't
 * valid.
 */
export function parseHistoryState(value: unknown): HistoryState {
  if (!isRecord(value)) return {};

  const arrival = isArrival(value.arrival) ? value.arrival : undefined;
  const breadcrumbs = parseBreadcrumbs(value.breadcrumbs) ?? undefined;
  return { arrival, breadcrumbs };
}

/**
 * Which kind of link it is, or null for one that keeps no breadcrumbs, such
 * as a link to another site.
 */
function followedLink({
  breadcrumbsElement,
  link,
}: {
  breadcrumbsElement: Element | null;
  link: HTMLAnchorElement;
}): FollowedLink | null {
  const index = breadcrumbLinks(breadcrumbsElement).indexOf(link);
  if (index >= 0) return { kind: 'breadcrumb', index };
  if (link.closest('.allume-breadcrumbs')) return { kind: 'heading menu' };
  if (link.closest('.allume-linked-menu')) return { kind: 'linked card menu' };
  if (link.matches('.allume-panel')) return { kind: 'board card' };
  return null;
}

function isArrival(value: unknown): value is Arrival {
  return value === 'down' || value === 'across' || value === 'up';
}
