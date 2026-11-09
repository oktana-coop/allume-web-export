import { fitBoard, zoomAtCenter, type Canvas } from './canvas';
import { focusedArea, isMainContent } from './focus';

// Each step zooms in by a quarter, and back out by as much.
const ZOOM_IN = 1.25;
const ZOOM_OUT = 0.8;

/**
 * The toolbar's buttons and the keys zoom at the viewport's center: + and −
 * zoom, 0 shows the board at 100%, and Shift+1 or Fit shows all of it. With
 * Ctrl/⌘ the keys work the same, instead of zooming the whole page. They work
 * while the view has focus, and while nothing has on a page whose main content
 * the view is; otherwise they're left to the page.
 */
export function setUpZoomControls({
  root,
  canvas,
}: {
  root: HTMLElement;
  canvas: Canvas;
}) {
  root.querySelector('.allume-zoom')?.addEventListener('click', (event) => {
    const action = (event.target as Element).closest<HTMLElement>(
      '[data-allume-zoom]'
    )?.dataset.allumeZoom;
    const { scale } = canvas.camera;

    if (action === 'in') {
      zoomAtCenter({ canvas, scale: scale * ZOOM_IN });
    } else if (action === 'out') {
      zoomAtCenter({ canvas, scale: scale * ZOOM_OUT });
    } else if (action === 'home') {
      fitBoard(canvas);
    }
  });

  addEventListener('keydown', (event) => {
    if (event.altKey || !isForTheView({ root, event })) return;

    const { scale } = canvas.camera;

    if (event.key === '+' || event.key === '=') {
      zoomAtCenter({ canvas, scale: scale * ZOOM_IN });
    } else if (event.key === '-') {
      zoomAtCenter({ canvas, scale: scale * ZOOM_OUT });
    } else if (event.key === '0') {
      zoomAtCenter({ canvas, scale: 1 });
    } else if (event.shiftKey && event.code === 'Digit1') {
      fitBoard(canvas);
    } else {
      return;
    }

    event.preventDefault();
  });
}

function isForTheView({
  root,
  event,
}: {
  root: Element;
  event: KeyboardEvent;
}) {
  switch (focusedArea({ root, event })) {
    case 'view':
      return true;
    case 'page':
      return isMainContent(root);
    case 'other':
      return false;
  }
}
