import { expect, test } from '@playwright/test';

import { expectBoard } from '../navigation/helpers';
import { languages, paradigms } from '../shared/boards';
import { enterBoard } from '../shared/helpers';
import { embedBoard } from './helpers';

// A site's scripts share the page's session storage and its history entries'
// state with the viewer.
test.describe("a site's own state, beside the view's", () => {
  test("keeps the site's own session storage", async ({ page }) => {
    const sitePage = await embedBoard({ page, board: languages });
    await page.goto(sitePage);
    await page.evaluate(() => {
      sessionStorage.setItem('arrival', "the site's");
      sessionStorage.setItem('camera:/site.html', "the site's");
    });

    // Records how Paradigms is reached, and where the board was left.
    await enterBoard({ page, board: paradigms });

    expect(
      await page.evaluate(() => [
        sessionStorage.getItem('arrival'),
        sessionStorage.getItem('camera:/site.html'),
      ])
    ).toEqual(["the site's", "the site's"]);
  });

  test("keeps the site's own history state", async ({ page }) => {
    await page.addInitScript(() =>
      history.replaceState({ ...history.state, breadcrumbs: "the site's" }, '')
    );
    await page.goto(languages.url);

    // Records the breadcrumbs in Paradigms' history entry.
    await enterBoard({ page, board: paradigms });

    await expectBoard({ page, board: paradigms, ancestors: [languages] });
    expect(await page.evaluate(() => history.state.breadcrumbs)).toBe(
      "the site's"
    );
  });
});
