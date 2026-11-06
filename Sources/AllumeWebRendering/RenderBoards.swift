import AllumeWebModels
import Foundation

package struct Page: Equatable, Sendable {
  /// From the site's folder, e.g. `index.html` or `functional-q5tbqj.html`.
  package let path: String
  package let html: String
}

/// Each board as a standalone page, in breadth-first order from the root, and the files the pages
/// refer to, once each, in the order they're first referred to.
package func renderBoards(_ contents: Contents, favicons: [String: Asset])
  -> (pages: [Page], files: [PublishedFile])
{
  let paths = pagePaths(in: contents)
  let boardLayouts = layouts(in: contents)
  let trees = contents.hierarchy.boardIDs.compactMap { boardID in
    contents.board(boardID).map { board in
      (
        path: paths[boardID] ?? "",
        tree: drawPageShell(
          title: pageTitle(of: board, in: contents),
          view: drawBoardView(
            board, contents: contents, layouts: boardLayouts, favicons: favicons))
      )
    }
  }

  let pages = trees.map { path, tree in
    Page(
      path: path,
      html: tree.map { node in
        node.rendered(resolving: { reference in standaloneURL(of: reference, pagePaths: paths) })
      }.joined())
  }
  let files = trees.flatMap { _, tree in tree.flatMap { node in node.files } }
    .uniqued(on: \.path)
  return (pages, files)
}

/// Pages sit side by side, the root's as `index.html` and the others named after their slugs.
private func pagePaths(in contents: Contents) -> [Document.ID: String] {
  slugs(in: contents).mapValues { slug in "\(slug).html" }
    .merging([contents.rootID: "index.html"]) { _, root in root }
}

/// Files are under `files/`, with each segment of their path percent-encoded as JavaScript's
/// `encodeURIComponent` does.
private func standaloneURL(of reference: Reference, pagePaths: [Document.ID: String]) -> String {
  switch reference {
  case .board(let boardID, let cardID):
    (pagePaths[boardID] ?? "") + (cardID.map { cardID in "#card-\(cardID.rawValue)" } ?? "")
  case .file(let file):
    "files/"
      + file.path.split(separator: "/", omittingEmptySubsequences: false).map { segment in
        segment.addingPercentEncoding(withAllowedCharacters: uriComponentCharacters)
          ?? String(segment)
      }.joined(separator: "/")
  }
}

/// What `encodeURIComponent` leaves as is.
private let uriComponentCharacters = CharacterSet(
  charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.!~*'()")
