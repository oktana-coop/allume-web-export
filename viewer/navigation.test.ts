import { describe, expect, it } from 'vitest';

import {
  arrivalFor,
  escapeTarget,
  parseArrivalRecord,
  parseHistoryState,
  withViewerState,
} from './navigation';

// The breadcrumbs on Functional, inside Paradigms, inside Languages.
const languages = { href: 'http://localhost/index.html', label: 'Languages' };
const paradigms = {
  href: 'http://localhost/paradigms-grn33t.html',
  label: 'Paradigms',
};
const functional = {
  href: 'http://localhost/functional-q5tbqj.html',
  label: 'Functional',
};
const breadcrumbs = [languages, paradigms];

describe('arrivalFor', () => {
  it('goes up a breadcrumb, keeping the ones before it', () => {
    const link = { kind: 'breadcrumb', index: 1 } as const;

    expect(arrivalFor({ link, breadcrumbs, current: functional })).toEqual({
      how: 'up',
      breadcrumbs: [languages],
    });
  });

  it("goes up from the heading's linked card menu, to the board's main path", () => {
    const link = { kind: 'heading menu' } as const;

    expect(arrivalFor({ link, breadcrumbs, current: functional })).toEqual({
      how: 'up',
    });
  });

  it('goes across from a linked card menu', () => {
    const link = { kind: 'linked card menu' } as const;

    expect(arrivalFor({ link, breadcrumbs, current: functional })).toEqual({
      how: 'across',
    });
  });

  it('goes down into a board card, adding the current board to the breadcrumbs', () => {
    const link = { kind: 'board card' } as const;

    expect(arrivalFor({ link, breadcrumbs, current: functional })).toEqual({
      how: 'down',
      breadcrumbs: [languages, paradigms, functional],
    });
  });
});

describe('escapeTarget', () => {
  it.each(['down', 'across'] as const)(
    'goes back after arriving %s',
    (arrival) => {
      expect(escapeTarget({ arrival, hasParent: true })).toBe('back');
    }
  );

  it.each([
    { kind: 'going up', arrival: 'up' as const },
    { kind: 'arriving from elsewhere', arrival: undefined },
  ])('goes up to the parent after $kind', ({ arrival }) => {
    expect(escapeTarget({ arrival, hasParent: true })).toBe('up');
  });

  it('does nothing at the root', () => {
    expect(escapeTarget({ arrival: undefined, hasParent: false })).toBeNull();
  });
});

describe('parseArrivalRecord', () => {
  it('reads an arrival with its breadcrumbs', () => {
    const record = {
      path: '/functional-q5tbqj.html',
      how: 'down',
      breadcrumbs,
    };

    expect(parseArrivalRecord(record)).toEqual(record);
  });

  it('reads an arrival for the main path, without breadcrumbs', () => {
    const record = { path: '/functional-q5tbqj.html', how: 'across' };

    expect(parseArrivalRecord(record)).toEqual(record);
  });

  it.each([
    { kind: 'null', value: null },
    { kind: 'an arrival without a path', value: { how: 'down' } },
    { kind: 'an unknown way', value: { path: '/a.html', how: 'sideways' } },
    {
      kind: 'breadcrumbs that are not a list',
      value: { path: '/a.html', how: 'down', breadcrumbs: 'Languages' },
    },
    {
      kind: 'a breadcrumb without a label',
      value: { path: '/a.html', how: 'down', breadcrumbs: [{ href: '/' }] },
    },
  ])('rejects $kind', ({ value }) => {
    expect(parseArrivalRecord(value)).toBeNull();
  });
});

describe('parseHistoryState', () => {
  it('reads the arrival and the breadcrumbs', () => {
    const state = { allume: { arrival: 'down', breadcrumbs } };

    expect(parseHistoryState(state)).toEqual({ arrival: 'down', breadcrumbs });
  });

  it("leaves out what isn't valid", () => {
    const state = { allume: { arrival: 'sideways', breadcrumbs: 'Languages' } };

    expect(parseHistoryState(state)).toEqual({});
  });

  it("reads nothing from the site's own state", () => {
    expect(parseHistoryState({ arrival: 'down', breadcrumbs })).toEqual({});
  });

  it('reads nothing from a page without a history entry of its own', () => {
    expect(parseHistoryState(null)).toEqual({});
  });
});

describe('withViewerState', () => {
  it("keeps the site's own state beside the viewer's", () => {
    const state = { arrival: "the site's", allume: { arrival: 'up' } };

    const updated = withViewerState({ state, ours: { arrival: 'down' } });

    expect(updated).toEqual({
      arrival: "the site's",
      allume: { arrival: 'down' },
    });
  });

  it('starts from nothing without a state to keep', () => {
    expect(withViewerState({ state: null, ours: { arrival: 'down' } })).toEqual(
      { allume: { arrival: 'down' } }
    );
  });
});
