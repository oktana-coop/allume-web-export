import { clampScale, parseCamera } from './camera';
import {
  fitBoard,
  focusCard,
  measure,
  moveCamera,
  type Canvas,
} from './canvas';
import { readSession, writeSession } from './session';

/**
 * A link to a card centers it. Otherwise a board opens where it was last left
 * in this session, like in Allume, or framed whole on a first visit.
 */
export function setUpStartingView(canvas: Canvas) {
  const key = `camera:${location.pathname}`;

  addEventListener('hashchange', () =>
    focusCard({ canvas, id: location.hash.slice(1) })
  );
  addEventListener('pagehide', () =>
    writeSession({ key, value: canvas.camera })
  );

  if (focusCard({ canvas, id: location.hash.slice(1) })) return;

  const saved = readSession({ key, parse: parseCamera });
  if (!saved) {
    fitBoard(canvas);
    return;
  }

  const scale = clampScale({ scale: saved.scale, ...measure(canvas) });
  moveCamera({ canvas, camera: { ...saved, scale } });
}
