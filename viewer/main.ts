import { setUpCanvas } from './canvas';
import { makeCommentDatesRelative } from './comment-dates';
import { setUpCopyButtons } from './copy-buttons';
import { setUpGestures } from './gestures';
import { setUpLinkedCardMenus } from './linked-card-menus';
import { setUpNavigation } from './navigation';
import { setUpScrolling } from './scrolling';
import { setUpStartingView } from './starting-view';
import { setUpZoomControls } from './zoom-controls';

const canvas = setUpCanvas(document);
if (!canvas) {
  throw new Error('The page has no board: no .viewport with a .world in it.');
}
document.documentElement.classList.add('js');

setUpScrolling(canvas);
setUpGestures(canvas);
setUpZoomControls(canvas);

makeCommentDatesRelative(document);
setUpCopyButtons(canvas);
setUpLinkedCardMenus(canvas);

setUpNavigation();
setUpStartingView(canvas);
