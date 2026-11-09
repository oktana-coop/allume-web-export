import { type Canvas } from './canvas';

// Copy buttons copy a note's or comment's full text, including any part the
// card's size cuts off, or all of a text block.

const COPIED_FOR = 1500;

export function setUpCopyButtons(canvas: Canvas) {
  canvas.element.addEventListener('click', async (event) => {
    const button = (event.target as Element).closest<HTMLElement>(
      '.allume-copy'
    );
    if (!button) return;

    const element = copyTargetElement(button);
    if (!element || !(await copyText(element))) return;

    showCopied(button);
  });
}

/** The element whose text the button copies. */
function copyTargetElement(button: Element) {
  const owner = button.parentElement;
  if (owner?.matches('.allume-text-block')) return owner;
  return (
    owner?.querySelector(':scope > .allume-body, :scope > .allume-text') ?? null
  );
}

async function copyText(element: Element) {
  try {
    await navigator.clipboard.writeText(textOf(element));
    return true;
  } catch {
    // The Clipboard API needs a secure context; copy a selection instead.
    const selection = getSelection();
    if (!selection) return false;

    const range = document.createRange();
    range.selectNodeContents(element);
    selection.removeAllRanges();
    selection.addRange(range);

    const copied = document.execCommand('copy');
    selection.removeAllRanges();
    return copied;
  }
}

// A text block has a paragraph per line, which textContent runs together.
function textOf(element: Element) {
  if (!element.matches('.allume-text-block')) return element.textContent;

  return [...element.querySelectorAll(':scope > p')]
    .map((paragraph) => paragraph.textContent)
    .join('\n');
}

/**
 * Shows on the button that it copied, for COPIED_FOR. Copying again starts
 * over: each copy marks the button with its own time, and only the timer of
 * the copy whose mark is still there resets the button.
 */
function showCopied(button: HTMLElement) {
  const mark = String(performance.now());
  button.dataset.allumeCopied = mark;
  button.setAttribute('aria-label', 'Copied');

  setTimeout(() => {
    if (button.dataset.allumeCopied !== mark) return;

    delete button.dataset.allumeCopied;
    button.setAttribute('aria-label', 'Copy text');
  }, COPIED_FOR);
}
