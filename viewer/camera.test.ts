import { describe, expect, it } from 'vitest';

import {
  bounce,
  bounceBack,
  clampScale,
  fit,
  fitScale,
  focus,
  isBouncing,
  panLimits,
  pinch,
  withinLimits,
  zoomAt,
  type Camera,
  type Scene,
} from './camera';
import { type Point } from './geometry';

// A board whose contents start 20 px from the canvas's origin, and fit the
// viewport twice over. At 100%, its pan limits are -360 to 860 across and
// -160 to 460 down.
const scene: Scene = {
  viewport: { width: 1000, height: 600 },
  contentBounds: { x: 20, y: 20, width: 460, height: 260 },
};

// A board four times as wide as the viewport, which fits at 25%.
const wideBoard: Scene = {
  ...scene,
  contentBounds: { x: 0, y: 0, width: 4000, height: 600 },
};

const atOrigin: Camera = { x: 0, y: 0, scale: 1 };

describe('fitScale', () => {
  it('is 100% for a board that fits', () => {
    expect(fitScale(scene)).toBe(1);
  });

  it('shrinks a board larger than the viewport', () => {
    expect(fitScale(wideBoard)).toBe(0.25);
  });

  it('leaves the margin at the origin on the far side too', () => {
    const offset: Scene = {
      viewport: { width: 500, height: 600 },
      contentBounds: { x: 100, y: 0, width: 800, height: 100 },
    };

    expect(fitScale(offset)).toBe(0.5);
  });
});

describe('clampScale', () => {
  it('stops zooming out at 50%', () => {
    expect(clampScale({ scale: 0.2, ...scene })).toBe(0.5);
  });

  it('stops zooming in at 400%', () => {
    expect(clampScale({ scale: 5, ...scene })).toBe(4);
  });

  it('leaves a scale in between as it is', () => {
    expect(clampScale({ scale: 1.5, ...scene })).toBe(1.5);
  });

  it('goes below 50% as far as a board needs to fit', () => {
    expect(clampScale({ scale: 0.1, ...wideBoard })).toBe(0.25);
    expect(clampScale({ scale: 0.3, ...wideBoard })).toBe(0.3);
  });
});

describe('fit', () => {
  it('shows the whole board from the canvas origin', () => {
    expect(fit(wideBoard)).toEqual({ x: 0, y: 0, scale: 0.25 });
  });
});

describe('focus', () => {
  it('centers the frame in the viewport', () => {
    const frame = { x: 100, y: 100, width: 200, height: 100 };

    const camera = focus({ frame, ...scene });

    expect(viewportPoint({ camera, of: { x: 200, y: 150 } })).toEqual({
      x: 500,
      y: 300,
    });
  });

  it('shrinks a large frame to leave 80 px around it', () => {
    const frame = { x: 0, y: 0, width: 1680, height: 440 };

    const camera = focus({ frame, ...scene });

    expect(camera.scale).toBe(0.5);
    expect(viewportPoint({ camera, of: { x: 0, y: 0 } }).x).toBe(80);
  });

  it("doesn't zoom in past 100%", () => {
    const frame = { x: 0, y: 0, width: 10, height: 10 };

    expect(focus({ frame, ...scene }).scale).toBe(1);
  });
});

describe('zoomAt', () => {
  it('keeps the canvas point under the viewport point', () => {
    const camera = { x: 100, y: 50, scale: 1 };
    const point = { x: 400, y: 300 };

    const zoomed = zoomAt({ camera, point, scale: 2, ...scene });

    expect(zoomed.scale).toBe(2);
    expect(canvasPoint({ camera: zoomed, under: point })).toEqual(
      canvasPoint({ camera, under: point })
    );
  });

  it('stays within the zoom limits', () => {
    const point = { x: 400, y: 300 };

    const zoomed = zoomAt({ camera: atOrigin, point, scale: 10, ...scene });

    expect(zoomed.scale).toBe(4);
  });
});

describe('pinch', () => {
  it('moves the canvas point under one viewport point to under another', () => {
    const from = { x: 100, y: 100 };
    const to = { x: 150, y: 120 };

    const pinched = pinch({ camera: atOrigin, from, to, scale: 2 });

    expect(canvasPoint({ camera: pinched, under: to })).toEqual(
      canvasPoint({ camera: atOrigin, under: from })
    );
  });

  it('pans at the same scale', () => {
    const from = { x: 100, y: 100 };
    const to = { x: 150, y: 120 };

    expect(pinch({ camera: atOrigin, from, to, scale: 1 })).toEqual({
      x: 50,
      y: 20,
      scale: 1,
    });
  });
});

describe('panLimits', () => {
  it('keeps 120 px of the board in view at each edge', () => {
    expect(panLimits({ scale: 1, ...scene })).toEqual({
      x: [-360, 860],
      y: [-160, 460],
    });
  });

  it('keeps all of a narrower board in view', () => {
    const narrow: Scene = {
      ...scene,
      contentBounds: { x: 20, y: 20, width: 50, height: 260 },
    };

    expect(panLimits({ scale: 1, ...narrow }).x).toEqual([-20, 930]);
  });

  it('measures the board at the scale', () => {
    const narrow: Scene = {
      ...scene,
      contentBounds: { x: 20, y: 20, width: 50, height: 260 },
    };

    expect(panLimits({ scale: 0.5, ...narrow }).x).toEqual([-10, 965]);
  });

  it('keeps no more than half a small viewport', () => {
    const small: Scene = { ...scene, viewport: { width: 200, height: 600 } };

    expect(panLimits({ scale: 1, ...small }).x).toEqual([-380, 80]);
  });
});

describe('withinLimits', () => {
  it('leaves a camera within the pan limits as it is', () => {
    expect(withinLimits({ camera: atOrigin, ...scene })).toEqual(atOrigin);
  });

  it('moves a camera past them to the nearest limit', () => {
    const camera = { x: 1000, y: -500, scale: 1 };

    expect(withinLimits({ camera, ...scene })).toEqual({
      x: 860,
      y: -160,
      scale: 1,
    });
  });
});

describe('isBouncing', () => {
  it('is false within the pan limits', () => {
    expect(isBouncing({ camera: atOrigin, ...scene })).toBe(false);
  });

  it('is true past them', () => {
    const camera = { x: 900, y: 0, scale: 1 };

    expect(isBouncing({ camera, ...scene })).toBe(true);
  });
});

describe('bounce', () => {
  it('draws a camera within the pan limits where it is', () => {
    expect(bounce({ camera: atOrigin, ...scene })).toEqual(atOrigin);
  });

  it.each([
    { pulled: 80, drawn: 40 },
    { pulled: 240, drawn: 60 },
  ])(
    'draws a board pulled $pulled px past an edge $drawn px past it',
    ({ pulled, drawn }) => {
      const camera = { x: 860 + pulled, y: 0, scale: 1 };

      expect(bounce({ camera, ...scene }).x).toBe(860 + drawn);
    }
  );

  it('never draws the board 80 px past an edge', () => {
    const camera = { x: 860 + 1_000_000, y: 0, scale: 1 };

    expect(bounce({ camera, ...scene }).x).toBeLessThan(860 + 80);
  });

  it('bounces the same way past the opposite edge', () => {
    const camera = { x: -360 - 80, y: 0, scale: 1 };

    expect(bounce({ camera, ...scene }).x).toBe(-360 - 40);
  });
});

describe('bounceBack', () => {
  it.each([
    { elapsed: 16, left: 80 },
    { elapsed: 32, left: 64 },
  ])(
    'leaves $left px of a 100 px bounce after $elapsed ms',
    ({ elapsed, left }) => {
      const camera = { x: 860 + 100, y: 0, scale: 1 };

      const back = bounceBack({ camera, elapsed, ...scene });

      expect(back.x).toBeCloseTo(860 + left);
    }
  );

  it('reaches the limit once within half a pixel of it', () => {
    const camera = { x: 860.4, y: 0, scale: 1 };

    expect(bounceBack({ camera, elapsed: 16, ...scene }).x).toBe(860);
  });

  it('leaves the bounce as it is for a negative elapsed time', () => {
    const camera = { x: 860 + 100, y: 0, scale: 1 };

    expect(bounceBack({ camera, elapsed: -16, ...scene })).toEqual(camera);
  });

  it('leaves a camera within the pan limits as it is', () => {
    expect(bounceBack({ camera: atOrigin, elapsed: 16, ...scene })).toEqual(
      atOrigin
    );
  });
});

/** The canvas point under the viewport point. */
const canvasPoint = ({
  camera,
  under,
}: {
  camera: Camera;
  under: Point;
}): Point => ({
  x: (under.x - camera.x) / camera.scale,
  y: (under.y - camera.y) / camera.scale,
});

/** The viewport point over the canvas point. */
const viewportPoint = ({
  camera,
  of,
}: {
  camera: Camera;
  of: Point;
}): Point => ({
  x: camera.x + of.x * camera.scale,
  y: camera.y + of.y * camera.scale,
});
