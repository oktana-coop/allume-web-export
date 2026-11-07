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
      const over = value < min ? value - min : value > max ? value - max : 0;
      return clamp(value, min, max) + MAX_BOUNCE * over / (Math.abs(over) + MAX_BOUNCE);
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
  function cardFrame({
    canvas,
    id
  }) {
    const card = id && document.getElementById(id);
    if (!card || !canvas.element.contains(card)) return null;
    return {
      x: card.offsetLeft,
      y: card.offsetTop,
      width: card.offsetWidth,
      height: card.offsetHeight
    };
  }

  // viewer/main.ts
  (() => {
    const canvas = setUpCanvas(document);
    if (!canvas) return;
    const { viewport } = canvas;
    document.documentElement.classList.add("js");
    const PUSH_TIME = 100;
    const SCROLL_PAUSE = 300;
    const DRAG_THRESHOLD = 4;
    const SELECTABLE_TEXT = ".world > .card--text > .body, .world > .comment > .text, .world > .chain";
    const zoomLevel = document.querySelector(".zoom-level");
    const cameraKey = `camera:${location.pathname}`;
    let lastWheel = 0;
    const pushes = { x: { start: 0, slowest: 0 }, y: { start: 0, slowest: 0 } };
    function apply({
      camera,
      bouncing = false
    }) {
      moveCamera({ canvas, camera, bouncing });
      if (zoomLevel) {
        zoomLevel.textContent = `${Math.round(canvas.camera.scale * 100)}%`;
      }
    }
    function home() {
      apply({ camera: fit(measure(canvas)) });
    }
    function zoomAtCenter(scale) {
      const measured = measure(canvas);
      const { width, height } = measured.viewport;
      const point = { x: width / 2, y: height / 2 };
      apply({
        camera: zoomAt({ camera: canvas.camera, point, scale, ...measured })
      });
    }
    function focusCard(id) {
      const frame = cardFrame({ canvas, id });
      if (!frame) return false;
      apply({ camera: focus({ frame, ...measure(canvas) }) });
      return true;
    }
    function closeMenus() {
      for (const menu of document.querySelectorAll(
        ".linked-menu:popover-open"
      )) {
        menu.hidePopover();
      }
    }
    function viewportPoint(clientX, clientY) {
      const { left, top } = viewport.getBoundingClientRect();
      return { x: clientX - left, y: clientY - top };
    }
    viewport.addEventListener(
      "wheel",
      (event) => {
        event.preventDefault();
        closeMenus();
        const unit = event.deltaMode === 1 ? 16 : event.deltaMode === 2 ? viewport.clientHeight : 1;
        if (event.ctrlKey || event.metaKey) {
          const delta = Math.max(-50, Math.min(50, event.deltaY * unit));
          const point = viewportPoint(event.clientX, event.clientY);
          const scale = canvas.camera.scale * Math.exp(-delta * 0.01);
          apply({
            camera: zoomAt({
              camera: canvas.camera,
              point,
              scale,
              ...measure(canvas)
            })
          });
        } else {
          const now = performance.now();
          const paused = now - lastWheel > SCROLL_PAUSE;
          lastWheel = now;
          const limits = panLimits({
            scale: canvas.camera.scale,
            ...measure(canvas)
          });
          const pan = (axis, delta) => {
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
            const outward = Math.abs(next - clamp(next, min, max)) > Math.abs(value - clamp(value, min, max));
            return outward && now - push.start > PUSH_TIME ? value : next;
          };
          apply({
            camera: {
              ...canvas.camera,
              x: pan("x", event.deltaX * unit),
              y: pan("y", event.deltaY * unit)
            },
            bouncing: true
          });
          startBounceBack(canvas);
        }
      },
      { passive: false }
    );
    let gestureStartScale = 1;
    viewport.addEventListener("gesturestart", (event) => {
      event.preventDefault();
      gestureStartScale = canvas.camera.scale;
    });
    viewport.addEventListener("gesturechange", (event) => {
      event.preventDefault();
      if (pointers.size > 1) return;
      const point = viewportPoint(event.clientX, event.clientY);
      const scale = gestureStartScale * event.scale;
      apply({
        camera: zoomAt({
          camera: canvas.camera,
          point,
          scale,
          ...measure(canvas)
        })
      });
    });
    const pointers = /* @__PURE__ */ new Map();
    let suppressClick = false;
    function midpoint(points) {
      const x = points.reduce((sum, p) => sum + p.x, 0) / points.length;
      const y = points.reduce((sum, p) => sum + p.y, 0) / points.length;
      return { x, y };
    }
    function spread(points) {
      return points.length > 1 ? Math.hypot(points[0].x - points[1].x, points[0].y - points[1].y) : 0;
    }
    function startGesture() {
      const points = [...pointers.values()];
      canvas.gesture = {
        camera: { ...canvas.camera },
        center: midpoint(points),
        distance: spread(points),
        dragging: Boolean(canvas.gesture?.dragging) || points.length > 1
      };
    }
    viewport.addEventListener("pointerdown", (event) => {
      suppressClick = false;
      if (event.pointerType === "mouse" && event.button !== 0) return;
      if (event.target.closest("button, [popover]")) return;
      if (event.pointerType === "mouse" && event.target.closest(SELECTABLE_TEXT)) {
        return;
      }
      pointers.set(event.pointerId, { x: event.clientX, y: event.clientY });
      startGesture();
    });
    viewport.addEventListener("pointermove", (event) => {
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
        viewport.classList.add("is-dragging");
      }
      if (!viewport.hasPointerCapture(event.pointerId)) {
        viewport.setPointerCapture(event.pointerId);
      }
      const scale = points.length > 1 && gesture.distance > 0 ? clampScale({
        scale: gesture.camera.scale * spread(points) / gesture.distance,
        ...measure(canvas)
      }) : gesture.camera.scale;
      const from = viewportPoint(gesture.center.x, gesture.center.y);
      const to = viewportPoint(center.x, center.y);
      apply({
        camera: pinch({ camera: gesture.camera, from, to, scale }),
        bouncing: true
      });
    });
    function endPointer(event) {
      if (!pointers.delete(event.pointerId)) return;
      if (pointers.size > 0) {
        startGesture();
        return;
      }
      suppressClick = Boolean(canvas.gesture?.dragging);
      canvas.gesture = null;
      viewport.classList.remove("is-dragging");
      startBounceBack(canvas);
    }
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
    document.querySelector(".zoom")?.addEventListener("click", (event) => {
      const action = event.target.closest("[data-zoom]")?.dataset.zoom;
      if (action === "in") zoomAtCenter(canvas.camera.scale * 1.25);
      else if (action === "out") zoomAtCenter(canvas.camera.scale * 0.8);
      else if (action === "home") home();
    });
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
      if (event.altKey) return;
      const command = event.ctrlKey || event.metaKey;
      if (event.key === "+" || event.key === "=")
        zoomAtCenter(canvas.camera.scale * 1.25);
      else if (event.key === "-") zoomAtCenter(canvas.camera.scale * 0.8);
      else if (event.key === "0") zoomAtCenter(1);
      else if (event.shiftKey && event.code === "Digit1") home();
      else if (event.key !== "Escape" || command || !goToParent()) return;
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
        focusCard(link.hash.slice(1));
      });
    }
    addEventListener("hashchange", () => focusCard(location.hash.slice(1)));
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
        apply({
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
    if (!focusCard(location.hash.slice(1)) && !restoreCamera()) home();
  })();
})();
