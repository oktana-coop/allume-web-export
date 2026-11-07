// Pan and zoom for a board page, menus for linked cards, and focusing the card
// named in the URL hash (#card-<document id>). Loaded at the end of <body>,
// so the first camera is in place before the page is shown.

import { focusCard, setUpCanvas } from './canvas';
import { makeCommentDatesRelative } from './comment-dates';
import { setUpCopyButtons } from './copy-buttons';
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

  setUpCopyButtons(canvas);
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
