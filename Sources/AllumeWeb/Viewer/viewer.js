// Built from viewer/ by `npm run build:viewer`. Edit it there.
"use strict";
(() => {
  // viewer/geometry.ts
  function maxX(rect) {
    return rect.x + rect.width;
  }
  function maxY(rect) {
    return rect.y + rect.height;
  }
  function clamp(value, min, max) {
    return Math.min(max, Math.max(min, value));
  }

  // viewer/guards.ts
  function isRecord(value) {
    return typeof value === "object" && value !== null;
  }
  function isFiniteNumber(value) {
    return typeof value === "number" && Number.isFinite(value);
  }

  // viewer/camera.ts
  var MIN_SCALE = 0.5;
  var MAX_SCALE = 4;
  var PAN_MARGIN = 120;
  var MAX_BOUNCE = 80;
  var SPRING = 0.8;
  var FOCUS_PADDING = 80;
  function parseCamera(value) {
    if (!isRecord(value)) return null;
    const { x, y, scale } = value;
    return isFiniteNumber(x) && isFiniteNumber(y) && isFiniteNumber(scale) ? { x, y, scale } : null;
  }
  function fitScale({
    viewport,
    contentBounds
  }) {
    return Math.min(
      1,
      viewport.width / (maxX(contentBounds) + contentBounds.x),
      viewport.height / (maxY(contentBounds) + contentBounds.y)
    );
  }
  function clampScale({
    scale,
    viewport,
    contentBounds
  }) {
    const fit2 = fitScale({ viewport, contentBounds });
    return clamp(scale, Math.min(MIN_SCALE, fit2), MAX_SCALE);
  }
  function fit({
    viewport,
    contentBounds
  }) {
    return { x: 0, y: 0, scale: fitScale({ viewport, contentBounds }) };
  }
  function focus({
    frame,
    viewport,
    contentBounds
  }) {
    const { width, height } = viewport;
    const scale = clampScale({
      scale: Math.min(
        1,
        (width - FOCUS_PADDING * 2) / frame.width,
        (height - FOCUS_PADDING * 2) / frame.height
      ),
      viewport,
      contentBounds
    });
    return {
      x: width / 2 - (frame.x + frame.width / 2) * scale,
      y: height / 2 - (frame.y + frame.height / 2) * scale,
      scale
    };
  }
  function zoomAt({
    camera,
    point,
    scale,
    viewport,
    contentBounds
  }) {
    return pinch({
      camera,
      from: point,
      to: point,
      scale: clampScale({ scale, viewport, contentBounds })
    });
  }
  function pinch({
    camera,
    from,
    to,
    scale
  }) {
    const ratio = scale / camera.scale;
    return {
      x: to.x - (from.x - camera.x) * ratio,
      y: to.y - (from.y - camera.y) * ratio,
      scale
    };
  }
  function panLimits({
    scale,
    viewport,
    contentBounds
  }) {
    const marginX = Math.min(
      PAN_MARGIN,
      viewport.width / 2,
      contentBounds.width * scale
    );
    const marginY = Math.min(
      PAN_MARGIN,
      viewport.height / 2,
      contentBounds.height * scale
    );
    return {
      x: [
        marginX - maxX(contentBounds) * scale,
        viewport.width - marginX - contentBounds.x * scale
      ],
      y: [
        marginY - maxY(contentBounds) * scale,
        viewport.height - marginY - contentBounds.y * scale
      ]
    };
  }
  function withinLimits({
    camera,
    viewport,
    contentBounds
  }) {
    const limits = panLimits({ scale: camera.scale, viewport, contentBounds });
    return {
      x: clamp(camera.x, ...limits.x),
      y: clamp(camera.y, ...limits.y),
      scale: camera.scale
    };
  }
  function isBouncing({
    camera,
    viewport,
    contentBounds
  }) {
    const within = withinLimits({ camera, viewport, contentBounds });
    return camera.x !== within.x || camera.y !== within.y;
  }
  function bounce({
    camera,
    viewport,
    contentBounds
  }) {
    const limits = panLimits({ scale: camera.scale, viewport, contentBounds });
    const bounced = (value, [min, max]) => {
      const edge = clamp(value, min, max);
      const over = value - edge;
      return edge + MAX_BOUNCE * over / (Math.abs(over) + MAX_BOUNCE);
    };
    return {
      x: bounced(camera.x, limits.x),
      y: bounced(camera.y, limits.y),
      scale: camera.scale
    };
  }
  function bounceBack({
    camera,
    elapsed,
    viewport,
    contentBounds
  }) {
    const keep = SPRING ** (Math.max(0, elapsed) / 16);
    const limits = panLimits({ scale: camera.scale, viewport, contentBounds });
    const pulled = (value, [min, max]) => {
      const edge = clamp(value, min, max);
      return Math.abs(value - edge) < 0.5 ? edge : edge + (value - edge) * keep;
    };
    return {
      x: pulled(camera.x, limits.x),
      y: pulled(camera.y, limits.y),
      scale: camera.scale
    };
  }

  // viewer/canvas.ts
  function setUpCanvas(root) {
    const viewport = root.querySelector(".viewport");
    const element = viewport?.querySelector(".world");
    if (!viewport || !element) return null;
    viewport.addEventListener("scroll", () => {
      viewport.scrollTop = 0;
      viewport.scrollLeft = 0;
    });
    const [minX, minY, maxX2, maxY2] = element.dataset.bounds.split(",").map(Number);
    return {
      viewport,
      element,
      zoomLevelLabel: root.querySelector(".zoom-level"),
      contentBounds: {
        x: minX,
        y: minY,
        width: maxX2 - minX,
        height: maxY2 - minY
      },
      reducedMotion: matchMedia("(prefers-reduced-motion: reduce)").matches,
      camera: { x: 0, y: 0, scale: 1 },
      gesture: null,
      bouncingBack: false
    };
  }
  function measure(canvas2) {
    const { clientWidth: width, clientHeight: height } = canvas2.viewport;
    return { viewport: { width, height }, contentBounds: canvas2.contentBounds };
  }
  function moveCamera({
    canvas: canvas2,
    camera,
    bouncing = false
  }) {
    const showBounce = bouncing && !canvas2.reducedMotion;
    const shown = showBounce ? bounce({ camera, ...measure(canvas2) }) : withinLimits({ camera, ...measure(canvas2) });
    canvas2.camera = showBounce ? camera : shown;
    canvas2.element.style.transform = `translate(${shown.x}px, ${shown.y}px) scale(${shown.scale})`;
    if (canvas2.zoomLevelLabel) {
      canvas2.zoomLevelLabel.textContent = `${Math.round(canvas2.camera.scale * 100)}%`;
    }
  }
  function startBounceBack(canvas2) {
    if (canvas2.bouncingBack) return;
    let last = performance.now();
    const step = (now) => {
      canvas2.bouncingBack = false;
      if (canvas2.gesture) return;
      const camera = bounceBack({
        camera: canvas2.camera,
        elapsed: now - last,
        ...measure(canvas2)
      });
      last = now;
      moveCamera({ canvas: canvas2, camera, bouncing: true });
      if (isBouncing({ camera: canvas2.camera, ...measure(canvas2) })) {
        canvas2.bouncingBack = true;
        requestAnimationFrame(step);
      }
    };
    canvas2.bouncingBack = true;
    requestAnimationFrame(step);
  }
  function zoomAtPoint({
    canvas: canvas2,
    point,
    scale
  }) {
    const camera = zoomAt({
      camera: canvas2.camera,
      point,
      scale,
      ...measure(canvas2)
    });
    moveCamera({ canvas: canvas2, camera });
  }
  function zoomAtCenter({
    canvas: canvas2,
    scale
  }) {
    const { width, height } = measure(canvas2).viewport;
    zoomAtPoint({ canvas: canvas2, point: { x: width / 2, y: height / 2 }, scale });
  }
  function fitBoard(canvas2) {
    moveCamera({ canvas: canvas2, camera: fit(measure(canvas2)) });
  }
  function focusCard({ canvas: canvas2, id }) {
    const card = id && document.getElementById(id);
    if (!card || !canvas2.element.contains(card)) return false;
    const frame = {
      x: card.offsetLeft,
      y: card.offsetTop,
      width: card.offsetWidth,
      height: card.offsetHeight
    };
    moveCamera({ canvas: canvas2, camera: focus({ frame, ...measure(canvas2) }) });
    return true;
  }
  function windowPoint(event) {
    return { x: event.clientX, y: event.clientY };
  }
  function windowToViewport({
    canvas: canvas2,
    point
  }) {
    const { left, top } = canvas2.viewport.getBoundingClientRect();
    return { x: point.x - left, y: point.y - top };
  }

  // viewer/comment-dates.ts
  var MINUTE = 60 * 1e3;
  var HOUR = 60 * MINUTE;
  var DAY = 24 * HOUR;
  var SMALLEST = ["minute", MINUTE];
  var UNITS = [
    ["year", 365 * DAY],
    ["month", 30 * DAY],
    ["week", 7 * DAY],
    ["day", DAY],
    ["hour", HOUR],
    SMALLEST
  ];
  var relativeTime = new Intl.RelativeTimeFormat("en", { numeric: "auto" });
  function makeCommentDatesRelative(root) {
    const now = Date.now();
    for (const time of root.querySelectorAll(".comment time")) {
      const date = relativeDate({ written: Date.parse(time.dateTime), now });
      if (date) time.textContent = date;
    }
  }
  function relativeDate({
    written,
    now
  }) {
    const elapsed = now - written;
    if (!Number.isFinite(elapsed)) return null;
    const [unit, length] = UNITS.find(([, length2]) => elapsed >= length2) ?? SMALLEST;
    return relativeTime.format(-Math.trunc(elapsed / length), unit);
  }

  // viewer/copy-buttons.ts
  var COPIED_FOR = 1500;
  function setUpCopyButtons(canvas2) {
    canvas2.element.addEventListener("click", async (event) => {
      const button = event.target.closest(".copy");
      if (!button) return;
      const element = copyTargetElement(button);
      if (!element || !await copyText(element)) return;
      showCopied(button);
    });
  }
  function copyTargetElement(button) {
    const owner = button.parentElement;
    if (owner?.matches(".chain")) return owner;
    return owner?.querySelector(":scope > .body, :scope > .text") ?? null;
  }
  async function copyText(element) {
    try {
      await navigator.clipboard.writeText(textOf(element));
      return true;
    } catch {
      const selection = getSelection();
      if (!selection) return false;
      const range = document.createRange();
      range.selectNodeContents(element);
      selection.removeAllRanges();
      selection.addRange(range);
      const copied = document.execCommand("copy");
      selection.removeAllRanges();
      return copied;
    }
  }
  function textOf(element) {
    if (!element.matches(".chain")) return element.textContent;
    return [...element.querySelectorAll(":scope > p")].map((paragraph) => paragraph.textContent).join("\n");
  }
  function showCopied(button) {
    const mark = String(performance.now());
    button.dataset.copied = mark;
    button.setAttribute("aria-label", "Copied");
    setTimeout(() => {
      if (button.dataset.copied !== mark) return;
      delete button.dataset.copied;
      button.setAttribute("aria-label", "Copy text");
    }, COPIED_FOR);
  }

  // viewer/gestures.ts
  var DRAG_THRESHOLD = 4;
  var SELECTABLE_TEXT = ".world > .card--text > .body, .world > .comment > .text, .world > .chain";
  function setUpGestures(canvas2) {
    const { viewport } = canvas2;
    let pointers = /* @__PURE__ */ new Map();
    let suppressClick = false;
    let safariPinchStart = 1;
    viewport.addEventListener("gesturestart", (event) => {
      event.preventDefault();
      safariPinchStart = canvas2.camera.scale;
    });
    viewport.addEventListener("gesturechange", (event) => {
      event.preventDefault();
      if (pointers.size > 1) return;
      const point = windowToViewport({ canvas: canvas2, point: windowPoint(event) });
      zoomAtPoint({ canvas: canvas2, point, scale: safariPinchStart * event.scale });
    });
    viewport.addEventListener("pointerdown", (event) => {
      suppressClick = false;
      if (!startsGesture(event)) return;
      pointers = new Map(pointers).set(event.pointerId, windowPoint(event));
      canvas2.gesture = gestureFrom({
        camera: canvas2.camera,
        pointers,
        dragging: Boolean(canvas2.gesture?.dragging)
      });
    });
    viewport.addEventListener("pointermove", (event) => {
      const { gesture } = canvas2;
      if (!gesture || !pointers.has(event.pointerId)) return;
      pointers = new Map(pointers).set(event.pointerId, windowPoint(event));
      const points = [...pointers.values()];
      if (!gesture.dragging && !isPastDragThreshold({ gesture, points })) return;
      if (!gesture.dragging) {
        canvas2.gesture = { ...gesture, dragging: true };
        viewport.classList.add("is-dragging");
      }
      if (!viewport.hasPointerCapture(event.pointerId)) {
        viewport.setPointerCapture(event.pointerId);
      }
      const camera = gestureCamera({
        gesture,
        points,
        from: windowToViewport({ canvas: canvas2, point: gesture.center }),
        to: windowToViewport({ canvas: canvas2, point: midpoint(points) }),
        ...measure(canvas2)
      });
      moveCamera({ canvas: canvas2, camera, bouncing: true });
    });
    const endPointer = (event) => {
      if (!pointers.has(event.pointerId)) return;
      pointers = withoutPointer({ pointers, id: event.pointerId });
      if (pointers.size > 0) {
        canvas2.gesture = gestureFrom({
          camera: canvas2.camera,
          pointers,
          dragging: Boolean(canvas2.gesture?.dragging)
        });
        return;
      }
      suppressClick = Boolean(canvas2.gesture?.dragging);
      canvas2.gesture = null;
      viewport.classList.remove("is-dragging");
      startBounceBack(canvas2);
    };
    viewport.addEventListener("pointerup", endPointer);
    viewport.addEventListener("pointercancel", endPointer);
    viewport.addEventListener(
      "click",
      (event) => {
        if (!suppressClick) return;
        event.preventDefault();
        event.stopPropagation();
        suppressClick = false;
      },
      true
    );
    viewport.addEventListener("dragstart", (event) => event.preventDefault());
  }
  function startsGesture(event) {
    const target = event.target;
    const mouse = event.pointerType === "mouse";
    if (mouse && event.button !== 0) return false;
    if (target.closest("button, [popover]")) return false;
    return !(mouse && target.closest(SELECTABLE_TEXT));
  }
  function gestureFrom({
    camera,
    pointers,
    dragging
  }) {
    const points = [...pointers.values()];
    return {
      camera,
      center: midpoint(points),
      distance: spread(points),
      dragging: dragging || points.length > 1
    };
  }
  function isPastDragThreshold({
    gesture,
    points
  }) {
    const center = midpoint(points);
    const moved = Math.hypot(
      center.x - gesture.center.x,
      center.y - gesture.center.y
    );
    return moved >= DRAG_THRESHOLD;
  }
  function gestureCamera({
    gesture,
    points,
    from,
    to,
    viewport,
    contentBounds
  }) {
    const scale = points.length > 1 && gesture.distance > 0 ? clampScale({
      scale: gesture.camera.scale * spread(points) / gesture.distance,
      viewport,
      contentBounds
    }) : gesture.camera.scale;
    return pinch({ camera: gesture.camera, from, to, scale });
  }
  function withoutPointer({ pointers, id }) {
    return new Map([...pointers].filter(([pointer]) => pointer !== id));
  }
  function midpoint(points) {
    const x = points.reduce((sum, p) => sum + p.x, 0) / points.length;
    const y = points.reduce((sum, p) => sum + p.y, 0) / points.length;
    return { x, y };
  }
  function spread(points) {
    return points.length > 1 ? Math.hypot(points[0].x - points[1].x, points[0].y - points[1].y) : 0;
  }

  // viewer/linked-card-menus.ts
  var GAP = 6;
  var WINDOW_MARGIN = 16;
  function setUpLinkedCardMenus(canvas2) {
    canvas2.viewport.addEventListener("wheel", closeOpenMenus, { passive: true });
    for (const menu of document.querySelectorAll(".linked-menu")) {
      const button = document.querySelector(`[popovertarget="${menu.id}"]`);
      menu.addEventListener("beforetoggle", (event) => {
        if (event.newState !== "open" || !button) return;
        const to = initialMenuPosition({
          button: button.getBoundingClientRect()
        });
        moveMenu({ menu, to });
      });
      menu.addEventListener("toggle", (event) => {
        if (event.newState !== "open" || !button) return;
        const to = menuPosition({
          button: button.getBoundingClientRect(),
          menu: menu.getBoundingClientRect(),
          windowSize: { width: innerWidth, height: innerHeight }
        });
        moveMenu({ menu, to });
      });
      menu.addEventListener("click", (event) => {
        const link = event.target.closest("a");
        if (!link || link.pathname !== location.pathname) return;
        event.preventDefault();
        menu.hidePopover();
        history.replaceState(history.state, "", link.hash);
        focusCard({ canvas: canvas2, id: link.hash.slice(1) });
      });
    }
  }
  function initialMenuPosition({ button }) {
    return { x: Math.max(WINDOW_MARGIN, button.x), y: maxY(button) + GAP };
  }
  function menuPosition({
    button,
    menu,
    windowSize
  }) {
    const x = Math.max(
      WINDOW_MARGIN,
      Math.min(button.x, windowSize.width - menu.width - WINDOW_MARGIN)
    );
    const below = maxY(button) + GAP;
    const fitsBelow = below + menu.height <= windowSize.height - WINDOW_MARGIN;
    const above = Math.max(WINDOW_MARGIN, button.y - menu.height - GAP);
    return { x, y: fitsBelow ? below : above };
  }
  function closeOpenMenus() {
    for (const menu of document.querySelectorAll(
      ".linked-menu:popover-open"
    )) {
      menu.hidePopover();
    }
  }
  function moveMenu({ menu, to }) {
    menu.style.left = `${to.x}px`;
    menu.style.top = `${to.y}px`;
  }

  // viewer/breadcrumbs.ts
  function parseBreadcrumbs(value) {
    if (!Array.isArray(value)) return null;
    const breadcrumbs = value.map(parseBreadcrumb);
    return breadcrumbs.every((breadcrumb) => breadcrumb !== null) ? breadcrumbs : null;
  }
  function parseBreadcrumb(value) {
    if (!isRecord(value)) return null;
    const { href, label } = value;
    return typeof href === "string" && typeof label === "string" ? { href, label } : null;
  }
  function breadcrumbLinks(breadcrumbsElement) {
    return [
      ...breadcrumbsElement?.querySelectorAll(":scope > a") ?? []
    ];
  }
  function parentLink(breadcrumbsElement) {
    return breadcrumbsElement?.querySelector(
      ':scope > a[rel="up"]'
    ) ?? null;
  }
  function readBreadcrumbs(breadcrumbsElement) {
    return breadcrumbLinks(breadcrumbsElement).map((link) => ({
      href: link.href,
      label: link.textContent
    }));
  }
  function currentBoard(breadcrumbsElement) {
    return {
      href: location.href.split("#")[0],
      label: breadcrumbsElement?.querySelector(":scope > h1 > span")?.textContent ?? ""
    };
  }
  function showBreadcrumbs({
    breadcrumbsElement,
    breadcrumbs
  }) {
    const heading = breadcrumbsElement?.querySelector(":scope > h1");
    if (!heading) return;
    const shown = breadcrumbsElement.querySelectorAll(
      ":scope > a, :scope > .separator"
    );
    for (const element of shown) element.remove();
    breadcrumbs.forEach(({ href, label }, index) => {
      const link = document.createElement("a");
      link.href = href;
      link.textContent = label;
      if (index === breadcrumbs.length - 1) link.rel = "up";
      const separator = document.createElement("span");
      separator.className = "separator";
      separator.setAttribute("aria-hidden", "true");
      separator.textContent = "/";
      heading.before(link, separator);
    });
    markParent({ heading, parent: breadcrumbs.at(-1) });
  }
  function markParent({
    heading,
    parent
  }) {
    if (!parent) return;
    const path = new URL(parent.href).pathname;
    for (const link of heading.querySelectorAll(
      ".linked-menu a"
    )) {
      if (link.pathname === path) link.setAttribute("aria-current", "true");
      else link.removeAttribute("aria-current");
    }
  }

  // viewer/session.ts
  function readSession({
    key,
    parse
  }) {
    try {
      const item = sessionStorage.getItem(key);
      return item === null ? null : parse(JSON.parse(item));
    } catch {
      return null;
    }
  }
  function takeSession({
    key,
    parse
  }) {
    const value = readSession({ key, parse });
    try {
      sessionStorage.removeItem(key);
    } catch {
    }
    return value;
  }
  function writeSession({ key, value }) {
    try {
      sessionStorage.setItem(key, JSON.stringify(value));
    } catch {
    }
  }

  // viewer/navigation.ts
  var ARRIVAL_KEY = "arrival";
  function setUpNavigation() {
    const breadcrumbsElement = document.querySelector(".breadcrumbs");
    const recorded = takeSession({ key: ARRIVAL_KEY, parse: parseArrivalRecord });
    if (recorded?.path === location.pathname) {
      const { how, breadcrumbs: breadcrumbs2 } = recorded;
      history.replaceState({ ...history.state, arrival: how, breadcrumbs: breadcrumbs2 }, "");
    }
    const { breadcrumbs } = parseHistoryState(history.state);
    if (breadcrumbs) showBreadcrumbs({ breadcrumbsElement, breadcrumbs });
    const recordFollowing = (link) => {
      const followed = followedLink({ breadcrumbsElement, link });
      if (!followed) return;
      const arrival = arrivalFor({
        link: followed,
        breadcrumbs: readBreadcrumbs(breadcrumbsElement),
        current: currentBoard(breadcrumbsElement)
      });
      const path = new URL(link.href).pathname;
      writeSession({ key: ARRIVAL_KEY, value: { path, ...arrival } });
    };
    document.addEventListener("click", (event) => {
      const link = event.target.closest(
        "a[href]"
      );
      const modified = event.metaKey || event.ctrlKey || event.shiftKey || event.altKey;
      if (!link || link.target || modified || event.defaultPrevented) return;
      recordFollowing(link);
    });
    addEventListener("keydown", (event) => {
      const modified = event.altKey || event.ctrlKey || event.metaKey;
      if (event.key !== "Escape" || modified) return;
      if (document.querySelector(":popover-open")) return;
      const parent = parentLink(breadcrumbsElement);
      const target = escapeTarget({
        arrival: parseHistoryState(history.state).arrival,
        hasParent: parent !== null
      });
      if (target === "back") {
        history.back();
      } else if (target === "up" && parent) {
        recordFollowing(parent);
        location.href = parent.href;
      } else {
        return;
      }
      event.preventDefault();
    });
  }
  function arrivalFor({
    link,
    breadcrumbs,
    current
  }) {
    switch (link.kind) {
      case "breadcrumb":
        return { how: "up", breadcrumbs: breadcrumbs.slice(0, link.index) };
      case "heading menu":
        return { how: "up" };
      case "linked card menu":
        return { how: "across" };
      case "board card":
        return { how: "down", breadcrumbs: [...breadcrumbs, current] };
    }
  }
  function escapeTarget({
    arrival,
    hasParent
  }) {
    if (arrival === "down" || arrival === "across") return "back";
    return hasParent ? "up" : null;
  }
  function parseArrivalRecord(value) {
    if (!isRecord(value)) return null;
    const { path, how, breadcrumbs } = value;
    if (typeof path !== "string" || !isArrival(how)) return null;
    if (breadcrumbs === void 0) return { path, how };
    const parsed = parseBreadcrumbs(breadcrumbs);
    return parsed && { path, how, breadcrumbs: parsed };
  }
  function parseHistoryState(value) {
    if (!isRecord(value)) return {};
    const arrival = isArrival(value.arrival) ? value.arrival : void 0;
    const breadcrumbs = parseBreadcrumbs(value.breadcrumbs) ?? void 0;
    return { arrival, breadcrumbs };
  }
  function followedLink({
    breadcrumbsElement,
    link
  }) {
    const index = breadcrumbLinks(breadcrumbsElement).indexOf(link);
    if (index >= 0) return { kind: "breadcrumb", index };
    if (link.closest(".breadcrumbs")) return { kind: "heading menu" };
    if (link.closest(".linked-menu")) return { kind: "linked card menu" };
    if (link.matches(".panel")) return { kind: "board card" };
    return null;
  }
  function isArrival(value) {
    return value === "down" || value === "across" || value === "up";
  }

  // viewer/scrolling.ts
  var PUSH_TIME = 100;
  var SCROLL_PAUSE = 300;
  var ZOOM_PER_PIXEL = 0.01;
  var MAX_ZOOM_SCROLL = 50;
  function setUpScrolling(canvas2) {
    const noPush = { start: 0, slowest: 0 };
    let state = { last: 0, pushes: { x: noPush, y: noPush } };
    canvas2.viewport.addEventListener(
      "wheel",
      (event) => {
        event.preventDefault();
        const delta = scrollDelta({ canvas: canvas2, event });
        if (event.ctrlKey || event.metaKey) {
          zoomAtPointer({ canvas: canvas2, event, delta: delta.y });
        } else {
          state = pan({ canvas: canvas2, delta, state });
        }
      },
      { passive: false }
    );
  }
  function scrollDelta({
    canvas: canvas2,
    event
  }) {
    const unit = pixelsPerUnit({ canvas: canvas2, deltaMode: event.deltaMode });
    return { x: event.deltaX * unit, y: event.deltaY * unit };
  }
  function pixelsPerUnit({
    canvas: canvas2,
    deltaMode
  }) {
    switch (deltaMode) {
      case WheelEvent.DOM_DELTA_LINE:
        return 16;
      case WheelEvent.DOM_DELTA_PAGE:
        return canvas2.viewport.clientHeight;
      default:
        return 1;
    }
  }
  function zoomAtPointer({
    canvas: canvas2,
    event,
    delta
  }) {
    const point = windowToViewport({ canvas: canvas2, point: windowPoint(event) });
    const counted = clamp(delta, -MAX_ZOOM_SCROLL, MAX_ZOOM_SCROLL);
    const scale = canvas2.camera.scale * Math.exp(-counted * ZOOM_PER_PIXEL);
    zoomAtPoint({ canvas: canvas2, point, scale });
  }
  function pan({
    canvas: canvas2,
    delta,
    state
  }) {
    const now = performance.now();
    const paused = now - state.last > SCROLL_PAUSE;
    const limits = panLimits({ scale: canvas2.camera.scale, ...measure(canvas2) });
    const panned = (axis) => axisAfterScroll({
      position: canvas2.camera[axis],
      delta: delta[axis],
      limits: limits[axis],
      push: state.pushes[axis],
      now,
      paused
    });
    const x = panned("x");
    const y = panned("y");
    moveCamera({
      canvas: canvas2,
      camera: { ...canvas2.camera, x: x.position, y: y.position },
      bouncing: true
    });
    startBounceBack(canvas2);
    return { last: now, pushes: { x: x.push, y: y.push } };
  }
  function axisAfterScroll({
    position,
    delta,
    limits: [min, max],
    push,
    now,
    paused
  }) {
    const next = position - delta;
    if (next >= min && next <= max) {
      return { position: next, push: { ...push, start: 0 } };
    }
    const speed = Math.abs(delta);
    const pushesAnew = !push.start || paused || speed > 2 * push.slowest + 4;
    const started = pushesAnew ? { start: now, slowest: speed } : push;
    const pushed = { ...started, slowest: Math.min(started.slowest, speed) };
    const outward = Math.abs(next - clamp(next, min, max)) > Math.abs(position - clamp(position, min, max));
    const pushEnded = now - pushed.start > PUSH_TIME;
    return { position: outward && pushEnded ? position : next, push: pushed };
  }

  // viewer/starting-view.ts
  function setUpStartingView(canvas2) {
    const key = `camera:${location.pathname}`;
    addEventListener(
      "hashchange",
      () => focusCard({ canvas: canvas2, id: location.hash.slice(1) })
    );
    addEventListener(
      "pagehide",
      () => writeSession({ key, value: canvas2.camera })
    );
    if (focusCard({ canvas: canvas2, id: location.hash.slice(1) })) return;
    const saved = readSession({ key, parse: parseCamera });
    if (!saved) {
      fitBoard(canvas2);
      return;
    }
    const scale = clampScale({ scale: saved.scale, ...measure(canvas2) });
    moveCamera({ canvas: canvas2, camera: { ...saved, scale } });
  }

  // viewer/zoom-controls.ts
  var ZOOM_IN = 1.25;
  var ZOOM_OUT = 0.8;
  function setUpZoomControls(canvas2) {
    document.querySelector(".zoom")?.addEventListener("click", (event) => {
      const action = event.target.closest("[data-zoom]")?.dataset.zoom;
      const { scale } = canvas2.camera;
      if (action === "in") {
        zoomAtCenter({ canvas: canvas2, scale: scale * ZOOM_IN });
      } else if (action === "out") {
        zoomAtCenter({ canvas: canvas2, scale: scale * ZOOM_OUT });
      } else if (action === "home") {
        fitBoard(canvas2);
      }
    });
    addEventListener("keydown", (event) => {
      if (event.altKey) return;
      const { scale } = canvas2.camera;
      if (event.key === "+" || event.key === "=") {
        zoomAtCenter({ canvas: canvas2, scale: scale * ZOOM_IN });
      } else if (event.key === "-") {
        zoomAtCenter({ canvas: canvas2, scale: scale * ZOOM_OUT });
      } else if (event.key === "0") {
        zoomAtCenter({ canvas: canvas2, scale: 1 });
      } else if (event.shiftKey && event.code === "Digit1") {
        fitBoard(canvas2);
      } else {
        return;
      }
      event.preventDefault();
    });
  }

  // viewer/main.ts
  var canvas = setUpCanvas(document);
  if (!canvas) {
    throw new Error("The page has no board: no .viewport with a .world in it.");
  }
  document.documentElement.classList.add("js");
  setUpScrolling(canvas);
  setUpGestures(canvas);
  setUpZoomControls(canvas);
  makeCommentDatesRelative(document);
  setUpCopyButtons(canvas);
  setUpLinkedCardMenus(canvas);
  setUpNavigation();
  setUpStartingView(canvas);
})();
