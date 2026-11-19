# Development

## Run

`swift run` builds the tool and runs it in one step. To try it on the public sample export in
`Fixtures/SampleExport/`, and view the result:

```sh
swift run allume-web-export site Fixtures/SampleExport --out out --replace
python3 -m http.server --directory out
```

Then open <http://localhost:8000>. Git ignores `out/`. `--replace` lets each run replace the last
one's site, and `--no-favicons` keeps the run offline.

## Viewer

The viewer is the script and stylesheet that let visitors pan, zoom and move between boards. Its
sources are in `viewer/`, but the tool doesn't build them: it copies a built `allume.js` and
`allume.css` from its resources, in `Sources/AllumeWeb/Viewer/`, into every site it writes.
esbuild builds those two files from `viewer/`, and they're committed, so building the tool needs
only Swift.

A change to the viewer therefore takes two steps: rebuilding it into the tool's resources, then
writing the site again with them:

```sh
npm run build:viewer
swift run allume-web-export site Fixtures/SampleExport --out out --replace
```

Then reload the page, served as in [Run](#run). The
[end-to-end tests](Testing.md#end-to-end-tests) rebuild the viewer before each run.

`npm run typecheck` checks the TypeScript: the viewer against the browser's APIs, and the build
script and the end-to-end tests against Node's. esbuild removes the types without checking them,
so before committing a change to `viewer/`, run the type check, the
[unit tests](Testing.md#viewer) and the end-to-end tests, and commit the rebuilt
files with it. All of these need Node and `npm install`, as for the end-to-end tests.

The renderer in `Sources/AllumeWebRendering/`, the stylesheets and the script share the page's
classes and `data-*` attributes, so renaming one means renaming it in all three. The integration
tests' expected pages and the end-to-end tests catch one that's missed. Each class, ID and `data-*`
attribute starts with `allume-`, as in `data-allume-color`, so that a site's own styles and scripts
can't reach the board's view. The one exception is a card's `card-<id>`, which links point to.

## Formatting

The code is formatted with swift-format's defaults, which keep lines within 100 columns, and
`.editorconfig` sets two-space indentation everywhere. Format before committing:

```sh
swift format --in-place --recursive Package.swift Sources Tests
```

`swift format lint --recursive Sources Tests` lists what's left.

The viewer and the end-to-end tests are formatted with Prettier, which keeps lines within 80
columns: `npm run format`.

## Commits

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/), e.g.
`feat: draw the icons` or `fix: find files in folders whose names have spaces`.

## Testing

Run `swift test`. See [Testing](Testing.md) for the unit, integration and
end-to-end tests, how to run some of them, and how to update the expected output.

## Releasing

A workflow on GitHub tests, builds, signs, notarizes and publishes each release. See
[Releasing](Releasing.md) for instructions.
