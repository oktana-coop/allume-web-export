import { defineConfig, devices } from '@playwright/test';

// Not the port the README serves `out/` on, so a site served by hand is never
// mistaken for the one the tests build
const PORT = 4400;

const SITE = 'e2e-results/site';

export default defineConfig({
  testDir: './e2e',
  outputDir: 'e2e-results/artifacts',
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  reporter: [
    ['list'],
    ['html', { outputFolder: 'e2e-results/html', open: 'never' }],
  ],
  use: {
    baseURL: `http://localhost:${PORT}`,
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    trace: 'retain-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        permissions: ['clipboard-read', 'clipboard-write'],
      },
    },
  ],
  // Builds the sample export's site, without favicons so that the tests stay
  // offline, then serves it. The first run waits for `swift build`.
  // `e2e/serve.json` keeps clean URLs to paths without an extension, so `/`
  // serves `index.html` but pages keep their `.html`, which the viewer's
  // camera memory is keyed by.
  webServer: {
    command:
      `swift run allume-web-export Fixtures/SampleExport --out ${SITE} --replace --no-favicons` +
      ` && serve ${SITE} --listen ${PORT} --config ../../e2e/serve.json --no-clipboard`,
    url: `http://localhost:${PORT}`,
    reuseExistingServer: !process.env.CI,
    timeout: 300_000,
  },
});
