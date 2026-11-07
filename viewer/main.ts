// Pan and zoom for a board page, menus for linked cards, and focusing the card
// named in the URL hash (#card-<document id>). Loaded at the end of <body>,
// so the first camera is in place before the page is shown.

import {
  clampScale,
  fit,
  focus,
  panLimits,
  pinch,
  zoomAt,
  type Camera,
} from './camera';
import {
  cardFrame,
  measure,
  moveCamera,
  setUpCanvas,
  startBounceBack,
} from './canvas';
import { clamp, type Point } from './geometry';

type Axis = 'x' | 'y';

/** A board in the breadcrumbs. */
type Breadcrumb = { href: string; label: string };

/** How a page was reached. */
type Arrival = 'down' | 'across' | 'up';

declare global {
  // Safari's trackpad pinches, which TypeScript's DOM types leave out.
  interface GestureEvent extends UIEvent {
    readonly scale: number;
    readonly clientX: number;
    readonly clientY: number;
  }

  interface HTMLElementEventMap {
    gesturestart: GestureEvent;
    gesturechange: GestureEvent;
  }
}

(() => {
  // Asserted rather than narrowed by the check below, which TypeScript
  // doesn't carry into the function declarations.
  const canvas = setUpCanvas(document)!;
  if (!canvas) return;
  const { viewport } = canvas;
  document.documentElement.classList.add('js');

  // Past an edge, a scroll only pushes for PUSH_TIME. The rest of it, usually
  // trackpad momentum, is ignored, so the board bounces back like on a Mac.
  // A new push starts after panning clear of the edge, after a pause of
  // SCROLL_PAUSE, or when scrolling picks up well beyond its slowest since the
  // push began (momentum only slows, give or take some jitter).
  const PUSH_TIME = 100;
  const SCROLL_PAUSE = 300;
  const DRAG_THRESHOLD = 4;
  const SELECTABLE_TEXT =
    '.world > .card--text > .body, .world > .comment > .text, .world > .chain';
  const zoomLevel = document.querySelector('.zoom-level');
  const cameraKey = `camera:${location.pathname}`;

  let lastWheel = 0;
  const pushes = { x: { start: 0, slowest: 0 }, y: { start: 0, slowest: 0 } };

  // Moves the camera, and shows its zoom level in the toolbar.
  function apply({
    camera,
    bouncing = false,
  }: {
    camera: Camera;
    bouncing?: boolean;
  }) {
    moveCamera({ canvas, camera, bouncing });
    if (zoomLevel) {
      zoomLevel.textContent = `${Math.round(canvas.camera.scale * 100)}%`;
    }
  }

  function home() {
    apply({ camera: fit(measure(canvas)) });
  }

  function zoomAtCenter(scale: number) {
    const measured = measure(canvas);
    const { width, height } = measured.viewport;
    const point = { x: width / 2, y: height / 2 };
    apply({
      camera: zoomAt({ camera: canvas.camera, point, scale, ...measured }),
    });
  }

  function focusCard(id: string) {
    const frame = cardFrame({ canvas, id });
    if (!frame) return false;
    apply({ camera: focus({ frame, ...measure(canvas) }) });
    return true;
  }

  function closeMenus() {
    for (const menu of document.querySelectorAll<HTMLElement>(
      '.linked-menu:popover-open'
    )) {
      menu.hidePopover();
    }
  }

  function viewportPoint(clientX: number, clientY: number) {
    const { left, top } = viewport.getBoundingClientRect();
    return { x: clientX - left, y: clientY - top };
  }

  // Trackpads scroll to pan and pinch (sent as ctrl+wheel) to zoom.
  viewport.addEventListener(
    'wheel',
    (event) => {
      event.preventDefault();
      closeMenus();
      const unit =
        event.deltaMode === 1
          ? 16
          : event.deltaMode === 2
            ? viewport.clientHeight
            : 1;
      if (event.ctrlKey || event.metaKey) {
        const delta = Math.max(-50, Math.min(50, event.deltaY * unit));
        const point = viewportPoint(event.clientX, event.clientY);
        const scale = canvas.camera.scale * Math.exp(-delta * 0.01);
        apply({
          camera: zoomAt({
            camera: canvas.camera,
            point,
            scale,
            ...measure(canvas),
          }),
        });
      } else {
        const now = performance.now();
        const paused = now - lastWheel > SCROLL_PAUSE;
        lastWheel = now;
        const limits = panLimits({
          scale: canvas.camera.scale,
          ...measure(canvas),
        });
        const pan = (axis: Axis, delta: number) => {
          const [min, max] = limits[axis];
          const value = canvas.camera[axis];
          const next = value - delta;
          const push = pushes[axis];
          const speed = Math.abs(delta);
          if (next >= min && next <= max) {
            push.start = 0;
            return next;
          }
          if (!push.start || paused || speed > 2 * push.slowest + 4) {
            push.start = now;
            push.slowest = speed;
          }
          push.slowest = Math.min(push.slowest, speed);
          const outward =
            Math.abs(next - clamp(next, min, max)) >
            Math.abs(value - clamp(value, min, max));
          return outward && now - push.start > PUSH_TIME ? value : next;
        };
        apply({
          camera: {
            ...canvas.camera,
            x: pan('x', event.deltaX * unit),
            y: pan('y', event.deltaY * unit),
          },
          bouncing: true,
        });
        startBounceBack(canvas);
      }
    },
    { passive: false }
  );

  // Safari reports trackpad pinches as gesture events instead.
  let gestureStartScale = 1;
  viewport.addEventListener('gesturestart', (event) => {
    event.preventDefault();
    gestureStartScale = canvas.camera.scale;
  });
  viewport.addEventListener('gesturechange', (event) => {
    event.preventDefault();
    if (pointers.size > 1) return; // Touch pinches are handled below.
    const point = viewportPoint(event.clientX, event.clientY);
    const scale = gestureStartScale * event.scale;
    apply({
      camera: zoomAt({
        camera: canvas.camera,
        point,
        scale,
        ...measure(canvas),
      }),
    });
  });

  // Dragging with one pointer pans; pinching with two zooms. A press that
  // doesn't move is left alone, so links and buttons still work, and a mouse
  // drag that starts on text selects the text instead.
  const pointers = new Map<number, Point>();
  let suppressClick = false;

  function midpoint(points: Point[]) {
    const x = points.reduce((sum, p) => sum + p.x, 0) / points.length;
    const y = points.reduce((sum, p) => sum + p.y, 0) / points.length;
    return { x, y };
  }

  function spread(points: Point[]) {
    return points.length > 1
      ? Math.hypot(points[0].x - points[1].x, points[0].y - points[1].y)
      : 0;
  }

  function startGesture() {
    const points = [...pointers.values()];
    canvas.gesture = {
      camera: { ...canvas.camera },
      center: midpoint(points),
      distance: spread(points),
      dragging: Boolean(canvas.gesture?.dragging) || points.length > 1,
    };
  }

  viewport.addEventListener('pointerdown', (event) => {
    suppressClick = false;
    if (event.pointerType === 'mouse' && event.button !== 0) return;
    if ((event.target as Element).closest('button, [popover]')) return;
    if (
      event.pointerType === 'mouse' &&
      (event.target as Element).closest(SELECTABLE_TEXT)
    ) {
      return;
    }
    pointers.set(event.pointerId, { x: event.clientX, y: event.clientY });
    startGesture();
  });

  viewport.addEventListener('pointermove', (event) => {
    const { gesture } = canvas;
    if (!gesture || !pointers.has(event.pointerId)) return;
    pointers.set(event.pointerId, { x: event.clientX, y: event.clientY });
    const points = [...pointers.values()];
    const center = midpoint(points);
    if (!gesture.dragging) {
      const moved = Math.hypot(
        center.x - gesture.center.x,
        center.y - gesture.center.y
      );
      if (moved < DRAG_THRESHOLD) return;
      gesture.dragging = true;
      viewport.classList.add('is-dragging');
    }
    if (!viewport.hasPointerCapture(event.pointerId)) {
      viewport.setPointerCapture(event.pointerId);
    }
    const scale =
      points.length > 1 && gesture.distance > 0
        ? clampScale({
            scale: (gesture.camera.scale * spread(points)) / gesture.distance,
            ...measure(canvas),
          })
        : gesture.camera.scale;
    const from = viewportPoint(gesture.center.x, gesture.center.y);
    const to = viewportPoint(center.x, center.y);
    // Keeps the board point that started under the gesture under it.
    apply({
      camera: pinch({ camera: gesture.camera, from, to, scale }),
      bouncing: true,
    });
  });

  function endPointer(event: PointerEvent) {
    if (!pointers.delete(event.pointerId)) return;
    if (pointers.size > 0) {
      startGesture();
      return;
    }
    suppressClick = Boolean(canvas.gesture?.dragging);
    canvas.gesture = null;
    viewport.classList.remove('is-dragging');
    startBounceBack(canvas);
  }
  viewport.addEventListener('pointerup', endPointer);
  viewport.addEventListener('pointercancel', endPointer);

  viewport.addEventListener(
    'click',
    (event) => {
      if (!suppressClick) return;
      event.preventDefault();
      event.stopPropagation();
      suppressClick = false;
    },
    true
  );
  viewport.addEventListener('dragstart', (event) => event.preventDefault());

  document.querySelector('.zoom')?.addEventListener('click', (event) => {
    const action = (event.target as Element).closest<HTMLElement>('[data-zoom]')
      ?.dataset.zoom;
    if (action === 'in') zoomAtCenter(canvas.camera.scale * 1.25);
    else if (action === 'out') zoomAtCenter(canvas.camera.scale * 0.8);
    else if (action === 'home') home();
  });

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

  // + and − zoom, 0 shows the board at 100% and Shift+1 fits it. With
  // Ctrl/Cmd they work the same, instead of zooming the whole page.
  addEventListener('keydown', (event) => {
    if (event.altKey) return;
    const command = event.ctrlKey || event.metaKey;
    if (event.key === '+' || event.key === '=')
      zoomAtCenter(canvas.camera.scale * 1.25);
    else if (event.key === '-') zoomAtCenter(canvas.camera.scale * 0.8);
    else if (event.key === '0') zoomAtCenter(1);
    else if (event.shiftKey && event.code === 'Digit1') home();
    else if (event.key !== 'Escape' || command || !goToParent()) return;
    event.preventDefault();
  });

  // Escape goes back the way we came after entering a board or jumping to a
  // linked card. Otherwise, after going up or arriving from elsewhere, it goes
  // up to the last breadcrumb. An open menu takes Escape for itself.
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
      focusCard(link.hash.slice(1));
    });
  }

  addEventListener('hashchange', () => focusCard(location.hash.slice(1)));
  addEventListener('pagehide', () => {
    try {
      sessionStorage.setItem(cameraKey, JSON.stringify(canvas.camera));
    } catch {}
  });

  function restoreCamera() {
    try {
      // A missing item is null, which parses as null.
      const saved = JSON.parse(sessionStorage.getItem(cameraKey)!);
      if (![saved?.x, saved?.y, saved?.scale].every(Number.isFinite)) {
        return false;
      }
      apply({
        camera: {
          ...saved,
          scale: clampScale({ scale: saved.scale, ...measure(canvas) }),
        },
      });
      return true;
    } catch {
      return false;
    }
  }

  // A link to a card centres it. Otherwise a board opens where it was last
  // left in this session, like in Muse, or framed whole on a first visit.
  if (!focusCard(location.hash.slice(1)) && !restoreCamera()) home();
})();
