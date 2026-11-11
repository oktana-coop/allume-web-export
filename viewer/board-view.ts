import { setUpCanvas } from './canvas';
import { makeCommentDatesRelative } from './comment-dates';
import { setUpCopyButtons } from './copy-buttons';
import { setUpGestures } from './gestures';
import { setUpLinkedCardMenus } from './linked-card-menus';
import { setUpNavigation } from './navigation';
import { setUpScrolling } from './scrolling';
import { setUpStartingView } from './starting-view';
import { followTheme } from './theme';
import { setUpTitleTooltips } from './title-tooltips';
import { setUpZoomControls } from './zoom-controls';

/** Sets up the board's view whose element is the root. */
export function setUpBoardView(root: HTMLElement) {
  const canvas = setUpCanvas(root);
  if (!canvas) {
    throw new Error("The board's view has no viewport with a canvas in it.");
  }

  // Switches the view's styles from a natively scrolling board to the camera's.
  root.classList.add('allume-js');
  followTheme(root);

  setUpScrolling(canvas);
  setUpGestures(canvas);
  setUpZoomControls({ root, canvas });

  makeCommentDatesRelative(root);
  setUpCopyButtons(canvas);
  setUpLinkedCardMenus({ root, canvas });
  setUpTitleTooltips({ root, canvas });

  setUpNavigation(root);
  setUpStartingView(canvas);
}
