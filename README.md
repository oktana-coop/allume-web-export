# Allume Web Export

`allume-web-export` turns an [Allume](https://allume.com/) board export into a static website: a
page for every board, which visitors can pan, zoom and move between as they would in Allume.

Allume (formerly Muse) is a spatial canvas for thinking and organizing ideas. This tool lets you
publish those boards on the open web, either as a standalone website or embedded in an existing
site.

**See it in action:** [Fragments & Flows](https://fragmentsandflows.com/garden/boards/home-l0tzup/),
a digital garden that uses the exporter.

For the motivation behind the project, read [Opening the Pensieve: Web Exporting for
Allume](https://oktana.dev/blog/opening-the-pensieve-web-exporting-for-allume/).

## Demos

- Deployed as a standalone website in [Programming](https://allume-export-website.netlify.app).
- Embedded within the [Fragments & Flows](https://fragmentsandflows.com/garden/boards/home-l0tzup/)
  digital garden.

## Install

The tool runs on macOS 14 or later.

### With Homebrew

```sh
brew install oktana-coop/tap/allume-web-export
```

### From a Release

Each [release](https://github.com/oktana-coop/allume-web-export/releases) has the tool as a zip: the
command and its resource bundle, which the command needs beside it.

### From Source

With Xcode 26 or later, build the tool from this repository:

```sh
swift build -c release
```

The command is then `.build/release/allume-web-export`.

## Usage

### Run

1. In Allume, export the board to publish with **Export Board As › Allume Bundle…**. The boards
   inside it are exported with it, into a zip archive named after the board, such as
   `Programming.muse`.
2. Run the tool on the bundle, with one of its two commands, which publish the boards in two ways:
   `site` as a website of their own, and `embed` for an existing site to show in its own pages.
   Either way, PDFs are never published: their cards show only their title. A folder decompressed
   from the bundle, with `contents.json`, `metadata.json` and `files/` in it, works too.

#### Site

```sh
allume-web-export site path/to/bundle.muse --out site
```

The site's folder then holds:

- `index.html`, the exported board's page;
- a page for every board inside it, named after its label with a short code, such as
  `functional-q5tbqj.html`;
- `files/`, with the images, handwriting, avatars and favicons the pages show. Images in a format
  browsers can't show, such as HEIC, are published as JPEG instead, or as PNG when they have
  transparent pixels. In `previews/`, it has the previews board cards show: each board as a first
  visit opens it, from its top left at 100% in a window 1440 px wide, its own board cards showing
  their previews, scaled down to the card. They're images in the light and dark palettes, such as
  `<board-id>-light.jpg`, and for a colored card on its color, such as
  `<board-id>-purple-light.jpg`. WebKit draws them, and when it can't, the board's cards show an
  empty panel, with a warning;
- `allume.css` and `allume.js`, the viewer.

#### Embed

```sh
allume-web-export embed path/to/bundle.muse --out allume
```

Its folder holds:

- `boards.json`, which lists the boards, each with its label, a suggested slug, the boards it's on
  and its view's path, and gives the preview images' paths;
- `boards/`, each board's view, an element for a page to include, whose links and images are
  `allume:` references for the site to replace with its own URLs, as
  [References](docs/References.md) explains;
- `preview-light.jpg` and `preview-dark.jpg`, pictures of the whole exported board, 1600 px wide,
  in the light and dark palettes. WebKit draws them, and when
  it can't, they're left out with a warning;
- `files/`, as for a site;
- `allume.css` and `allume.js`, the viewer, for the site's pages to include.

To have the views link to the site's URLs instead, give `embed` the site's patterns: each board's
URL, with `{slug}` standing for its slug, and where the site serves the folder's `files/`:

```sh
allume-web-export embed path/to/bundle.muse --out allume --board-url '/boards/{slug}/' \
  --files-url /allume/files
```

Either can be given alone, leaving the other kind of reference in.

#### Options

| Option                     | Commands | What it does                                                                         |
| :------------------------- | :------- | :----------------------------------------------------------------------------------- |
| `--out <folder>`           | both     | Where to write, `out` by default. The folder must be missing or empty.               |
| `--replace`                | both     | Replaces the folder's contents, to publish again over an earlier run.                |
| `--no-favicons`            | both     | Gives link cards a generic link icon instead of their site's, e.g. to build offline. |
| `--root-label <label>`     | both     | Labels the exported board otherwise, e.g. `Home`.                                    |
| `--preview-width <pixels>` | both     | How wide board cards' previews are drawn, 1024 px by default.                        |
| `--theme <theme>`          | `site`   | `light`, the default, `dark`, or `system`, which follows each reader's system.       |
| `--board-url <pattern>`    | `embed`  | Each board's URL on the site, with `{slug}` standing for its slug.                   |
| `--files-url <url>`        | `embed`  | Where the site serves the folder's `files/`.                                         |

- `--out` refuses a folder with anything in it unless `--replace` is given, so that a mistyped path
  can't wipe a folder. If anything fails while writing, the earlier run's files are left as they
  were.
- Link cards' icons are fetched the first time a site is linked to and kept in
  `~/Library/Caches/allume-web-export/favicons/`; delete that folder to fetch them again.
- `--root-label` changes the label wherever it shows: the board's breadcrumb, heading and page
  title, and its slug.
- Wider previews stay sharp when zoomed in further, but take more room: the images grow with the
  square of their width.
- Without `--board-url` or `--files-url`, that kind of link stays an `allume:` reference, for the
  site to resolve.

### View the Site

Serve the folder with any static file server, e.g.:

```sh
python3 -m http.server --directory site
```

and open <http://localhost:8000>.

### Limitations

- Ink drawn on a text block or a comment thread isn't shown yet, and the tool warns about it. It's
  drawn over the text, positioned for how Allume wraps it, and the browser may wrap the text
  differently. So the ink's position has to be worked out against the browser's own layout,
  rather than copied.
- WebKit draws the previews again on every run, and doesn't always draw them identically. So
  publishing the same export again can give a few previews pixels a shade apart: invisibly
  different, but different files.

## Development

See [docs/Development.md](docs/Development.md) for working on the tool: running it from source,
the viewer, formatting, commits, testing and releasing.

## Support

If you like our work, please consider [supporting us financially](https://oktana.dev/#support), so
that we can do more of this. We statutorily do not accept venture capital investment so that we stay
independent and our resources are currently limited and based on personal savings from previous work
we’ve undertaken. It would be amazing for us to reach a point where our work is community-funded.

## License

[AGPL-3.0-or-later](LICENSE).
