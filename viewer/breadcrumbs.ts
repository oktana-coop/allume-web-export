import { isRecord } from './guards';

/** A board in the breadcrumbs. */
export type Breadcrumb = { href: string; label: string };

/** The boards in the breadcrumbs, from the root to the parent. */
export type Breadcrumbs = Breadcrumb[];

export function parseBreadcrumbs(value: unknown): Breadcrumbs | null {
  if (!Array.isArray(value)) return null;

  const breadcrumbs = value.map(parseBreadcrumb);
  return breadcrumbs.every((breadcrumb) => breadcrumb !== null)
    ? breadcrumbs
    : null;
}

function parseBreadcrumb(value: unknown): Breadcrumb | null {
  if (!isRecord(value)) return null;

  const { href, label } = value;
  return typeof href === 'string' && typeof label === 'string'
    ? { href, label }
    : null;
}

export function breadcrumbLinks(breadcrumbsElement: Element | null) {
  return [
    ...(breadcrumbsElement?.querySelectorAll<HTMLAnchorElement>(':scope > a') ??
      []),
  ];
}

/** The link to the board the breadcrumbs go up to, or null at the root. */
export function parentLink(breadcrumbsElement: Element | null) {
  return (
    breadcrumbsElement?.querySelector<HTMLAnchorElement>(
      ':scope > a[rel="up"]'
    ) ?? null
  );
}

/** The boards the breadcrumbs show. */
export function readBreadcrumbs(
  breadcrumbsElement: Element | null
): Breadcrumbs {
  return breadcrumbLinks(breadcrumbsElement).map((link) => ({
    href: link.href,
    label: link.textContent,
  }));
}

/** The page's board, as a breadcrumb on the boards inside it. */
export function currentBoard(breadcrumbsElement: Element | null): Breadcrumb {
  return {
    href: location.href.split('#')[0],
    label:
      breadcrumbsElement?.querySelector(':scope > h1 > span')?.textContent ??
      '',
  };
}

/**
 * Shows the breadcrumbs instead of the ones there, and marks the last as the
 * parent in the heading's linked card menu.
 */
export function showBreadcrumbs({
  breadcrumbsElement,
  breadcrumbs,
}: {
  breadcrumbsElement: Element | null;
  breadcrumbs: Breadcrumbs;
}) {
  const heading = breadcrumbsElement?.querySelector(':scope > h1');
  if (!heading) return;

  const shown = breadcrumbsElement!.querySelectorAll(
    ':scope > a, :scope > .separator'
  );
  for (const element of shown) element.remove();

  breadcrumbs.forEach(({ href, label }, index) => {
    const link = document.createElement('a');
    link.href = href;
    link.textContent = label;
    if (index === breadcrumbs.length - 1) link.rel = 'up';

    const separator = document.createElement('span');
    separator.className = 'separator';
    separator.setAttribute('aria-hidden', 'true');
    separator.textContent = '/';
    heading.before(link, separator);
  });

  markParent({ heading, parent: breadcrumbs.at(-1) });
}

// The page marks the main path's parent in the heading's linked card menu, so
// a different path moves the mark to its own parent.
function markParent({
  heading,
  parent,
}: {
  heading: Element;
  parent: Breadcrumb | undefined;
}) {
  if (!parent) return;

  const path = new URL(parent.href).pathname;
  for (const link of heading.querySelectorAll<HTMLAnchorElement>(
    '.linked-menu a'
  )) {
    if (link.pathname === path) link.setAttribute('aria-current', 'true');
    else link.removeAttribute('aria-current');
  }
}
