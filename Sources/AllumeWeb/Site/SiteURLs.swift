import AllumeWebModels

/// The site's pages side by side, the root's as `index.html` and the others named after their
/// slugs, and its files under `files/`.
package func siteURLs(for index: BoardsIndex) -> ReferenceURLs {
  let boards = boardURLs(pattern: "{slug}.html", in: index)
    .merging([index.root: "index.html"]) { _, root in root }

  return ReferenceURLs(boards: boards, files: "files/")
}
