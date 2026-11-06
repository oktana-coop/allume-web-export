# Favicons

Allume shows each link card with its site's icon. Exports don't include the icons, and browsers
can't show another site's icon by themselves, so this module fetches them when a site is built, once
for each linked site, and publishing puts them in the site's folder. The published pages then load
nothing from the sites they link to. Allume already has these icons, so once its exports include
them, this module can go.

Everything this module fetches comes from other people's websites, and is trusted no more than that.
The links themselves come from the author's export, but where they lead, and what comes back, is up
to the sites. Whatever it keeps ends up served from the author's own site. The rules below follow
from that.

## What's fetched

For each linked site: its home page, to find the icons the page declares, then the best of those,
and `/favicon.ico` last. Icons of 32 pixels or more come first, and Apple's touch icons last. Only
the page's head is read, and the page is only scanned for those declarations, never run or rendered.

For a link to `https://ocaml.org/docs`, it fetches `https://ocaml.org/`. If that page's head
declares `<link rel="icon" sizes="128x128" href="/icon.png">`, it then fetches
`https://ocaml.org/icon.png`.

## Only pixels are published

An icon file can carry more than an image:

- an SVG can hold scripts;
- a file can be an image and a web page at once;
- images carry metadata, such as where a photo was taken.

Published as it came, a script in an icon would run on the author's site whenever someone opened
the file, with access to whatever that site keeps in the browser. So a downloaded file is never
published. Its pixels are read and drawn into a new image, saved as a PNG of our own, so nothing
else from the file reaches the site, and every icon is a PNG named after its site, such as
`ocaml.org.png`.

The new image is at most 128 pixels wide, enough for a 16-pixel icon at 4 times zoom on a
high-density screen, and smaller icons keep their size. Only PNG, ICO, JPEG and GIF files are read.
SVG isn't, since cleaning it safely is notoriously hard, and sites that declare an SVG icon nearly
always have another one too.

## Only public sites, over HTTPS

A link, or a site redirecting there, could point into the author's own network: a router, a
printer, a development server. Fetching from those would read what should never leave that network,
and could even publish it as an icon. So:

- only HTTPS is used, with the usual certificate checks, which a server inside a network can't pass
  for a public site's name;
- only names are fetched from, never addresses like `192.168.1.1`, and never names that only mean
  something locally, like `localhost` or `printer.local`;
- every redirect is checked again, by the same rules.

## Limits

A site can be slow, or send endless data, by accident or on purpose. So each request has a time
limit, a page is read only as far as its first 512 KB, and an icon over 256 KB is refused. An
image's size is read from its header before it's decoded, so a small file that claims to be 50,000
pixels wide is refused without being decoded. At most three icons are tried for each site, and eight
sites are fetched at a time.

## Nothing else is shared

Requests carry no cookies, no saved passwords and nothing from earlier requests, and don't say which
page led to them. A site only learns that its home page and icon were fetched, and only once, since
the icons are kept.

## The cache

The icons, and a list of the sites that have none, are kept in the user's caches folder, so a site
is only contacted the first time it's linked to, and building again gives the same output. Deleting
the folder fetches them all again. The cache only ever holds that list and PNGs of our own.

## Limitations

- Reading an icon's pixels still runs Apple's image decoders on downloaded bytes. Accepting only a
  few formats, the size limits and the header check narrow that risk, and keeping macOS up to date
  covers the rest. Decoding in a separate, sandboxed process was judged out of proportion for icons.
- A site with only an SVG icon and no `/favicon.ico` gets the generic link icon.
- Pages are scanned with simple patterns, not read as a browser would, so unusual markup can hide an
  icon.
- A site whose icon changes keeps its old one until the cache is deleted.
