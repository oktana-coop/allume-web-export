import { type Canvas } from './canvas';
import { maxY, type Point, type Rect, type Size } from './geometry';

// A tooltip is as wide as its card, but at least MIN_WIDTH, and stays
// WINDOW_MARGIN inside the window.
const MIN_WIDTH = 240;
const WINDOW_MARGIN = 16;

const TITLES = '.allume-canvas > .allume-card > .allume-card-title > span';

/**
 * A card's title cut short shows whole in a tooltip while the pointer is on
 * it, where it can be selected and copied. The tooltip lives in the top layer,
 * so it reads the same at any zoom, spans its card, and touches the title, so
 * the pointer can move into it. It goes when the pointer leaves both, or the
 * board moves.
 */
export function setUpTitleTooltips({
  root,
  canvas,
}: {
  root: HTMLElement;
  canvas: Canvas;
}) {
  const tooltip = document.createElement('div');
  tooltip.className = 'allume-tooltip';
  tooltip.setAttribute('role', 'tooltip');
  tooltip.popover = 'manual';
  root.append(tooltip);

  const hide = () => {
    if (tooltip.matches(':popover-open')) tooltip.hidePopover();
  };

  canvas.element.addEventListener('pointerover', (event) => {
    const title = (event.target as Element).closest<HTMLElement>(TITLES);
    if (!title || title.scrollWidth <= title.clientWidth || canvas.gesture) {
      return;
    }

    const windowSize = { width: innerWidth, height: innerHeight };
    const card = title.closest('.allume-card')!.getBoundingClientRect();
    const { y, height } = title.getBoundingClientRect();

    tooltip.textContent = title.textContent;
    tooltip.style.width = `${tooltipWidth({ card, windowSize })}px`;
    if (!tooltip.matches(':popover-open')) tooltip.showPopover();
    const to = tooltipPosition({
      title: { x: card.x, y, width: card.width, height },
      tooltip: tooltip.getBoundingClientRect(),
      windowSize,
    });
    tooltip.style.left = `${to.x}px`;
    tooltip.style.top = `${to.y}px`;
  });

  canvas.element.addEventListener('pointerout', (event) => {
    if (event.relatedTarget !== tooltip) hide();
  });
  // Unless back onto a title, or dragging a selection out of it.
  tooltip.addEventListener('pointerleave', (event) => {
    const onTitle = (event.relatedTarget as Element | null)?.closest(TITLES);
    if (!onTitle && event.buttons === 0) hide();
  });
  canvas.viewport.addEventListener('wheel', hide, { passive: true });
  canvas.viewport.addEventListener('pointerdown', hide);
}

/** The card's width, but at least MIN_WIDTH, and within the window. */
export function tooltipWidth({
  card,
  windowSize,
}: {
  card: Size;
  windowSize: Size;
}): number {
  return Math.min(
    Math.max(card.width, MIN_WIDTH),
    windowSize.width - WINDOW_MARGIN * 2
  );
}

/**
 * Where a shown tooltip goes: right above the title, at its left, or right
 * below it when there's no room above, and within WINDOW_MARGIN of the
 * window's edges. The title spans its card.
 */
export function tooltipPosition({
  title,
  tooltip,
  windowSize,
}: {
  title: Rect;
  tooltip: Size;
  windowSize: Size;
}): Point {
  const x = Math.max(
    WINDOW_MARGIN,
    Math.min(title.x, windowSize.width - tooltip.width - WINDOW_MARGIN)
  );

  const above = title.y - tooltip.height;
  return { x, y: above >= WINDOW_MARGIN ? above : maxY(title) };
}
