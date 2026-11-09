import AllumeWebModels
import AllumeWebRendering

/// What references lead to on a site: each published board's URL, and the prefix of every file's.
package struct ReferenceURLs: Sendable {
  /// E.g. `functional-q5tbqj.html`.
  package let boards: [Document.ID: String]
  /// E.g. `files/`, which each file's path is added to.
  package let files: String

  package init(boards: [Document.ID: String], files: String) {
    self.boards = boards
    self.files = files
  }
}

/// A reference to a board the URLs don't list, which would be a broken link.
package struct UnknownBoardError: Error, Equatable, Sendable {
  package let boardID: Document.ID
}

/// Each board's URL, from the pattern, with `{slug}` standing for the board's slug.
func boardURLs(pattern: String, in index: BoardsIndex) -> [Document.ID: String] {
  index.boards.mapValues { board in pattern.replacingOccurrences(of: "{slug}", with: board.slug) }
}

extension Reference {
  /// What it resolves to: its board's or its file's URL.
  func url(in urls: ReferenceURLs) throws(UnknownBoardError) -> String {
    switch self {
    case .board(let board): try board.url(in: urls)
    case .file(let file): file.url(in: urls)
    }
  }
}

extension BoardReference {
  /// The board's URL, with a card on it as the hash.
  func url(in urls: ReferenceURLs) throws(UnknownBoardError) -> String {
    guard let page = urls.boards[boardID] else {
      throw UnknownBoardError(boardID: boardID)
    }

    return page + (cardID.map { cardID in "#card-\(cardID.rawValue)" } ?? "")
  }
}

extension FileReference {
  /// Its path after the files prefix.
  func url(in urls: ReferenceURLs) -> String {
    urls.files + encodedPath
  }
}
