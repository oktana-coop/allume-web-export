import { setUpBoardView } from './board-view';

for (const root of document.querySelectorAll<HTMLElement>('.allume')) {
  setUpBoardView(root);
}
