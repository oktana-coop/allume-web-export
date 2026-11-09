import {
  bounce,
  bounceBack,
  fit,
  focus,
  isBouncing,
  withinLimits,
  zoomAt,
  type Camera,
} from './camera';
import { type Point, type Rect, type Size } from './geometry';

/** A drag or pinch, from where it started. */
export type Gesture = {
  camera: Camera;
  center: Point;
  distance: number;
  dragging: boolean;
};

/**
 * A board's canvas, the viewport showing it, where the camera is, and the zoom
 * level that shows its scale.
 */
export type Canvas = {
  viewport: HTMLElement;
  element: HTMLElement;
  zoomLevelLabel: HTMLElement | null;
  contentBounds: Rect;
  reducedMotion: boolean;
  camera: Camera;
  gesture: Gesture | null;
  bouncingBack: boolean;
};

/**
 * The canvas in the root, with the camera at the canvas's origin, or null if
 * there's none. Its viewport stops scrolling natively.
 */
export function setUpCanvas(root: ParentNode): Canvas | null {
  const viewport = root.querySelector<HTMLElement>('.allume-viewport');
  const element = viewport?.querySelector<HTMLElement>('.allume-canvas');
  if (!viewport || !element) return null;

  // The camera is a transform, so undo any native scrolling, such as the
  // browser scrolling to the #card- target.
  viewport.addEventListener('scroll', () => {
    viewport.scrollTop = 0;
    viewport.scrollLeft = 0;
  });

  const [minX, minY, maxX, maxY] = element.dataset
    .allumeBounds!.split(',')
    .map(Number);
  return {
    viewport,
    element,
    zoomLevelLabel: root.querySelector<HTMLElement>('.allume-zoom-level'),
    contentBounds: {
      x: minX,
      y: minY,
      width: maxX - minX,
      height: maxY - minY,
    },
    reducedMotion: matchMedia('(prefers-reduced-motion: reduce)').matches,
    camera: { x: 0, y: 0, scale: 1 },
    gesture: null,
    bouncingBack: false,
  };
}

/** The viewport's size, and the box around the board's contents. */
export function measure(canvas: Canvas): {
  viewport: Size;
  contentBounds: Rect;
} {
  const { clientWidth: width, clientHeight: height } = canvas.viewport;
  return { viewport: { width, height }, contentBounds: canvas.contentBounds };
}

/**
 * Moves the camera, within the pan limits, and the canvas with it, and shows
 * the zoom level. While bouncing, the camera may go past the limits, and the
 * board bounces past the edge.
 */
export function moveCamera({
  canvas,
  camera,
  bouncing = false,
}: {
  canvas: Canvas;
  camera: Camera;
  bouncing?: boolean;
}) {
  // Reduced motion turns bouncing off, so panning stops at the edges.
  const showBounce = bouncing && !canvas.reducedMotion;
  const shown = showBounce
    ? bounce({ camera, ...measure(canvas) })
    : withinLimits({ camera, ...measure(canvas) });

  canvas.camera = showBounce ? camera : shown;

  canvas.element.style.transform = `translate(${shown.x}px, ${shown.y}px) scale(${shown.scale})`;
  if (canvas.zoomLevelLabel) {
    canvas.zoomLevelLabel.textContent = `${Math.round(canvas.camera.scale * 100)}%`;
  }
}

/**
 * Brings a bouncing camera back within the pan limits, frame by frame, waiting
 * while a gesture holds it. Scrolling pushes against the pull, so the bounce
 * follows how hard you push, and trackpad momentum ends in a bounce.
 */
export function startBounceBack(canvas: Canvas) {
  if (canvas.bouncingBack) return;

  let last = performance.now();
  const step = (now: number) => {
    canvas.bouncingBack = false;
    if (canvas.gesture) return; // Until it's let go.

    const camera = bounceBack({
      camera: canvas.camera,
      elapsed: now - last,
      ...measure(canvas),
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

/**
 * Zooms to the scale, keeping the canvas point under the viewport point
 * there.
 */
export function zoomAtPoint({
  canvas,
  point,
  scale,
}: {
  canvas: Canvas;
  point: Point;
  scale: number;
}) {
  const camera = zoomAt({
    camera: canvas.camera,
    point,
    scale,
    ...measure(canvas),
  });
  moveCamera({ canvas, camera });
}

/** Zooms to the scale, keeping the viewport's center where it is. */
export function zoomAtCenter({
  canvas,
  scale,
}: {
  canvas: Canvas;
  scale: number;
}) {
  const { width, height } = measure(canvas).viewport;
  zoomAtPoint({ canvas, point: { x: width / 2, y: height / 2 }, scale });
}

/** Shows the whole board, from the canvas's origin. */
export function fitBoard(canvas: Canvas) {
  moveCamera({ canvas, camera: fit(measure(canvas)) });
}

/**
 * Centers the canvas's card with the element ID, returning whether the canvas
 * has one.
 */
export function focusCard({ canvas, id }: { canvas: Canvas; id: string }) {
  const card = id && document.getElementById(id);
  if (!card || !canvas.element.contains(card)) return false;

  const frame = {
    x: card.offsetLeft,
    y: card.offsetTop,
    width: card.offsetWidth,
    height: card.offsetHeight,
  };

  moveCamera({ canvas, camera: focus({ frame, ...measure(canvas) }) });
  return true;
}

/** Where the event happened, in the window. */
export function windowPoint(event: {
  clientX: number;
  clientY: number;
}): Point {
  return { x: event.clientX, y: event.clientY };
}

/** The point in the window, such as a pointer's, in the viewport. */
export function windowToViewport({
  canvas,
  point,
}: {
  canvas: Canvas;
  point: Point;
}): Point {
  const { left, top } = canvas.viewport.getBoundingClientRect();
  return { x: point.x - left, y: point.y - top };
}
