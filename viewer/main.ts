import { setUpBoardView } from './board-view';

for (const root of document.querySelectorAll<HTMLElement>(
  '.allume[data-allume-board]'
)) {
  setUpBoardView(root);
}
