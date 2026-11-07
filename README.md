# Allume Web Export

`allume-web-export` turns an [Allume](https://allume.com) board export into a static website: a page
for every board, which visitors can pan, zoom and move between as they would in Allume.

## Usage

### Prerequisites

- macOS 14 or later.
- Swift 6, which comes with Xcode 16 or later.

### Build

There are no releases yet, so build the tool from this repository:

```sh
swift build -c release
```

The command is then `.build/release/allume-web-export`.

### Run

Point it at an export folder, the one with `contents.json`, `metadata.json` and `files/` in it:

```sh
allume-web-export path/to/export --out site
```

The site's folder then holds:

- `index.html`, the exported board's page;
- a page for every board inside it, named after its label with a short code, such as
  `functional-q5tbqj.html`;
- `files/`, with the images, handwriting, avatars and favicons the pages show;
- `viewer.css` and `viewer.js`, the viewer.

PDFs are never published: their cards show only their title.

`--out` defaults to `out`. The folder must be missing or empty, so that a mistyped path can't wipe a
folder. To publish again over an earlier site, pass `--replace`, which replaces the folder's
contents. If anything fails while writing, the earlier site is left as it was.

Link cards show their site's icon, fetched the first time a site is linked to and kept in
`~/Library/Caches/allume-web-export/favicons/`; delete that folder to fetch them again.
`--no-favicons` leaves link cards with a generic link icon instead, e.g. to build offline.

### View the Site

Serve the folder with any static file server, e.g.:

```sh
python3 -m http.server --directory site
```

and open <http://localhost:8000>.

## Development

### Run

`swift run` builds the tool and runs it in one step. To try it on the public sample export in
`Fixtures/SampleExport/`, and view the result:

```sh
swift run allume-web-export Fixtures/SampleExport --out out --replace
python3 -m http.server --directory out
```

Then open <http://localhost:8000>. Git ignores `out/`. `--replace` lets each run replace the last
one's site, and `--no-favicons` keeps the run offline.

### Viewer

The viewer is the script and stylesheet that let visitors pan, zoom and move between boards. Its
sources are in `viewer/`, but the tool doesn't build them: it copies a built `viewer.js` and
`viewer.css` from its resources, in `Sources/AllumeWeb/Viewer/`, into every site it writes.
esbuild builds those two files from `viewer/`, and they're committed, so building the tool needs
only Swift.

A change to the viewer therefore takes two steps: rebuilding it into the tool's resources, then
writing the site again with them:

```sh
npm run build:viewer
swift run allume-web-export Fixtures/SampleExport --out out --replace
```

Then reload the page, served as in [Run](#run). The
[end-to-end tests](docs/Testing.md#end-to-end-tests) rebuild the viewer before each run.

`npm run typecheck` checks the TypeScript: the viewer against the browser's APIs, and the build
script and the end-to-end tests against Node's. esbuild removes the types without checking them,
so before committing a change to `viewer/`, run the type check, the
[unit tests](docs/Testing.md#viewer) and the end-to-end tests, and commit the rebuilt
files with it. All of these need Node and `npm install`, as for the end-to-end tests.

### Formatting

The code is formatted with swift-format's defaults, which keep lines within 100 columns, and
`.editorconfig` sets two-space indentation everywhere. Format before committing:

```sh
swift format --in-place --recursive Package.swift Sources Tests
```

`swift format lint --recursive Sources Tests` lists what's left.

The viewer and the end-to-end tests are formatted with Prettier, which keeps lines within 80
columns: `npm run format`.

### Commits

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/), e.g.
`feat: draw the icons` or `fix: find files in folders whose names have spaces`.

### Testing

Run `swift test`. See [docs/Testing.md](docs/Testing.md) for the unit, integration and
end-to-end tests, how to run some of them, and how to update the expected output.

## License

[AGPL-3.0](LICENSE).
