import { clampScale, pinch, type Camera } from './camera';
import {
  measure,
  moveCamera,
  startBounceBack,
  windowPoint,
  windowToViewport,
  zoomAtPoint,
  type Canvas,
  type Gesture,
} from './canvas';
import { type Point, type Rect, type Size } from './geometry';

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

/** Where each pointer pressing on the board is in the window, by its ID. */
type Pointers = ReadonlyMap<number, Point>;

const DRAG_THRESHOLD = 4;
const SELECTABLE_TEXT =
  '.world > .card--text > .body, .world > .comment > .text, .world > .chain';

/**
 * Dragging with one pointer pans; pinching with two zooms, as does Safari's
 * trackpad pinch. A press that doesn't move is left alone, so links and
 * buttons still work, and a mouse drag that starts on text selects the text
 * instead.
 */
export function setUpGestures(canvas: Canvas) {
  const { viewport } = canvas;
  let pointers: Pointers = new Map();
  let suppressClick = false;
  let safariPinchStart = 1;

  // Safari reports trackpad pinches as gesture events instead.
  viewport.addEventListener('gesturestart', (event) => {
    event.preventDefault();
    safariPinchStart = canvas.camera.scale;
  });

  viewport.addEventListener('gesturechange', (event) => {
    event.preventDefault();
    if (pointers.size > 1) return; // Touch pinches are handled below.

    const point = windowToViewport({ canvas, point: windowPoint(event) });
    zoomAtPoint({ canvas, point, scale: safariPinchStart * event.scale });
  });

  viewport.addEventListener('pointerdown', (event) => {
    suppressClick = false;
    if (!startsGesture(event)) return;

    pointers = new Map(pointers).set(event.pointerId, windowPoint(event));
    canvas.gesture = gestureFrom({
      camera: canvas.camera,
      pointers,
      dragging: Boolean(canvas.gesture?.dragging),
    });
  });

  viewport.addEventListener('pointermove', (event) => {
    const { gesture } = canvas;
    if (!gesture || !pointers.has(event.pointerId)) return;

    pointers = new Map(pointers).set(event.pointerId, windowPoint(event));
    const points = [...pointers.values()];
    if (!gesture.dragging && !isPastDragThreshold({ gesture, points })) return;

    if (!gesture.dragging) {
      canvas.gesture = { ...gesture, dragging: true };
      viewport.classList.add('is-dragging');
    }
    if (!viewport.hasPointerCapture(event.pointerId)) {
      viewport.setPointerCapture(event.pointerId);
    }

    const camera = gestureCamera({
      gesture,
      points,
      from: windowToViewport({ canvas, point: gesture.center }),
      to: windowToViewport({ canvas, point: midpoint(points) }),
      ...measure(canvas),
    });
    moveCamera({ canvas, camera, bouncing: true });
  });

  const endPointer = (event: PointerEvent) => {
    if (!pointers.has(event.pointerId)) return;

    pointers = withoutPointer({ pointers, id: event.pointerId });
    if (pointers.size > 0) {
      canvas.gesture = gestureFrom({
        camera: canvas.camera,
        pointers,
        dragging: Boolean(canvas.gesture?.dragging),
      });
      return;
    }

    suppressClick = Boolean(canvas.gesture?.dragging);
    canvas.gesture = null;
    viewport.classList.remove('is-dragging');
    startBounceBack(canvas);
  };
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
}

/**
 * Whether the press starts a gesture: only a mouse's main button does, and not
 * on a button, a menu, or for a mouse, text.
 */
function startsGesture(event: PointerEvent) {
  const target = event.target as Element;
  const mouse = event.pointerType === 'mouse';
  if (mouse && event.button !== 0) return false;
  if (target.closest('button, [popover]')) return false;
  return !(mouse && target.closest(SELECTABLE_TEXT));
}

/**
 * A gesture starting from the camera with the pointers where they are. It's a
 * drag if it already was one, or if two pointers pinch.
 */
function gestureFrom({
  camera,
  pointers,
  dragging,
}: {
  camera: Camera;
  pointers: Pointers;
  dragging: boolean;
}): Gesture {
  const points = [...pointers.values()];
  return {
    camera,
    center: midpoint(points),
    distance: spread(points),
    dragging: dragging || points.length > 1,
  };
}

/** Whether the pointers, at the points, have moved far enough to drag. */
function isPastDragThreshold({
  gesture,
  points,
}: {
  gesture: Gesture;
  points: Point[];
}) {
  const center = midpoint(points);
  const moved = Math.hypot(
    center.x - gesture.center.x,
    center.y - gesture.center.y
  );
  return moved >= DRAG_THRESHOLD;
}

/**
 * The camera for the gesture with its pointers at the points: the board point
 * that started under them, at `from` in the viewport, is under them at `to`,
 * and two pointers zoom as far as they've spread apart.
 */
function gestureCamera({
  gesture,
  points,
  from,
  to,
  viewport,
  contentBounds,
}: {
  gesture: Gesture;
  points: Point[];
  from: Point;
  to: Point;
  viewport: Size;
  contentBounds: Rect;
}): Camera {
  const scale =
    points.length > 1 && gesture.distance > 0
      ? clampScale({
          scale: (gesture.camera.scale * spread(points)) / gesture.distance,
          viewport,
          contentBounds,
        })
      : gesture.camera.scale;
  return pinch({ camera: gesture.camera, from, to, scale });
}

function withoutPointer({ pointers, id }: { pointers: Pointers; id: number }) {
  return new Map([...pointers].filter(([pointer]) => pointer !== id));
}

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
