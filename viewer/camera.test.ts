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
  parseCamera,
  pinch,
  withinLimits,
  zoomAt,
  type Camera,
} from './camera';
import { type Point } from './geometry';

// A board whose contents start 20 px from the canvas's origin, and fit the
// viewport twice over. At 100%, its pan limits are -360 to 860 across and
// -160 to 460 down.
const viewport = { width: 1000, height: 600 };
const contentBounds = { x: 20, y: 20, width: 460, height: 260 };

// A board four times as wide as the viewport, which fits at 25%.
const wideBounds = { x: 0, y: 0, width: 4000, height: 600 };

const atOrigin: Camera = { x: 0, y: 0, scale: 1 };

describe('fitScale', () => {
  it('is 100% for a board that fits', () => {
    expect(fitScale({ viewport, contentBounds })).toBe(1);
  });

  it('shrinks a board larger than the viewport', () => {
    expect(fitScale({ viewport, contentBounds: wideBounds })).toBe(0.25);
  });

  it('leaves the margin at the origin on the far side too', () => {
    const offset = { x: 100, y: 0, width: 800, height: 100 };

    expect(
      fitScale({ viewport: { width: 500, height: 600 }, contentBounds: offset })
    ).toBe(0.5);
  });

  it('leaves room above the origin for the titles of cards at the top', () => {
    // 32 px of room, then 1168 of contents: twice the viewport's height.
    const tall = { x: 0, y: 0, width: 100, height: 1168 };

    expect(fitScale({ viewport, contentBounds: tall })).toBe(0.5);
  });
});

describe('clampScale', () => {
  it('stops zooming out at 50%', () => {
    expect(clampScale({ scale: 0.2, viewport, contentBounds })).toBe(0.5);
  });

  it('stops zooming in at 400%', () => {
    expect(clampScale({ scale: 5, viewport, contentBounds })).toBe(4);
  });

  it('leaves a scale in between as it is', () => {
    expect(clampScale({ scale: 1.5, viewport, contentBounds })).toBe(1.5);
  });

  it('goes below 50% as far as a board needs to fit', () => {
    expect(
      clampScale({ scale: 0.1, viewport, contentBounds: wideBounds })
    ).toBe(0.25);
    expect(
      clampScale({ scale: 0.3, viewport, contentBounds: wideBounds })
    ).toBe(0.3);
  });
});

describe('fit', () => {
  it('shows the whole board from the canvas origin, with room above it for titles', () => {
    expect(fit({ viewport, contentBounds: wideBounds })).toEqual({
      x: 0,
      y: 32 * 0.25,
      scale: 0.25,
    });
  });
});

describe('focus', () => {
  it('centers the frame in the viewport', () => {
    const frame = { x: 100, y: 100, width: 200, height: 100 };

    const camera = focus({ frame, viewport, contentBounds });

    expect(canvasToViewport({ camera, point: { x: 200, y: 150 } })).toEqual({
      x: 500,
      y: 300,
    });
  });

  it('shrinks a large frame to leave 80 px around it', () => {
    const frame = { x: 0, y: 0, width: 1680, height: 440 };

    const camera = focus({ frame, viewport, contentBounds });

    expect(camera.scale).toBe(0.5);
    expect(canvasToViewport({ camera, point: { x: 0, y: 0 } }).x).toBe(80);
  });

  it("doesn't zoom in past 100%", () => {
    const frame = { x: 0, y: 0, width: 10, height: 10 };

    expect(focus({ frame, viewport, contentBounds }).scale).toBe(1);
  });
});

describe('zoomAt', () => {
  it('keeps the canvas point under the viewport point', () => {
    const camera = { x: 100, y: 50, scale: 1 };
    const point = { x: 400, y: 300 };

    const zoomed = zoomAt({ camera, point, scale: 2, viewport, contentBounds });

    expect(zoomed.scale).toBe(2);
    expect(viewportToCanvas({ camera: zoomed, point })).toEqual(
      viewportToCanvas({ camera, point })
    );
  });

  it('stays within the zoom limits', () => {
    const point = { x: 400, y: 300 };

    const zoomed = zoomAt({
      camera: atOrigin,
      point,
      scale: 10,
      viewport,
      contentBounds,
    });

    expect(zoomed.scale).toBe(4);
  });
});

describe('pinch', () => {
  it('moves the canvas point under one viewport point to under another', () => {
    const from = { x: 100, y: 100 };
    const to = { x: 150, y: 120 };

    const pinched = pinch({ camera: atOrigin, from, to, scale: 2 });

    expect(viewportToCanvas({ camera: pinched, point: to })).toEqual(
      viewportToCanvas({ camera: atOrigin, point: from })
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
    expect(panLimits({ scale: 1, viewport, contentBounds })).toEqual({
      x: [-360, 860],
      y: [-160, 460],
    });
  });

  it('keeps all of a narrower board in view', () => {
    const narrow = { x: 20, y: 20, width: 50, height: 260 };

    expect(panLimits({ scale: 1, viewport, contentBounds: narrow }).x).toEqual([
      -20, 930,
    ]);
  });

  it('measures the board at the scale', () => {
    const narrow = { x: 20, y: 20, width: 50, height: 260 };

    expect(
      panLimits({ scale: 0.5, viewport, contentBounds: narrow }).x
    ).toEqual([-10, 965]);
  });

  it('keeps no more than half a small viewport', () => {
    const small = { width: 200, height: 600 };

    expect(panLimits({ scale: 1, viewport: small, contentBounds }).x).toEqual([
      -380, 80,
    ]);
  });
});

describe('withinLimits', () => {
  it('leaves a camera within the pan limits as it is', () => {
    expect(withinLimits({ camera: atOrigin, viewport, contentBounds })).toEqual(
      atOrigin
    );
  });

  it('moves a camera past them to the nearest limit', () => {
    const camera = { x: 1000, y: -500, scale: 1 };

    expect(withinLimits({ camera, viewport, contentBounds })).toEqual({
      x: 860,
      y: -160,
      scale: 1,
    });
  });
});

describe('isBouncing', () => {
  it('is false within the pan limits', () => {
    expect(isBouncing({ camera: atOrigin, viewport, contentBounds })).toBe(
      false
    );
  });

  it('is true past them', () => {
    const camera = { x: 900, y: 0, scale: 1 };

    expect(isBouncing({ camera, viewport, contentBounds })).toBe(true);
  });
});

describe('bounce', () => {
  it('draws a camera within the pan limits where it is', () => {
    expect(bounce({ camera: atOrigin, viewport, contentBounds })).toEqual(
      atOrigin
    );
  });

  it.each([
    { pulled: 80, drawn: 40 },
    { pulled: 240, drawn: 60 },
  ])(
    'draws a board pulled $pulled px past an edge $drawn px past it',
    ({ pulled, drawn }) => {
      const camera = { x: 860 + pulled, y: 0, scale: 1 };

      expect(bounce({ camera, viewport, contentBounds }).x).toBe(860 + drawn);
    }
  );

  it('never draws the board 80 px past an edge', () => {
    const camera = { x: 860 + 1_000_000, y: 0, scale: 1 };

    expect(bounce({ camera, viewport, contentBounds }).x).toBeLessThan(
      860 + 80
    );
  });

  it('bounces the same way past the opposite edge', () => {
    const camera = { x: -360 - 80, y: 0, scale: 1 };

    expect(bounce({ camera, viewport, contentBounds }).x).toBe(-360 - 40);
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

      const back = bounceBack({ camera, elapsed, viewport, contentBounds });

      expect(back.x).toBeCloseTo(860 + left);
    }
  );

  it('reaches the limit once within half a pixel of it', () => {
    const camera = { x: 860.4, y: 0, scale: 1 };

    expect(bounceBack({ camera, elapsed: 16, viewport, contentBounds }).x).toBe(
      860
    );
  });

  it('leaves the bounce as it is for a negative elapsed time', () => {
    const camera = { x: 860 + 100, y: 0, scale: 1 };

    expect(
      bounceBack({ camera, elapsed: -16, viewport, contentBounds })
    ).toEqual(camera);
  });

  it('leaves a camera within the pan limits as it is', () => {
    expect(
      bounceBack({ camera: atOrigin, elapsed: 16, viewport, contentBounds })
    ).toEqual(atOrigin);
  });
});

describe('parseCamera', () => {
  it('reads a camera', () => {
    const camera = { x: 10, y: -20, scale: 0.5 };

    expect(parseCamera(camera)).toEqual(camera);
  });

  it('leaves out anything else', () => {
    const value = { x: 10, y: -20, scale: 0.5, zoom: 2 };

    expect(parseCamera(value)).toEqual({ x: 10, y: -20, scale: 0.5 });
  });

  it.each([
    { kind: 'null', value: null },
    { kind: 'a number', value: 1 },
    { kind: 'a camera without a scale', value: { x: 10, y: -20 } },
    {
      kind: 'a camera whose scale is text',
      value: { x: 10, y: -20, scale: '0.5' },
    },
    {
      kind: 'a camera at an infinite x',
      value: { x: Infinity, y: -20, scale: 0.5 },
    },
  ])('rejects $kind', ({ value }) => {
    expect(parseCamera(value)).toBeNull();
  });
});

/** The point in the viewport, on the canvas. */
const viewportToCanvas = ({
  camera,
  point,
}: {
  camera: Camera;
  point: Point;
}): Point => ({
  x: (point.x - camera.x) / camera.scale,
  y: (point.y - camera.y) / camera.scale,
});

/** The point on the canvas, in the viewport. */
const canvasToViewport = ({
  camera,
  point,
}: {
  camera: Camera;
  point: Point;
}): Point => ({
  x: camera.x + point.x * camera.scale,
  y: camera.y + point.y * camera.scale,
});
