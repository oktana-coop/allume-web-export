import AllumeWebModels
import AllumeWebRendering
import Foundation

/// The published boards, as `boards.json` describes them for a site to route and link them.
package struct BoardsIndex: Equatable, Sendable {
  /// The exported board.
  package let root: Document.ID
  package let boards: [Document.ID: Board]

  package struct Board: Equatable, Sendable {
    package let label: String
    /// A suggestion for the board's URL, e.g. `functional-q5tbqj`, which sites may ignore.
    package let slug: String
    /// Every published board that has this one as a card, its primary parent first.
    package let parents: [Document.ID]
    /// Its view's path in the folder, e.g. `boards/<board-id>.html`.
    package let view: String
  }
}

/// The index of every board published from the export.
package func boardsIndex(for contents: Contents) -> BoardsIndex {
  let slugs = slugs(in: contents)
  let boards = contents.hierarchy.boardIDs.compactMap { boardID in
    contents.board(boardID).map { board in
      (
        boardID,
        BoardsIndex.Board(
          label: board.displayLabel, slug: slugs[boardID] ?? boardID.rawValue,
          parents: contents.hierarchy.parents(of: boardID), view: viewPath(of: boardID))
      )
    }
  }

  return BoardsIndex(root: contents.rootID, boards: Dictionary(uniqueKeysWithValues: boards))
}

/// Where the board's view is in the folder.
func viewPath(of boardID: Document.ID) -> String {
  "boards/\(boardID.rawValue).html"
}

/// The index as `boards.json`, its keys sorted, so the same boards give the same file.
package func boardsJSON(_ index: BoardsIndex) -> String {
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

  // Strings and arrays of them always encode.
  guard let json = try? encoder.encode(index) else {
    preconditionFailure("The boards index didn't encode.")
  }
  return String(decoding: json, as: UTF8.self)
}

extension BoardsIndex: Encodable {
  private enum CodingKeys: String, CodingKey {
    case version, root, boards
  }

  package func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(1, forKey: .version)
    try container.encode(root.rawValue, forKey: .root)
    try container.encode(
      Dictionary(uniqueKeysWithValues: boards.map { boardID, board in (boardID.rawValue, board) }),
      forKey: .boards)
  }
}

extension BoardsIndex.Board: Encodable {
  private enum CodingKeys: String, CodingKey {
    case label, slug, parents, view
  }

  package func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(label, forKey: .label)
    try container.encode(slug, forKey: .slug)
    try container.encode(parents.map(\.rawValue), forKey: .parents)
    try container.encode(view, forKey: .view)
  }
}
