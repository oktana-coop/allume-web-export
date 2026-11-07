import { panLimits, type Interval } from './camera';
import {
  measure,
  moveCamera,
  startBounceBack,
  windowPoint,
  windowToViewport,
  zoomAtPoint,
  type Canvas,
} from './canvas';
import { clamp, type Point } from './geometry';

type Axis = 'x' | 'y';

/** A push past an edge: when it began, and its slowest scroll since. */
type Push = { start: number; slowest: number };

/** When the board was last scrolled, and each axis's push past an edge. */
type ScrollState = { last: number; pushes: Record<Axis, Push> };

// Past an edge, a scroll only pushes for PUSH_TIME. The rest of it, usually
// trackpad momentum, is ignored, so the board bounces back like on a Mac.
// A new push starts after panning clear of the edge, after a pause of
// SCROLL_PAUSE, or when scrolling picks up well beyond its slowest since the
// push began (momentum only slows, give or take some jitter).
const PUSH_TIME = 100;
const SCROLL_PAUSE = 300;
// A scroll zooms by 1% a pixel, compounding, and counts for at most
// MAX_ZOOM_SCROLL pixels.
const ZOOM_PER_PIXEL = 0.01;
const MAX_ZOOM_SCROLL = 50;

/**
 * Scrolling pans the board, and Ctrl/⌘+scroll, which trackpads send for a
 * pinch, zooms it at the pointer.
 */
export function setUpScrolling(canvas: Canvas) {
  const noPush = { start: 0, slowest: 0 };
  let state: ScrollState = { last: 0, pushes: { x: noPush, y: noPush } };

  canvas.viewport.addEventListener(
    'wheel',
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

/** How far the event scrolls, in pixels. */
function scrollDelta({
  canvas,
  event,
}: {
  canvas: Canvas;
  event: WheelEvent;
}): Point {
  const unit = pixelsPerUnit({ canvas, deltaMode: event.deltaMode });
  return { x: event.deltaX * unit, y: event.deltaY * unit };
}

/**
 * The pixels in a unit the event scrolls by: a line counts as 16, and a page
 * as the viewport's height.
 */
function pixelsPerUnit({
  canvas,
  deltaMode,
}: {
  canvas: Canvas;
  deltaMode: number;
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

/**
 * Zooms in at the pointer for a scroll up, as trackpads send for a pinch
 * apart, and out for a scroll down.
 */
function zoomAtPointer({
  canvas,
  event,
  delta,
}: {
  canvas: Canvas;
  event: WheelEvent;
  delta: number;
}) {
  const point = windowToViewport({ canvas, point: windowPoint(event) });
  const counted = clamp(delta, -MAX_ZOOM_SCROLL, MAX_ZOOM_SCROLL);
  const scale = canvas.camera.scale * Math.exp(-counted * ZOOM_PER_PIXEL);
  zoomAtPoint({ canvas, point, scale });
}

/**
 * Pans the board by the scroll, past an edge only while the push lasts, and
 * lets it bounce back. Returns the scroll state after the scroll.
 */
function pan({
  canvas,
  delta,
  state,
}: {
  canvas: Canvas;
  delta: Point;
  state: ScrollState;
}): ScrollState {
  const now = performance.now();
  const paused = now - state.last > SCROLL_PAUSE;

  const limits = panLimits({ scale: canvas.camera.scale, ...measure(canvas) });
  const panned = (axis: Axis) =>
    axisAfterScroll({
      position: canvas.camera[axis],
      delta: delta[axis],
      limits: limits[axis],
      push: state.pushes[axis],
      now,
      paused,
    });
  const x = panned('x');
  const y = panned('y');

  moveCamera({
    canvas,
    camera: { ...canvas.camera, x: x.position, y: y.position },
    bouncing: true,
  });
  startBounceBack(canvas);

  return { last: now, pushes: { x: x.push, y: y.push } };
}

/**
 * The camera's position along an axis after the scroll, and the axis's push:
 * within the pan limits, the scroll moves it all the way, and past them only
 * until the push ends.
 */
function axisAfterScroll({
  position,
  delta,
  limits: [min, max],
  push,
  now,
  paused,
}: {
  position: number;
  delta: number;
  limits: Interval;
  push: Push;
  now: number;
  paused: boolean;
}): { position: number; push: Push } {
  const next = position - delta;
  if (next >= min && next <= max) {
    return { position: next, push: { ...push, start: 0 } };
  }

  const speed = Math.abs(delta);
  const pushesAnew = !push.start || paused || speed > 2 * push.slowest + 4;
  const started = pushesAnew ? { start: now, slowest: speed } : push;
  const pushed = { ...started, slowest: Math.min(started.slowest, speed) };

  const outward =
    Math.abs(next - clamp(next, min, max)) >
    Math.abs(position - clamp(position, min, max));
  const pushEnded = now - pushed.start > PUSH_TIME;
  return { position: outward && pushEnded ? position : next, push: pushed };
}
