// Pan and zoom for a board page, menus for linked cards, and focusing the card
// named in the URL hash (#card-<document id>). Loaded at the end of <body>,
// so the first camera is in place before the page is shown.

import { setUpCanvas } from './canvas';
import { makeCommentDatesRelative } from './comment-dates';
import { setUpCopyButtons } from './copy-buttons';
import { setUpGestures } from './gestures';
import { setUpLinkedCardMenus } from './linked-card-menus';
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

  makeCommentDatesRelative(document);
  setUpCopyButtons(canvas);
  setUpLinkedCardMenus(canvas);

  setUpNavigation();
  setUpStartingView(canvas);
})();
