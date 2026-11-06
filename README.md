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

`swift run` builds the tool and runs it in one step. To try it on the public fixture export in
`Fixtures/Languages/`, and view the result:

```sh
swift run allume-web-export Fixtures/Languages --out out --replace
python3 -m http.server --directory out
```

Then open <http://localhost:8000>. Git ignores `out/`. `--replace` lets each run replace the last
one's site, and `--no-favicons` keeps the run offline.

### Formatting

The code is formatted with swift-format's defaults, which keep lines within 100 columns, and
`.editorconfig` sets two-space indentation everywhere. Format before committing:

```sh
swift format --in-place --recursive Package.swift Sources Tests
```

`swift format lint --recursive Sources Tests` lists what's left.

### Commits

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/), e.g.
`feat: draw the icons` or `fix: find files in folders whose names have spaces`.

### Testing

Run `swift test`. See [docs/Testing.md](docs/Testing.md) for the unit and integration tests, how to
run some of them, and how to update the expected output.

## License

[AGPL-3.0](LICENSE).
