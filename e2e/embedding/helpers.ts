import { type Page } from '@playwright/test';

import { type Board } from '../shared/boards';

/**
 * Embeds the board's view in a site's page, in a box below a search field,
 * under rules that sites commonly set, and returns the page's URL. The page is
 * served next to the board's own, so the view's links and files resolve as they
 * do there.
 */
export const embedBoard = async ({
  page,
  board,
}: {
  page: Page;
  board: Board;
}) => {
  const boardPage = await (await page.request.get(board.url)).text();
  await page.route(SITE_PAGE, (route) =>
    route.fulfill({
      contentType: 'text/html',
      body: sitePageHTML({ view: mainContent(boardPage) }),
    })
  );

  return SITE_PAGE;
};

const SITE_PAGE = '/site.html';

/** The box the site's page gives the board's view. */
export const siteBox = ({ page }: { page: Page }) => page.locator('.board-box');

/** The board's view, which its own page has as its main content. */
const mainContent = (html: string) => {
  const content = /<main>\n(.*)\n<\/main>/s.exec(html)?.[1];
  if (!content) throw new Error('The page has no main content.');
  return content;
};

const sitePageHTML = ({ view }: { view: string }) => `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>A site's page</title>
<link rel="stylesheet" href="viewer.css">
<style>
${siteStyles}
</style>
</head>
<body>
<input type="search" aria-label="Search the site">
<div class="board-box">
${view}
</div>
<script src="viewer.js"></script>
</body>
</html>
`;

// A reset in the manner of Tailwind's, element styles, and classes that
// frameworks such as Bootstrap define too.
const siteStyles = `
*, ::before, ::after { box-sizing: border-box; margin: 0; padding: 0; border: 0 solid; }
body { font: 18px/1.6 Georgia, serif; color: #222; }
h1 { font-size: 2.5rem; font-weight: 800; }
p { margin-bottom: 1rem; }
a { color: rebeccapurple; text-decoration: underline; }
img, svg { display: block; vertical-align: middle; }
img { max-width: 100%; height: auto; }
button { background: transparent; font: inherit; color: inherit; }
.card { border: 1px solid #ddd; border-radius: 0.5rem; padding: 1rem; }
.title { font-size: 2rem; }
.board-box { width: 800px; height: 500px; margin: 2rem; }
`;
