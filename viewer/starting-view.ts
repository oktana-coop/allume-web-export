import { clampScale, parseCamera, topLeft } from './camera';
import { focusCard, measure, moveCamera, type Canvas } from './canvas';
import { readSession, writeSession } from './session';

/**
 * A link to a card centers it. Otherwise a board opens where it was last left
 * in this session, like in Allume, or on a first visit at 100% from its top
 * left, as Allume opens boards.
 */
export function setUpStartingView(canvas: Canvas) {
  const key = `allume:camera:${location.pathname}`;

  addEventListener('hashchange', () =>
    focusCard({ canvas, id: location.hash.slice(1) })
  );
  addEventListener('pagehide', () =>
    writeSession({ key, value: canvas.camera })
  );

  if (focusCard({ canvas, id: location.hash.slice(1) })) return;

  const saved = readSession({ key, parse: parseCamera });
  if (!saved) {
    moveCamera({ canvas, camera: topLeft() });
    return;
  }

  const scale = clampScale({ scale: saved.scale, ...measure(canvas) });
  moveCamera({ canvas, camera: { ...saved, scale } });
}
