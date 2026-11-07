import { defineConfig } from 'vitest/config';

export default defineConfig({
  // Only the viewer's unit tests: the end-to-end tests are Playwright's.
  test: { include: ['viewer/**/*.test.ts'] },
});
