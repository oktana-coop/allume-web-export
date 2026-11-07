import {
  bounce,
  bounceBack,
  isBouncing,
  withinLimits,
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

/** A board's canvas, the viewport showing it, and where the camera is. */
export type Canvas = {
  viewport: HTMLElement;
  element: HTMLElement;
  contentBounds: Rect;
  camera: Camera;
  gesture: Gesture | null;
  bouncingBack: boolean;
};

// Reduced motion turns bouncing off, so panning stops at the edges.
const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;

/**
 * The canvas in the root, with the camera at the canvas's origin, or null if
 * there's none. Its viewport stops scrolling natively.
 */
export function setUpCanvas(root: ParentNode): Canvas | null {
  const viewport = root.querySelector<HTMLElement>('.viewport');
  const element = viewport?.querySelector<HTMLElement>('.world');
  if (!viewport || !element) return null;

  // The camera is a transform, so undo any native scrolling, such as the
  // browser scrolling to the #card- target.
  viewport.addEventListener('scroll', () => {
    viewport.scrollTop = 0;
    viewport.scrollLeft = 0;
  });

  const [minX, minY, maxX, maxY] = element.dataset
    .bounds!.split(',')
    .map(Number);
  return {
    viewport,
    element,
    contentBounds: {
      x: minX,
      y: minY,
      width: maxX - minX,
      height: maxY - minY,
    },
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
 * Moves the camera, within the pan limits, and the canvas with it. While
 * bouncing, the camera may go past the limits, and the board bounces past the
 * edge.
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
  const showBounce = bouncing && !reducedMotion;
  const shown = showBounce
    ? bounce({ camera, ...measure(canvas) })
    : withinLimits({ camera, ...measure(canvas) });
  canvas.camera = showBounce ? camera : shown;
  canvas.element.style.transform = `translate(${shown.x}px, ${shown.y}px) scale(${shown.scale})`;
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

/** The frame of the canvas's card with the element ID, or null without one. */
export function cardFrame({
  canvas,
  id,
}: {
  canvas: Canvas;
  id: string;
}): Rect | null {
  const card = id && document.getElementById(id);
  if (!card || !canvas.element.contains(card)) return null;
  return {
    x: card.offsetLeft,
    y: card.offsetTop,
    width: card.offsetWidth,
    height: card.offsetHeight,
  };
}
