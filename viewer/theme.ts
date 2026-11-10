// Board cards' previews are images, drawn in each theme, and CSS alone can't
// show the one in the page's theme in every browser: Safari's `light-dark()`
// can't pick between images yet, and `prefers-color-scheme` follows the system
// rather than the page, whose theme a site may switch.
// TODO: Remove once Safari's `light-dark()` picks between images, with board
// cards choosing their preview through it, and the theme probe with it.

/**
 * Marks the board's view with the page's theme, light or dark, for its board
 * cards to show the preview images drawn in it, and marks it again whenever the
 * theme changes. The site sets the theme through the page's color-scheme, which
 * the view's theme probe follows. When the theme changes, the probe's color
 * transitions, and the transition's end is the only sign of it scripts get.
 */
export function followTheme(root: HTMLElement) {
  const mark = () => {
    root.dataset.allumeTheme = theme(root);
  };

  mark();
  root.addEventListener('transitionend', (event) => {
    if (
      event.target === root &&
      event.propertyName === '--allume-theme-probe'
    ) {
      mark();
    }
  });
}

/** The probe is white in a light theme and black in a dark one. */
function theme(root: HTMLElement): 'light' | 'dark' {
  const probe = getComputedStyle(root)
    .getPropertyValue('--allume-theme-probe')
    .trim();
  return probe === 'rgb(0, 0, 0)' ? 'dark' : 'light';
}
