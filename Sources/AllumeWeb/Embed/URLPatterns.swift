import AllumeWebModels
import AllumeWebRendering

/// The site's patterns for the URLs `embed` resolves references to. Without a pattern, that kind of
/// reference is kept, for the site to replace.
package struct URLPatterns: Sendable {
  /// Each board's URL, with `{slug}` standing for the board's slug, e.g. `/boards/{slug}/`.
  package let board: String?
  /// Where the site serves the folder's `files/`, e.g. `/allume/files`.
  package let files: String?

  package init(board: String? = nil, files: String? = nil) {
    self.board = board
    self.files = files
  }
}

/// The view's HTML, with each reference that has a pattern resolved to its URL.
func resolvingReferences(in view: BoardView, urlPatterns: URLPatterns, index: BoardsIndex) -> String
{
  let urls = ReferenceURLs(
    boards: urlPatterns.board.map { pattern in boardURLs(pattern: pattern, in: index) } ?? [:],
    files: urlPatterns.files.map { url in url.hasSuffix("/") ? url : url + "/" } ?? "")

  // The index lists every published board, which are all a view can refer to.
  guard
    let html = try? resolvingReferences(
      in: view.html,
      with: { reference throws(UnknownBoardError) in
        try resolved(reference, urlPatterns: urlPatterns, urls: urls)
      })
  else {
    preconditionFailure("A view refers to a board the index doesn't list.")
  }
  return html
}

/// The reference's URL, from the pattern for its kind, or the reference itself without one.
private func resolved(
  _ reference: Reference, urlPatterns: URLPatterns, urls: ReferenceURLs
) throws(UnknownBoardError) -> String {
  switch reference {
  case .board(let board):
    guard urlPatterns.board != nil else {
      return reference.text
    }
    return try board.url(in: urls)
  case .file(let file):
    guard urlPatterns.files != nil else {
      return reference.text
    }
    return file.url(in: urls)
  }
}
