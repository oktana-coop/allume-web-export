# Testing

The unit and integration tests use
[Swift Testing](https://developer.apple.com/documentation/testing), and the end-to-end tests use
[Playwright](https://playwright.dev/). None of them touches the network.

## Running Tests

Run every unit and integration test with:

```sh
swift test
```

To run one module's tests, or one suite, filter by its name:

```sh
swift test --filter AllumeWebRenderingTests
swift test --filter CardsTests
```

## Unit Tests

Each module has a test target named after it in `Tests/`, e.g. `Tests/AllumeWebRenderingTests/`.
They check the module on its own, with small inputs written in the tests.

## Integration Tests

`Tests/AllumeWebIntegrationTests/` reads the public sample export in `Fixtures/SampleExport/`,
renders and publishes it, and compares the pages with the expected files in
`Tests/AllumeWebIntegrationTests/Expected/SampleExport/`. These are the accepted output, so any
change in the pages fails the tests.

### Updating Expected Files

When a change in the output is intended, accept it with:

```sh
ACCEPT=1 swift test --filter AllumeWebIntegrationTests
```

That replaces the expected files with the current output. Review the change with `git diff`, and
commit the expected files together with the change that caused it.

## End-to-End Tests

The end-to-end tests in `e2e/` open the sample export's site in Chromium, and check what visitors
see and do there. Before each run, Playwright builds the viewer from `viewer/`, then the site into
`e2e-results/site/`, and serves it on <http://localhost:4400>, so the first run also waits for
`swift build`. If something is already serving on that port, the run fails rather than test it.

They need Node, at the version in `.nvmrc`. Install the tools and Playwright's Chromium once:

```sh
npm install
npx playwright install chromium
```

Then run them with:

```sh
npm run test:e2e
```

`npm run test:e2e:ui` opens Playwright's UI, which builds the site only when it opens, so restart
it after changing the viewer or the tool. `npm run test:e2e:debug` steps through a test in a
browser window, and `npm run test:e2e:report` shows the report of the last run. Results, including
screenshots, videos and traces of failed tests, are written to `e2e-results/`.

Format the tests with `npm run format`.
