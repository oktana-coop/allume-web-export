import { focusCard, type Canvas } from './canvas';
import { maxY, type Point, type Rect, type Size } from './geometry';

// A menu opens GAP below its button, or above it without room below, and
// stays WINDOW_MARGIN inside the window.
const GAP = 6;
const WINDOW_MARGIN = 16;

/**
 * Linked card menus live in the top layer, so they're placed by their button,
 * and close when the board scrolls. Choosing the board the menu is on centers
 * the card, without leaving the page.
 */
export function setUpLinkedCardMenus({
  root,
  canvas,
}: {
  root: ParentNode;
  canvas: Canvas;
}) {
  canvas.viewport.addEventListener('wheel', () => closeOpenMenus(root), {
    passive: true,
  });

  for (const menu of root.querySelectorAll<HTMLElement>('.linked-menu')) {
    const button = root.querySelector(`[popovertarget="${menu.id}"]`);

    menu.addEventListener('beforetoggle', (event) => {
      if (event.newState !== 'open' || !button) return;

      const to = initialMenuPosition({
        button: button.getBoundingClientRect(),
      });
      moveMenu({ menu, to });
    });

    menu.addEventListener('toggle', (event) => {
      if (event.newState !== 'open' || !button) return;

      const to = menuPosition({
        button: button.getBoundingClientRect(),
        menu: menu.getBoundingClientRect(),
        windowSize: { width: innerWidth, height: innerHeight },
      });
      moveMenu({ menu, to });
    });

    menu.addEventListener('click', (event) => {
      const link = (event.target as Element).closest('a');
      if (!link || link.pathname !== location.pathname) return;

      // Not followed, so navigation records no arrival for a page not left.
      event.preventDefault();
      menu.hidePopover();
      history.replaceState(history.state, '', link.hash);
      focusCard({ canvas, id: link.hash.slice(1) });
    });
  }
}

/**
 * Where a menu goes before it's shown and can be measured: below the button,
 * and at least WINDOW_MARGIN from the window's left.
 */
export function initialMenuPosition({ button }: { button: Rect }): Point {
  return { x: Math.max(WINDOW_MARGIN, button.x), y: maxY(button) + GAP };
}

/**
 * Where a shown menu goes: below the button, or above it when there's no room
 * below, and within WINDOW_MARGIN of the window's edges.
 */
export function menuPosition({
  button,
  menu,
  windowSize,
}: {
  button: Rect;
  menu: Size;
  windowSize: Size;
}): Point {
  const x = Math.max(
    WINDOW_MARGIN,
    Math.min(button.x, windowSize.width - menu.width - WINDOW_MARGIN)
  );

  const below = maxY(button) + GAP;
  const fitsBelow = below + menu.height <= windowSize.height - WINDOW_MARGIN;
  const above = Math.max(WINDOW_MARGIN, button.y - menu.height - GAP);
  return { x, y: fitsBelow ? below : above };
}

function closeOpenMenus(root: ParentNode) {
  for (const menu of root.querySelectorAll<HTMLElement>(
    '.linked-menu:popover-open'
  )) {
    menu.hidePopover();
  }
}

function moveMenu({ menu, to }: { menu: HTMLElement; to: Point }) {
  menu.style.left = `${to.x}px`;
  menu.style.top = `${to.y}px`;
}
