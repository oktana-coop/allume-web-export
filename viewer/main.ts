// Pan and zoom for a board page, menus for linked cards, and focusing the card
// named in the URL hash (#card-<document id>). Loaded at the end of <body>,
// so the first camera is in place before the page is shown.

import { focusCard, setUpCanvas } from './canvas';
import { setUpGestures } from './gestures';
import { setUpScrolling } from './scrolling';
import { setUpStartingView } from './starting-view';
import { setUpZoomControls } from './zoom-controls';

/** A board in the breadcrumbs. */
type Breadcrumb = { href: string; label: string };

/** How a page was reached. */
type Arrival = 'down' | 'across' | 'up';

(() => {
  // Asserted rather than narrowed by the check below, which TypeScript
  // doesn't carry into the function declarations.
  const canvas = setUpCanvas(document)!;
  if (!canvas) return;
  document.documentElement.classList.add('js');

  setUpScrolling(canvas);
  setUpGestures(canvas);
  setUpZoomControls(canvas);

  // Scrolling the board closes an open linked card menu.
  canvas.viewport.addEventListener('wheel', closeMenus, { passive: true });

  function closeMenus() {
    for (const menu of document.querySelectorAll<HTMLElement>(
      '.linked-menu:popover-open'
    )) {
      menu.hidePopover();
    }
  }

  // Comment dates read like Muse's ("last year", "5 months ago"), counted
  // when the page is viewed. Like Muse, only whole units count: 23 months
  // ago is "last year".
  const relativeTime = new Intl.RelativeTimeFormat('en', { numeric: 'auto' });
  const DAY = 24 * 60 * 60 * 1000;
  const UNITS: [Intl.RelativeTimeFormatUnit, number][] = [
    ['year', 365 * DAY],
    ['month', 30 * DAY],
    ['week', 7 * DAY],
    ['day', DAY],
    ['hour', DAY / 24],
    ['minute', DAY / 1440],
  ];

  for (const time of document.querySelectorAll<HTMLTimeElement>(
    '.comment time'
  )) {
    const elapsed = Date.now() - Date.parse(time.dateTime);
    if (!Number.isFinite(elapsed)) continue;

    const [unit, length] =
      UNITS.find(([, length]) => elapsed >= length) ?? UNITS.at(-1)!;
    time.textContent = relativeTime.format(-Math.trunc(elapsed / length), unit);
  }

  // Copy buttons copy a text card's or comment's full text, including any
  // part the card's size cuts off, or all of a canvas text.
  const copiedTimers = new WeakMap<HTMLElement, number>();
  canvas.element.addEventListener('click', async (event) => {
    const button = (event.target as Element).closest<HTMLElement>('.copy');
    const owner = button?.parentElement;
    const source = owner?.matches('.chain')
      ? owner
      : owner?.querySelector(':scope > .body, :scope > .text');
    if (!source || !(await copyText(source))) return;

    button!.dataset.copied = '';
    button!.setAttribute('aria-label', 'Copied');

    clearTimeout(copiedTimers.get(button!));
    copiedTimers.set(
      button!,
      setTimeout(() => {
        delete button!.dataset.copied;
        button!.setAttribute('aria-label', 'Copy text');
      }, 1500)
    );
  });

  async function copyText(element: Element) {
    try {
      await navigator.clipboard.writeText(textOf(element));
      return true;
    } catch {
      // The Clipboard API needs a secure context; copy a selection instead.
      const selection = getSelection()!;
      const range = document.createRange();

      range.selectNodeContents(element);
      selection.removeAllRanges();
      selection.addRange(range);

      const copied = document.execCommand('copy');
      selection.removeAllRanges();
      return copied;
    }
  }

  // A canvas text has a paragraph per line, which textContent runs together.
  function textOf(element: Element) {
    if (!element.matches('.chain')) return element.textContent;
    return [...element.querySelectorAll(':scope > p')]
      .map((paragraph) => paragraph.textContent)
      .join('\n');
  }

  // Escape goes back the way we came after entering a board or jumping to a
  // linked card. Otherwise, after going up or arriving from elsewhere, it goes
  // up to the last breadcrumb. An open menu takes Escape for itself.
  addEventListener('keydown', (event) => {
    const modified = event.altKey || event.ctrlKey || event.metaKey;
    if (event.key !== 'Escape' || modified || !goToParent()) return;
    event.preventDefault();
  });

  function goToParent() {
    if (document.querySelector(':popover-open')) return false;

    const { arrival } = history.state ?? {};
    if (arrival === 'down' || arrival === 'across') {
      history.back();
      return true;
    }

    const parent = breadcrumbs?.querySelector<HTMLAnchorElement>(
      ':scope > a[rel="up"]'
    );
    if (!parent) return false;

    recordArrival(parent.href, 'up', breadcrumbTrail().slice(0, -1));
    location.href = parent.href;
    return true;
  }

  // Breadcrumbs follow the path taken, like in Muse: entering a board extends
  // the breadcrumbs it was entered from, and going up a breadcrumb keeps the
  // ones before it. Arriving any other way shows the board's main path.
  const breadcrumbs = document.querySelector('.crumbs');

  function breadcrumbLinks() {
    return [
      ...(breadcrumbs?.querySelectorAll<HTMLAnchorElement>(':scope > a') ?? []),
    ];
  }

  /** The boards in the breadcrumbs, from the root to the parent. */
  function breadcrumbTrail(): Breadcrumb[] {
    return breadcrumbLinks().map((link) => ({
      href: link.href,
      label: link.textContent,
    }));
  }

  function showTrail(trail: Breadcrumb[]) {
    const heading = breadcrumbs?.querySelector(':scope > h1');
    if (!heading) return;

    const shown = breadcrumbs!.querySelectorAll(
      ':scope > a, :scope > .separator'
    );
    for (const element of shown) element.remove();

    trail.forEach(({ href, label }, index) => {
      const link = document.createElement('a');
      link.href = href;
      link.textContent = label;
      if (index === trail.length - 1) link.rel = 'up';

      const separator = document.createElement('span');
      separator.className = 'separator';
      separator.setAttribute('aria-hidden', 'true');
      separator.textContent = '/';
      heading.before(link, separator);
    });

    markParent(heading, trail.at(-1));
  }

  // The page marks the main path's parent in the heading's linked card menu,
  // so a different path moves the mark to its own parent.
  function markParent(heading: Element, parent: Breadcrumb | undefined) {
    if (!parent) return;

    const path = new URL(parent.href).pathname;
    for (const link of heading.querySelectorAll<HTMLAnchorElement>(
      '.linked-menu a'
    )) {
      if (link.pathname === path) link.setAttribute('aria-current', 'true');
      else link.removeAttribute('aria-current');
    }
  }

  // Following a link records how the next page is reached: down into a
  // board, across to a linked card, or up through the breadcrumbs, with the
  // breadcrumbs it should show. That page keeps both in its history entry,
  // so they survive going back to it.
  const ARRIVAL_KEY = 'arrival';
  document.addEventListener('click', (event) => {
    // Modified clicks open new tabs or windows, which have nowhere to go back to.
    const link = (event.target as Element).closest<HTMLAnchorElement>(
      'a[href]'
    );
    const modified =
      event.metaKey || event.ctrlKey || event.shiftKey || event.altKey;
    if (!link || link.target || modified || event.defaultPrevented) return;

    const breadcrumb = breadcrumbLinks().indexOf(link);
    if (breadcrumb >= 0) {
      recordArrival(link.href, 'up', breadcrumbTrail().slice(0, breadcrumb));
    } else if (link.closest('.crumbs')) {
      recordArrival(link.href, 'up');
    } else if (link.closest('.linked-menu')) {
      recordArrival(link.href, 'across');
    } else if (link.matches('.panel')) {
      const here = {
        href: location.href.split('#')[0],
        label:
          breadcrumbs?.querySelector(':scope > h1 > span')?.textContent ?? '',
      };
      recordArrival(link.href, 'down', [...breadcrumbTrail(), here]);
    }
  });

  function recordArrival(url: string, how: Arrival, trail?: Breadcrumb[]) {
    try {
      const path = new URL(url).pathname;
      sessionStorage.setItem(ARRIVAL_KEY, JSON.stringify({ path, how, trail }));
    } catch {}
  }

  try {
    // A missing item is null, which parses as null.
    const arrival = JSON.parse(sessionStorage.getItem(ARRIVAL_KEY)!);
    sessionStorage.removeItem(ARRIVAL_KEY);

    if (arrival?.path === location.pathname) {
      const { how, trail } = arrival;
      history.replaceState({ ...history.state, arrival: how, trail }, '');
    }
  } catch {}
  if (history.state?.trail) showTrail(history.state.trail);

  // Linked-card menus live in the top layer, so place them by their button.
  for (const menu of document.querySelectorAll<HTMLElement>('.linked-menu')) {
    const button = document.querySelector(`[popovertarget="${menu.id}"]`);

    menu.addEventListener('beforetoggle', (event) => {
      if (event.newState !== 'open' || !button) return;

      const anchor = button.getBoundingClientRect();
      menu.style.left = `${Math.max(16, anchor.left)}px`;
      menu.style.top = `${anchor.bottom + 6}px`;
    });

    menu.addEventListener('toggle', (event) => {
      if (event.newState !== 'open' || !button) return;

      const anchor = button.getBoundingClientRect();
      const { width, height } = menu.getBoundingClientRect();
      const left = Math.max(16, Math.min(anchor.left, innerWidth - width - 16));
      const below = anchor.bottom + 6;
      const top =
        below + height > innerHeight - 16
          ? Math.max(16, anchor.top - height - 6)
          : below;

      menu.style.left = `${left}px`;
      menu.style.top = `${top}px`;
    });

    menu.addEventListener('click', (event) => {
      const link = (event.target as Element).closest('a');
      if (!link || link.pathname !== location.pathname) return;

      event.preventDefault();
      menu.hidePopover();
      history.replaceState(history.state, '', link.hash);
      focusCard({ canvas, id: link.hash.slice(1) });
    });
  }

  setUpStartingView(canvas);
})();
