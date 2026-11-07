export type Point = { x: number; y: number };

export type Size = { width: number; height: number };

export type Rect = { x: number; y: number; width: number; height: number };

export function maxX(rect: Rect) {
  return rect.x + rect.width;
}

export function maxY(rect: Rect) {
  return rect.y + rect.height;
}

export function clamp(value: number, min: number, max: number) {
  return Math.min(max, Math.max(min, value));
}
