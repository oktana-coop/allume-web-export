import { type Canvas } from './canvas';

const NOTES = '.allume-canvas > .allume-note-card > .allume-body';
const SCROLLING = 'allume-scrolling';

/**
 * A note shorter than its text scrolls once clicked, as in Allume's edit mode,
 * until a press elsewhere or Escape, which scroll it back to its top. Until
 * then, scrolling over it pans the board, so panning doesn't catch on notes.
 */
export function setUpNoteScrolling(canvas: Canvas) {
  /** Stops the note that scrolls, returning whether there was one. */
  const stopScrolling = () => {
    const note = canvas.element.querySelector(`.${SCROLLING}`);
    if (!note) return false;

    note.classList.remove(SCROLLING);
    note.scrollTo({
      top: 0,
      behavior: canvas.reducedMotion ? 'instant' : 'smooth',
    });
    return true;
  };

  canvas.viewport.addEventListener('click', (event) => {
    const note = (event.target as Element).closest(NOTES);
    if (note && note.scrollHeight > note.clientHeight) {
      note.classList.add(SCROLLING);
    }
  });

  // A press on the note's card, such as on its copy button, keeps it.
  canvas.viewport.addEventListener('pointerdown', (event) => {
    const card = (event.target as Element).closest('.allume-note-card');
    if (!card?.querySelector(`:scope > .${SCROLLING}`)) stopScrolling();
  });

  // Escape stops the note rather than leaving the board: navigation, set up
  // after this, leaves alone an Escape already taken.
  addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && stopScrolling()) event.preventDefault();
  });
}

/**
 * Whether the event is on a note that scrolls, which takes scrolling and
 * touches from the board.
 */
export function isOnScrollingNote(event: Event) {
  return (event.target as Element).closest(`.${SCROLLING}`) !== null;
}
