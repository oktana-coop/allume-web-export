// Pan and zoom for a board page, menus for linked cards, and focusing the card
// named in the URL hash (#card-<document id>). Loaded at the end of <body>,
// so the first camera is in place before the page is shown.

import { focusCard, setUpCanvas } from './canvas';
import { makeCommentDatesRelative } from './comment-dates';
import { setUpGestures } from './gestures';
import { setUpNavigation } from './navigation';
import { setUpScrolling } from './scrolling';
import { setUpStartingView } from './starting-view';
import { setUpZoomControls } from './zoom-controls';

(() => {
  // Asserted rather than narrowed by the check below, which TypeScript
  // doesn't carry into the function declarations.
  const canvas = setUpCanvas(document)!;
  if (!canvas) return;
  document.documentElement.classList.add('js');

  setUpScrolling(canvas);
  setUpGestures(canvas);
  setUpZoomControls(canvas);

  // Scrolling the board closes an open linked card menu.
  canvas.viewport.addEventListener('wheel', closeMenus, { passive: true });

  function closeMenus() {
    for (const menu of document.querySelectorAll<HTMLElement>(
      '.linked-menu:popover-open'
    )) {
      menu.hidePopover();
    }
  }

  makeCommentDatesRelative(document);

  // Copy buttons copy a text card's or comment's full text, including any
  // part the card's size cuts off, or all of a canvas text.
  const copiedTimers = new WeakMap<HTMLElement, number>();
  canvas.element.addEventListener('click', async (event) => {
    const button = (event.target as Element).closest<HTMLElement>('.copy');
    const owner = button?.parentElement;
    const source = owner?.matches('.chain')
      ? owner
      : owner?.querySelector(':scope > .body, :scope > .text');
    if (!source || !(await copyText(source))) return;

    button!.dataset.copied = '';
    button!.setAttribute('aria-label', 'Copied');

    clearTimeout(copiedTimers.get(button!));
    copiedTimers.set(
      button!,
      setTimeout(() => {
        delete button!.dataset.copied;
        button!.setAttribute('aria-label', 'Copy text');
      }, 1500)
    );
  });

  async function copyText(element: Element) {
    try {
      await navigator.clipboard.writeText(textOf(element));
      return true;
    } catch {
      // The Clipboard API needs a secure context; copy a selection instead.
      const selection = getSelection()!;
      const range = document.createRange();

      range.selectNodeContents(element);
      selection.removeAllRanges();
      selection.addRange(range);

      const copied = document.execCommand('copy');
      selection.removeAllRanges();
      return copied;
    }
  }

  // A canvas text has a paragraph per line, which textContent runs together.
  function textOf(element: Element) {
    if (!element.matches('.chain')) return element.textContent;
    return [...element.querySelectorAll(':scope > p')]
      .map((paragraph) => paragraph.textContent)
      .join('\n');
  }

  setUpNavigation();

  // Linked-card menus live in the top layer, so place them by their button.
  for (const menu of document.querySelectorAll<HTMLElement>('.linked-menu')) {
    const button = document.querySelector(`[popovertarget="${menu.id}"]`);

    menu.addEventListener('beforetoggle', (event) => {
      if (event.newState !== 'open' || !button) return;

      const anchor = button.getBoundingClientRect();
      menu.style.left = `${Math.max(16, anchor.left)}px`;
      menu.style.top = `${anchor.bottom + 6}px`;
    });

    menu.addEventListener('toggle', (event) => {
      if (event.newState !== 'open' || !button) return;

      const anchor = button.getBoundingClientRect();
      const { width, height } = menu.getBoundingClientRect();
      const left = Math.max(16, Math.min(anchor.left, innerWidth - width - 16));
      const below = anchor.bottom + 6;
      const top =
        below + height > innerHeight - 16
          ? Math.max(16, anchor.top - height - 6)
          : below;

      menu.style.left = `${left}px`;
      menu.style.top = `${top}px`;
    });

    menu.addEventListener('click', (event) => {
      const link = (event.target as Element).closest('a');
      if (!link || link.pathname !== location.pathname) return;

      event.preventDefault();
      menu.hidePopover();
      history.replaceState(history.state, '', link.hash);
      focusCard({ canvas, id: link.hash.slice(1) });
    });
  }

  setUpStartingView(canvas);
})();
