/**
 * What has focus as a key is pressed: the view, or something inside it; the
 * page itself, while nothing has focus; or some other element on the page, such
 * as a site's field.
 */
export type FocusedArea = 'view' | 'page' | 'other';

export function focusedArea({
  root,
  event,
}: {
  root: Element;
  event: KeyboardEvent;
}): FocusedArea {
  const { target } = event;
  if (target instanceof Node && root.contains(target)) return 'view';
  if (target === document.body || target === document.documentElement) {
    return 'page';
  }
  return 'other';
}

/**
 * Whether the view is all of its page's main content, as on its own page,
 * rather than one part of a site's page among others.
 */
export function isMainContent(root: Element): boolean {
  const parent = root.parentElement;
  return parent?.localName === 'main' && parent.childElementCount === 1;
}
