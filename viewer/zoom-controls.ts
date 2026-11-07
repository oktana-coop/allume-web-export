import { fitBoard, zoomAtCenter, type Canvas } from './canvas';

// Each step zooms in by a quarter, and back out by as much.
const ZOOM_IN = 1.25;
const ZOOM_OUT = 0.8;

/**
 * The toolbar's buttons and the keys zoom at the viewport's center: + and −
 * zoom, 0 shows the board at 100%, and Shift+1 or Fit shows all of it. With
 * Ctrl/⌘ the keys work the same, instead of zooming the whole page.
 */
export function setUpZoomControls(canvas: Canvas) {
  document.querySelector('.zoom')?.addEventListener('click', (event) => {
    const action = (event.target as Element).closest<HTMLElement>('[data-zoom]')
      ?.dataset.zoom;
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
    if (event.altKey) return;

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
