// Pan and zoom for a board page, menus for linked cards, and focusing the card
// named in the URL hash (#card-<document id>). Loaded at the end of <body>,
// so the first camera is in place before the page is shown.

type Point = { x: number; y: number };

/** The canvas's offset in the viewport, in pixels, and its scale. */
type Camera = { x: number; y: number; scale: number };

type Axis = 'x' | 'y';

type Interval = [min: number, max: number];

/** A drag or pinch, from where it started. */
type Gesture = {
  camera: Camera;
  center: Point;
  distance: number;
  dragging: boolean;
};

/** A board in the breadcrumbs. */
type Breadcrumb = { href: string; label: string };

/** How a page was reached. */
type Arrival = 'down' | 'across' | 'up';

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

(() => {
  // Asserted rather than narrowed by the check below, which TypeScript
  // doesn't carry into the function declarations.
  const viewport = document.querySelector<HTMLElement>('.viewport')!;
  const world = viewport?.querySelector<HTMLElement>('.world')!;
  if (!viewport || !world) return;
  document.documentElement.classList.add('js');

  // Zooming out stops at 50%, or lower when the whole board needs it to fit.
  const MIN_SCALE = 0.5;
  const MAX_SCALE = 4;
  // Panning stops while this much of the board's contents is still in view.
  // Pulling further bounces the board past the edge, by at most MAX_BOUNCE,
  // and unless a drag holds it there it bounces back, keeping SPRING of the
  // bounce each frame (at 60 fps). Reduced motion turns bouncing off.
  const PAN_MARGIN = 120;
  const MAX_BOUNCE = 80;
  const SPRING = 0.8;
  const BOUNCES = !matchMedia('(prefers-reduced-motion: reduce)').matches;
  // Past an edge, a scroll only pushes for PUSH_TIME. The rest of it, usually
  // trackpad momentum, is ignored, so the board bounces back like on a Mac.
  // A new push starts after panning clear of the edge, after a pause of
  // SCROLL_PAUSE, or when scrolling picks up well beyond its slowest since the
  // push began (momentum only slows, give or take some jitter).
  const PUSH_TIME = 100;
  const SCROLL_PAUSE = 300;
  const DRAG_THRESHOLD = 4;
  const FOCUS_PADDING = 80;
  const SELECTABLE_TEXT =
    '.world > .card--text > .body, .world > .comment > .text, .world > .chain';
  const [minX, minY, maxX, maxY] = world.dataset.bounds!.split(',').map(Number);
  const zoomLevel = document.querySelector('.zoom-level');
  const cameraKey = `camera:${location.pathname}`;

  let camera: Camera = { x: 0, y: 0, scale: 1 };
  let bounceFrame = 0;
  let lastWheel = 0;
  const pushes = { x: { start: 0, slowest: 0 }, y: { start: 0, slowest: 0 } };

  // The camera positions that keep PAN_MARGIN of the board in view.
  function panLimits(): Record<Axis, Interval> {
    const { clientWidth: width, clientHeight: height } = viewport;
    const { scale } = camera;
    const marginX = Math.min(PAN_MARGIN, width / 2, (maxX - minX) * scale);
    const marginY = Math.min(PAN_MARGIN, height / 2, (maxY - minY) * scale);
    return {
      x: [marginX - maxX * scale, width - marginX - minX * scale],
      y: [marginY - maxY * scale, height - marginY - minY * scale],
    };
  }

  // Places the board, keeping the camera within the panning limits. While
  // panning (bouncing), the camera may go past them and the board bounces.
  function apply({ bouncing = false }: { bouncing?: boolean } = {}) {
    const limits = panLimits();
    const bound = bouncing && BOUNCES ? bounce : clamp;
    const x = bound(camera.x, ...limits.x);
    const y = bound(camera.y, ...limits.y);
    if (bound === clamp) Object.assign(camera, { x, y });
    world.style.transform = `translate(${x}px, ${y}px) scale(${camera.scale})`;
    if (zoomLevel) zoomLevel.textContent = `${Math.round(camera.scale * 100)}%`;
  }

  // Brings a bouncing board back within the limits, frame by frame. Scrolling
  // pushes against the pull, so the bounce follows how hard you push, and
  // trackpad momentum ends in a bounce.
  function startBounceBack() {
    if (bounceFrame) return;
    let last = performance.now();
    const step = (now: number) => {
      bounceFrame = 0;
      if (gesture) return; // A drag holds the bounce until it's let go.
      const keep = SPRING ** (Math.max(0, now - last) / 16);
      last = now;
      const limits = panLimits();
      const pull = (value: number, [min, max]: Interval) => {
        const edge = clamp(value, min, max);
        return Math.abs(value - edge) < 0.5
          ? edge
          : edge + (value - edge) * keep;
      };
      camera.x = pull(camera.x, limits.x);
      camera.y = pull(camera.y, limits.y);
      apply({ bouncing: true });
      const stillBouncing =
        camera.x !== clamp(camera.x, ...limits.x) ||
        camera.y !== clamp(camera.y, ...limits.y);
      if (stillBouncing) bounceFrame = requestAnimationFrame(step);
    };
    bounceFrame = requestAnimationFrame(step);
  }

  function clamp(value: number, min: number, max: number) {
    return Math.min(max, Math.max(min, value));
  }

  // Past a limit, the board gives less the further it's pulled.
  function bounce(value: number, min: number, max: number) {
    const over = value < min ? value - min : value > max ? value - max : 0;
    return (
      clamp(value, min, max) +
      (MAX_BOUNCE * over) / (Math.abs(over) + MAX_BOUNCE)
    );
  }

  function clampScale(scale: number) {
    return clamp(scale, Math.min(MIN_SCALE, fitScale()), MAX_SCALE);
  }

  // The scale that frames the board the way its card previews it: origin at
  // the top left, with everything in view.
  function fitScale() {
    return Math.min(
      1,
      viewport.clientWidth / (maxX + minX),
      viewport.clientHeight / (maxY + minY)
    );
  }

  function home() {
    camera = { x: 0, y: 0, scale: clampScale(fitScale()) };
    apply();
  }

  // Zooms to the scale, keeping the viewport point (x, y) in place.
  function zoomAt(x: number, y: number, scale: number) {
    const target = clampScale(scale);
    const ratio = target / camera.scale;
    camera = {
      x: x - (x - camera.x) * ratio,
      y: y - (y - camera.y) * ratio,
      scale: target,
    };
    apply();
  }

  function zoomAtCenter(scale: number) {
    zoomAt(viewport.clientWidth / 2, viewport.clientHeight / 2, scale);
  }

  function focusCard(id: string) {
    const card = id && document.getElementById(id);
    if (!card || !world.contains(card)) return false;
    const {
      offsetLeft: x,
      offsetTop: y,
      offsetWidth: w,
      offsetHeight: h,
    } = card;
    const scale = clampScale(
      Math.min(
        1,
        (viewport.clientWidth - FOCUS_PADDING * 2) / w,
        (viewport.clientHeight - FOCUS_PADDING * 2) / h
      )
    );
    camera = {
      x: viewport.clientWidth / 2 - (x + w / 2) * scale,
      y: viewport.clientHeight / 2 - (y + h / 2) * scale,
      scale,
    };
    apply();
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
        zoomAt(point.x, point.y, camera.scale * Math.exp(-delta * 0.01));
      } else {
        const now = performance.now();
        const paused = now - lastWheel > SCROLL_PAUSE;
        lastWheel = now;
        const limits = panLimits();
        const pan = (axis: Axis, delta: number) => {
          const [min, max] = limits[axis];
          const value = camera[axis];
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
        camera = {
          ...camera,
          x: pan('x', event.deltaX * unit),
          y: pan('y', event.deltaY * unit),
        };
        apply({ bouncing: true });
        startBounceBack();
      }
    },
    { passive: false }
  );

  // Safari reports trackpad pinches as gesture events instead.
  let gestureStartScale = 1;
  viewport.addEventListener('gesturestart', (event) => {
    event.preventDefault();
    gestureStartScale = camera.scale;
  });
  viewport.addEventListener('gesturechange', (event) => {
    event.preventDefault();
    if (pointers.size > 1) return; // Touch pinches are handled below.
    const point = viewportPoint(event.clientX, event.clientY);
    zoomAt(point.x, point.y, gestureStartScale * event.scale);
  });

  // Dragging with one pointer pans; pinching with two zooms. A press that
  // doesn't move is left alone, so links and buttons still work, and a mouse
  // drag that starts on text selects the text instead.
  const pointers = new Map<number, Point>();
  let gesture: Gesture | null = null;
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
    gesture = {
      camera: { ...camera },
      center: midpoint(points),
      distance: spread(points),
      dragging: Boolean(gesture?.dragging) || points.length > 1,
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
        ? clampScale((gesture.camera.scale * spread(points)) / gesture.distance)
        : gesture.camera.scale;
    const ratio = scale / gesture.camera.scale;
    const start = viewportPoint(gesture.center.x, gesture.center.y);
    const now = viewportPoint(center.x, center.y);
    // Keeps the board point that started under the gesture under it.
    camera = {
      x: now.x - (start.x - gesture.camera.x) * ratio,
      y: now.y - (start.y - gesture.camera.y) * ratio,
      scale,
    };
    apply({ bouncing: true });
  });

  function endPointer(event: PointerEvent) {
    if (!pointers.delete(event.pointerId)) return;
    if (pointers.size > 0) {
      startGesture();
      return;
    }
    suppressClick = Boolean(gesture?.dragging);
    gesture = null;
    viewport.classList.remove('is-dragging');
    startBounceBack();
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

  // The camera is a transform, so undo any native scrolling, such as the
  // browser scrolling to the #card- target.
  viewport.addEventListener('scroll', () => {
    viewport.scrollTop = 0;
    viewport.scrollLeft = 0;
  });

  document.querySelector('.zoom')?.addEventListener('click', (event) => {
    const action = (event.target as Element).closest<HTMLElement>('[data-zoom]')
      ?.dataset.zoom;
    if (action === 'in') zoomAtCenter(camera.scale * 1.25);
    else if (action === 'out') zoomAtCenter(camera.scale * 0.8);
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
  world.addEventListener('click', async (event) => {
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
      zoomAtCenter(camera.scale * 1.25);
    else if (event.key === '-') zoomAtCenter(camera.scale * 0.8);
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
      sessionStorage.setItem(cameraKey, JSON.stringify(camera));
    } catch {}
  });

  function restoreCamera() {
    try {
      // A missing item is null, which parses as null.
      const saved = JSON.parse(sessionStorage.getItem(cameraKey)!);
      if (![saved?.x, saved?.y, saved?.scale].every(Number.isFinite)) {
        return false;
      }
      camera = { ...saved, scale: clampScale(saved.scale) };
      apply();
      return true;
    } catch {
      return false;
    }
  }

  // A link to a card centres it. Otherwise a board opens where it was last
  // left in this session, like in Muse, or framed whole on a first visit.
  if (!focusCard(location.hash.slice(1)) && !restoreCamera()) home();
})();
