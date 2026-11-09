# References

A board's view links to other boards and shows files: images, ink, avatars and favicons. Where
those live is up to the site. The tool's own site has a page for each board, side by side, and the
files under `files/`. A site built with a framework such as Astro has routes of its own, and may
serve files through its own pipeline.

So a board's view isn't drawn with URLs. It's drawn with references, and each output fills them
with the URLs of the site it's for. A view is otherwise the same, whatever site shows it.

## What a reference is

A reference names what a link leads to, or what an image shows, by what it is rather than by
where it is:

- a board, by its ID, and optionally a card on that board
- a file, by its path under `files/`

Every link between boards is a reference: board cards, breadcrumbs and linked card menus. So is
every file a view shows, as an image, ink, an avatar or a favicon. The files published are the
files the views refer to, so a site publishes exactly what its boards show.

## Filling references

Each output decides what the references become. The tool's own site, which the `site` command
writes, names each board's page after its slug, with the root's as `index.html`, and puts the
files under `files/`. Writing board views for other sites, which comes next, will either fill the
references from patterns the site gives, such as `/boards/{slug}/` for boards and `/allume/` for
files, or keep them, for the site to replace with its own URLs.

The link from Functional's card for Haskell to Haskell's board is, in each case:

```html
<!-- On the tool's own site -->
<a class="body panel" href="haskell-zkdb1w.html">…</a>

<!-- From the patterns /boards/{slug}/ and /allume/ -->
<a class="body panel" href="/boards/haskell-zkdb1w/">…</a>

<!-- With the reference kept -->
<a class="body panel" href="allume:board/0b92912e0774056fbb869596628560b7">…</a>
```

A reference that's kept is written as `allume:board/` and a board's ID, with `#card-` and a
card's ID for a card on it, or as `allume:file/` and a file's path. Kept references are only ever
`href` and `src` values, so a site can find them all and replace each one.

## Every reference leads somewhere

A view only refers to boards published with it, and to files under `files/`. So a site can
resolve every reference, and must: there's no broken link for it to tolerate. Likewise, the tool
fails rather than write a link to a board it doesn't know.

## Limitations

- A board can't be left out of what's published while other boards link to it, since its
  references would lead nowhere.
- The viewer assumes each board has a page of its own: it remembers where a board was left, and
  how it was reached, by the page's path.
