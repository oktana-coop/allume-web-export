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

  // viewer/camera.ts
  var MIN_SCALE = 0.5;
  var MAX_SCALE = 4;
  var PAN_MARGIN = 120;
  var MAX_BOUNCE = 80;
  var SPRING = 0.8;
  var FOCUS_PADDING = 80;
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
  var reducedMotion = matchMedia("(prefers-reduced-motion: reduce)").matches;
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
      camera: { x: 0, y: 0, scale: 1 },
      gesture: null,
      bouncingBack: false
    };
  }
  function measure(canvas) {
    const { clientWidth: width, clientHeight: height } = canvas.viewport;
    return { viewport: { width, height }, contentBounds: canvas.contentBounds };
  }
  function moveCamera({
    canvas,
    camera,
    bouncing = false
  }) {
    const showBounce = bouncing && !reducedMotion;
    const shown = showBounce ? bounce({ camera, ...measure(canvas) }) : withinLimits({ camera, ...measure(canvas) });
    canvas.camera = showBounce ? camera : shown;
    canvas.element.style.transform = `translate(${shown.x}px, ${shown.y}px) scale(${shown.scale})`;
    if (canvas.zoomLevelLabel) {
      canvas.zoomLevelLabel.textContent = `${Math.round(canvas.camera.scale * 100)}%`;
    }
  }
  function startBounceBack(canvas) {
    if (canvas.bouncingBack) return;
    let last = performance.now();
    const step = (now) => {
      canvas.bouncingBack = false;
      if (canvas.gesture) return;
      const camera = bounceBack({
        camera: canvas.camera,
        elapsed: now - last,
        ...measure(canvas)
      });
      last = now;
      moveCamera({ canvas, camera, bouncing: true });
      if (isBouncing({ camera: canvas.camera, ...measure(canvas) })) {
        canvas.bouncingBack = true;
        requestAnimationFrame(step);
      }
    };
    canvas.bouncingBack = true;
    requestAnimationFrame(step);
  }
  function zoomAtPoint({
    canvas,
    point,
    scale
  }) {
    const camera = zoomAt({
      camera: canvas.camera,
      point,
      scale,
      ...measure(canvas)
    });
    moveCamera({ canvas, camera });
  }
  function zoomAtCenter({
    canvas,
    scale
  }) {
    const { width, height } = measure(canvas).viewport;
    zoomAtPoint({ canvas, point: { x: width / 2, y: height / 2 }, scale });
  }
  function fitBoard(canvas) {
    moveCamera({ canvas, camera: fit(measure(canvas)) });
  }
  function focusCard({ canvas, id }) {
    const card = id && document.getElementById(id);
    if (!card || !canvas.element.contains(card)) return false;
    const frame = {
      x: card.offsetLeft,
      y: card.offsetTop,
      width: card.offsetWidth,
      height: card.offsetHeight
    };
    moveCamera({ canvas, camera: focus({ frame, ...measure(canvas) }) });
    return true;
  }
  function windowPoint(event) {
    return { x: event.clientX, y: event.clientY };
  }
  function windowToViewport({
    canvas,
    point
  }) {
    const { left, top } = canvas.viewport.getBoundingClientRect();
    return { x: point.x - left, y: point.y - top };
  }

  // viewer/gestures.ts
  var DRAG_THRESHOLD = 4;
  var SELECTABLE_TEXT = ".world > .card--text > .body, .world > .comment > .text, .world > .chain";
  function setUpGestures(canvas) {
    const { viewport } = canvas;
    let pointers = /* @__PURE__ */ new Map();
    let suppressClick = false;
    let safariPinchStart = 1;
    viewport.addEventListener("gesturestart", (event) => {
      event.preventDefault();
      safariPinchStart = canvas.camera.scale;
    });
    viewport.addEventListener("gesturechange", (event) => {
      event.preventDefault();
      if (pointers.size > 1) return;
      const point = windowToViewport({ canvas, point: windowPoint(event) });
      zoomAtPoint({ canvas, point, scale: safariPinchStart * event.scale });
    });
    viewport.addEventListener("pointerdown", (event) => {
      suppressClick = false;
      if (!startsGesture(event)) return;
      pointers = new Map(pointers).set(event.pointerId, windowPoint(event));
      canvas.gesture = gestureFrom({
        camera: canvas.camera,
        pointers,
        dragging: Boolean(canvas.gesture?.dragging)
      });
    });
    viewport.addEventListener("pointermove", (event) => {
      const { gesture } = canvas;
      if (!gesture || !pointers.has(event.pointerId)) return;
      pointers = new Map(pointers).set(event.pointerId, windowPoint(event));
      const points = [...pointers.values()];
      if (!gesture.dragging && !isPastDragThreshold({ gesture, points })) return;
      if (!gesture.dragging) {
        canvas.gesture = { ...gesture, dragging: true };
        viewport.classList.add("is-dragging");
      }
      if (!viewport.hasPointerCapture(event.pointerId)) {
        viewport.setPointerCapture(event.pointerId);
      }
      const camera = gestureCamera({
        gesture,
        points,
        from: windowToViewport({ canvas, point: gesture.center }),
        to: windowToViewport({ canvas, point: midpoint(points) }),
        ...measure(canvas)
      });
      moveCamera({ canvas, camera, bouncing: true });
    });
    const endPointer = (event) => {
      if (!pointers.has(event.pointerId)) return;
      pointers = withoutPointer({ pointers, id: event.pointerId });
      if (pointers.size > 0) {
        canvas.gesture = gestureFrom({
          camera: canvas.camera,
          pointers,
          dragging: Boolean(canvas.gesture?.dragging)
        });
        return;
      }
      suppressClick = Boolean(canvas.gesture?.dragging);
      canvas.gesture = null;
      viewport.classList.remove("is-dragging");
      startBounceBack(canvas);
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

  // viewer/scrolling.ts
  var PUSH_TIME = 100;
  var SCROLL_PAUSE = 300;
  var ZOOM_PER_PIXEL = 0.01;
  var MAX_ZOOM_SCROLL = 50;
  function setUpScrolling(canvas) {
    const noPush = { start: 0, slowest: 0 };
    let state = { last: 0, pushes: { x: noPush, y: noPush } };
    canvas.viewport.addEventListener(
      "wheel",
      (event) => {
        event.preventDefault();
        const delta = scrollDelta({ canvas, event });
        if (event.ctrlKey || event.metaKey) {
          zoomAtPointer({ canvas, event, delta: delta.y });
        } else {
          state = pan({ canvas, delta, state });
        }
      },
      { passive: false }
    );
  }
  function scrollDelta({
    canvas,
    event
  }) {
    const unit = pixelsPerUnit({ canvas, deltaMode: event.deltaMode });
    return { x: event.deltaX * unit, y: event.deltaY * unit };
  }
  function pixelsPerUnit({
    canvas,
    deltaMode
  }) {
    switch (deltaMode) {
      case WheelEvent.DOM_DELTA_LINE:
        return 16;
      case WheelEvent.DOM_DELTA_PAGE:
        return canvas.viewport.clientHeight;
      default:
        return 1;
    }
  }
  function zoomAtPointer({
    canvas,
    event,
    delta
  }) {
    const point = windowToViewport({ canvas, point: windowPoint(event) });
    const counted = clamp(delta, -MAX_ZOOM_SCROLL, MAX_ZOOM_SCROLL);
    const scale = canvas.camera.scale * Math.exp(-counted * ZOOM_PER_PIXEL);
    zoomAtPoint({ canvas, point, scale });
  }
  function pan({
    canvas,
    delta,
    state
  }) {
    const now = performance.now();
    const paused = now - state.last > SCROLL_PAUSE;
    const limits = panLimits({ scale: canvas.camera.scale, ...measure(canvas) });
    const panned = (axis) => axisAfterScroll({
      position: canvas.camera[axis],
      delta: delta[axis],
      limits: limits[axis],
      push: state.pushes[axis],
      now,
      paused
    });
    const x = panned("x");
    const y = panned("y");
    moveCamera({
      canvas,
      camera: { ...canvas.camera, x: x.position, y: y.position },
      bouncing: true
    });
    startBounceBack(canvas);
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

  // viewer/zoom-controls.ts
  var ZOOM_IN = 1.25;
  var ZOOM_OUT = 0.8;
  function setUpZoomControls(canvas) {
    document.querySelector(".zoom")?.addEventListener("click", (event) => {
      const action = event.target.closest("[data-zoom]")?.dataset.zoom;
      const { scale } = canvas.camera;
      if (action === "in") {
        zoomAtCenter({ canvas, scale: scale * ZOOM_IN });
      } else if (action === "out") {
        zoomAtCenter({ canvas, scale: scale * ZOOM_OUT });
      } else if (action === "home") {
        fitBoard(canvas);
      }
    });
    addEventListener("keydown", (event) => {
      if (event.altKey) return;
      const { scale } = canvas.camera;
      if (event.key === "+" || event.key === "=") {
        zoomAtCenter({ canvas, scale: scale * ZOOM_IN });
      } else if (event.key === "-") {
        zoomAtCenter({ canvas, scale: scale * ZOOM_OUT });
      } else if (event.key === "0") {
        zoomAtCenter({ canvas, scale: 1 });
      } else if (event.shiftKey && event.code === "Digit1") {
        fitBoard(canvas);
      } else {
        return;
      }
      event.preventDefault();
    });
  }

  // viewer/main.ts
  (() => {
    const canvas = setUpCanvas(document);
    if (!canvas) return;
    document.documentElement.classList.add("js");
    const cameraKey = `camera:${location.pathname}`;
    setUpScrolling(canvas);
    setUpGestures(canvas);
    setUpZoomControls(canvas);
    canvas.viewport.addEventListener("wheel", closeMenus, { passive: true });
    function closeMenus() {
      for (const menu of document.querySelectorAll(
        ".linked-menu:popover-open"
      )) {
        menu.hidePopover();
      }
    }
    const relativeTime = new Intl.RelativeTimeFormat("en", { numeric: "auto" });
    const DAY = 24 * 60 * 60 * 1e3;
    const UNITS = [
      ["year", 365 * DAY],
      ["month", 30 * DAY],
      ["week", 7 * DAY],
      ["day", DAY],
      ["hour", DAY / 24],
      ["minute", DAY / 1440]
    ];
    for (const time of document.querySelectorAll(
      ".comment time"
    )) {
      const elapsed = Date.now() - Date.parse(time.dateTime);
      if (!Number.isFinite(elapsed)) continue;
      const [unit, length] = UNITS.find(([, length2]) => elapsed >= length2) ?? UNITS.at(-1);
      time.textContent = relativeTime.format(-Math.trunc(elapsed / length), unit);
    }
    const copiedTimers = /* @__PURE__ */ new WeakMap();
    canvas.element.addEventListener("click", async (event) => {
      const button = event.target.closest(".copy");
      const owner = button?.parentElement;
      const source = owner?.matches(".chain") ? owner : owner?.querySelector(":scope > .body, :scope > .text");
      if (!source || !await copyText(source)) return;
      button.dataset.copied = "";
      button.setAttribute("aria-label", "Copied");
      clearTimeout(copiedTimers.get(button));
      copiedTimers.set(
        button,
        setTimeout(() => {
          delete button.dataset.copied;
          button.setAttribute("aria-label", "Copy text");
        }, 1500)
      );
    });
    async function copyText(element) {
      try {
        await navigator.clipboard.writeText(textOf(element));
        return true;
      } catch {
        const selection = getSelection();
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
    addEventListener("keydown", (event) => {
      const modified = event.altKey || event.ctrlKey || event.metaKey;
      if (event.key !== "Escape" || modified || !goToParent()) return;
      event.preventDefault();
    });
    function goToParent() {
      if (document.querySelector(":popover-open")) return false;
      const { arrival } = history.state ?? {};
      if (arrival === "down" || arrival === "across") {
        history.back();
        return true;
      }
      const parent = breadcrumbs?.querySelector(
        ':scope > a[rel="up"]'
      );
      if (!parent) return false;
      recordArrival(parent.href, "up", breadcrumbTrail().slice(0, -1));
      location.href = parent.href;
      return true;
    }
    const breadcrumbs = document.querySelector(".crumbs");
    function breadcrumbLinks() {
      return [
        ...breadcrumbs?.querySelectorAll(":scope > a") ?? []
      ];
    }
    function breadcrumbTrail() {
      return breadcrumbLinks().map((link) => ({
        href: link.href,
        label: link.textContent
      }));
    }
    function showTrail(trail) {
      const heading = breadcrumbs?.querySelector(":scope > h1");
      if (!heading) return;
      const shown = breadcrumbs.querySelectorAll(
        ":scope > a, :scope > .separator"
      );
      for (const element of shown) element.remove();
      trail.forEach(({ href, label }, index) => {
        const link = document.createElement("a");
        link.href = href;
        link.textContent = label;
        if (index === trail.length - 1) link.rel = "up";
        const separator = document.createElement("span");
        separator.className = "separator";
        separator.setAttribute("aria-hidden", "true");
        separator.textContent = "/";
        heading.before(link, separator);
      });
      markParent(heading, trail.at(-1));
    }
    function markParent(heading, parent) {
      if (!parent) return;
      const path = new URL(parent.href).pathname;
      for (const link of heading.querySelectorAll(
        ".linked-menu a"
      )) {
        if (link.pathname === path) link.setAttribute("aria-current", "true");
        else link.removeAttribute("aria-current");
      }
    }
    const ARRIVAL_KEY = "arrival";
    document.addEventListener("click", (event) => {
      const link = event.target.closest(
        "a[href]"
      );
      const modified = event.metaKey || event.ctrlKey || event.shiftKey || event.altKey;
      if (!link || link.target || modified || event.defaultPrevented) return;
      const breadcrumb = breadcrumbLinks().indexOf(link);
      if (breadcrumb >= 0) {
        recordArrival(link.href, "up", breadcrumbTrail().slice(0, breadcrumb));
      } else if (link.closest(".crumbs")) {
        recordArrival(link.href, "up");
      } else if (link.closest(".linked-menu")) {
        recordArrival(link.href, "across");
      } else if (link.matches(".panel")) {
        const here = {
          href: location.href.split("#")[0],
          label: breadcrumbs?.querySelector(":scope > h1 > span")?.textContent ?? ""
        };
        recordArrival(link.href, "down", [...breadcrumbTrail(), here]);
      }
    });
    function recordArrival(url, how, trail) {
      try {
        const path = new URL(url).pathname;
        sessionStorage.setItem(ARRIVAL_KEY, JSON.stringify({ path, how, trail }));
      } catch {
      }
    }
    try {
      const arrival = JSON.parse(sessionStorage.getItem(ARRIVAL_KEY));
      sessionStorage.removeItem(ARRIVAL_KEY);
      if (arrival?.path === location.pathname) {
        const { how, trail } = arrival;
        history.replaceState({ ...history.state, arrival: how, trail }, "");
      }
    } catch {
    }
    if (history.state?.trail) showTrail(history.state.trail);
    for (const menu of document.querySelectorAll(".linked-menu")) {
      const button = document.querySelector(`[popovertarget="${menu.id}"]`);
      menu.addEventListener("beforetoggle", (event) => {
        if (event.newState !== "open" || !button) return;
        const anchor = button.getBoundingClientRect();
        menu.style.left = `${Math.max(16, anchor.left)}px`;
        menu.style.top = `${anchor.bottom + 6}px`;
      });
      menu.addEventListener("toggle", (event) => {
        if (event.newState !== "open" || !button) return;
        const anchor = button.getBoundingClientRect();
        const { width, height } = menu.getBoundingClientRect();
        const left = Math.max(16, Math.min(anchor.left, innerWidth - width - 16));
        const below = anchor.bottom + 6;
        const top = below + height > innerHeight - 16 ? Math.max(16, anchor.top - height - 6) : below;
        menu.style.left = `${left}px`;
        menu.style.top = `${top}px`;
      });
      menu.addEventListener("click", (event) => {
        const link = event.target.closest("a");
        if (!link || link.pathname !== location.pathname) return;
        event.preventDefault();
        menu.hidePopover();
        history.replaceState(history.state, "", link.hash);
        focusCard({ canvas, id: link.hash.slice(1) });
      });
    }
    addEventListener(
      "hashchange",
      () => focusCard({ canvas, id: location.hash.slice(1) })
    );
    addEventListener("pagehide", () => {
      try {
        sessionStorage.setItem(cameraKey, JSON.stringify(canvas.camera));
      } catch {
      }
    });
    function restoreCamera() {
      try {
        const saved = JSON.parse(sessionStorage.getItem(cameraKey));
        if (![saved?.x, saved?.y, saved?.scale].every(Number.isFinite)) {
          return false;
        }
        moveCamera({
          canvas,
          camera: {
            ...saved,
            scale: clampScale({ scale: saved.scale, ...measure(canvas) })
          }
        });
        return true;
      } catch {
        return false;
      }
    }
    const card = location.hash.slice(1);
    if (!focusCard({ canvas, id: card }) && !restoreCamera()) fitBoard(canvas);
  })();
})();
