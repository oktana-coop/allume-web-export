import {
  clamp,
  maxX,
  maxY,
  type Point,
  type Rect,
  type Size,
} from './geometry';

/** The canvas's offset in the viewport, in pixels, and its scale. */
export type Camera = { x: number; y: number; scale: number };

export type Interval = [min: number, max: number];

// Zooming out stops at 50%, or lower when the whole board needs it to fit.
const MIN_SCALE = 0.5;
const MAX_SCALE = 4;
// Panning stops while this much of the board's contents is still in view.
// Pulling further bounces the board past the edge, by at most MAX_BOUNCE, and
// it bounces back keeping SPRING of the bounce each frame (at 60 fps).
const PAN_MARGIN = 120;
const MAX_BOUNCE = 80;
const SPRING = 0.8;
const FOCUS_PADDING = 80;

/**
 * The scale that frames the board the way its card previews it: from the
 * canvas's origin, with everything in view, at most 100%.
 */
export function fitScale({
  viewport,
  contentBounds,
}: {
  viewport: Size;
  contentBounds: Rect;
}) {
  return Math.min(
    1,
    viewport.width / (maxX(contentBounds) + contentBounds.x),
    viewport.height / (maxY(contentBounds) + contentBounds.y)
  );
}

/** The scale within the zoom limits. */
export function clampScale({
  scale,
  viewport,
  contentBounds,
}: {
  scale: number;
  viewport: Size;
  contentBounds: Rect;
}) {
  const fit = fitScale({ viewport, contentBounds });
  return clamp(scale, Math.min(MIN_SCALE, fit), MAX_SCALE);
}

/** The camera that shows the whole board, from the canvas's origin. */
export function fit({
  viewport,
  contentBounds,
}: {
  viewport: Size;
  contentBounds: Rect;
}): Camera {
  return { x: 0, y: 0, scale: fitScale({ viewport, contentBounds }) };
}

/**
 * The camera that centers the frame, with FOCUS_PADDING around it, at no more
 * than 100%.
 */
export function focus({
  frame,
  viewport,
  contentBounds,
}: {
  frame: Rect;
  viewport: Size;
  contentBounds: Rect;
}): Camera {
  const { width, height } = viewport;
  const scale = clampScale({
    scale: Math.min(
      1,
      (width - FOCUS_PADDING * 2) / frame.width,
      (height - FOCUS_PADDING * 2) / frame.height
    ),
    viewport,
    contentBounds,
  });
  return {
    x: width / 2 - (frame.x + frame.width / 2) * scale,
    y: height / 2 - (frame.y + frame.height / 2) * scale,
    scale,
  };
}

/**
 * The camera at the scale, within the zoom limits, with the canvas point under
 * the viewport point kept there.
 */
export function zoomAt({
  camera,
  point,
  scale,
  viewport,
  contentBounds,
}: {
  camera: Camera;
  point: Point;
  scale: number;
  viewport: Size;
  contentBounds: Rect;
}): Camera {
  return pinch({
    camera,
    from: point,
    to: point,
    scale: clampScale({ scale, viewport, contentBounds }),
  });
}

/**
 * The camera at the scale that moves the canvas point under the viewport point
 * `from` to under `to`.
 */
export function pinch({
  camera,
  from,
  to,
  scale,
}: {
  camera: Camera;
  from: Point;
  to: Point;
  scale: number;
}): Camera {
  const ratio = scale / camera.scale;
  return {
    x: to.x - (from.x - camera.x) * ratio,
    y: to.y - (from.y - camera.y) * ratio,
    scale,
  };
}

/** The camera positions, at the scale, that keep PAN_MARGIN of the board in view. */
export function panLimits({
  scale,
  viewport,
  contentBounds,
}: {
  scale: number;
  viewport: Size;
  contentBounds: Rect;
}): { x: Interval; y: Interval } {
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
      viewport.width - marginX - contentBounds.x * scale,
    ],
    y: [
      marginY - maxY(contentBounds) * scale,
      viewport.height - marginY - contentBounds.y * scale,
    ],
  };
}

/** The camera within the pan limits. */
export function withinLimits({
  camera,
  viewport,
  contentBounds,
}: {
  camera: Camera;
  viewport: Size;
  contentBounds: Rect;
}): Camera {
  const limits = panLimits({ scale: camera.scale, viewport, contentBounds });
  return {
    x: clamp(camera.x, ...limits.x),
    y: clamp(camera.y, ...limits.y),
    scale: camera.scale,
  };
}

/** Whether the camera is past the pan limits. */
export function isBouncing({
  camera,
  viewport,
  contentBounds,
}: {
  camera: Camera;
  viewport: Size;
  contentBounds: Rect;
}) {
  const within = withinLimits({ camera, viewport, contentBounds });
  return camera.x !== within.x || camera.y !== within.y;
}

/**
 * Where a camera pulled past the pan limits is drawn: the further it's pulled,
 * the less the board gives, never reaching MAX_BOUNCE.
 */
export function bounce({
  camera,
  viewport,
  contentBounds,
}: {
  camera: Camera;
  viewport: Size;
  contentBounds: Rect;
}): Camera {
  const limits = panLimits({ scale: camera.scale, viewport, contentBounds });
  const bounced = (value: number, [min, max]: Interval) => {
    const over = value < min ? value - min : value > max ? value - max : 0;
    return (
      clamp(value, min, max) +
      (MAX_BOUNCE * over) / (Math.abs(over) + MAX_BOUNCE)
    );
  };
  return {
    x: bounced(camera.x, limits.x),
    y: bounced(camera.y, limits.y),
    scale: camera.scale,
  };
}

/**
 * The camera after bouncing back toward the pan limits for `elapsed`
 * milliseconds, keeping SPRING of the bounce every 16, and at the limits once
 * within half a pixel of them. A negative `elapsed` counts as none.
 */
export function bounceBack({
  camera,
  elapsed,
  viewport,
  contentBounds,
}: {
  camera: Camera;
  elapsed: number;
  viewport: Size;
  contentBounds: Rect;
}): Camera {
  const keep = SPRING ** (Math.max(0, elapsed) / 16);
  const limits = panLimits({ scale: camera.scale, viewport, contentBounds });
  const pulled = (value: number, [min, max]: Interval) => {
    const edge = clamp(value, min, max);
    return Math.abs(value - edge) < 0.5 ? edge : edge + (value - edge) * keep;
  };
  return {
    x: pulled(camera.x, limits.x),
    y: pulled(camera.y, limits.y),
    scale: camera.scale,
  };
}
