public struct Hierarchy: Equatable, Sendable {
  /// The root and the boards under it, in breadth-first order: level by level, and within a level in
  /// the order of the previous level's cards.
  public let boardIDs: [Document.ID]
  /// Each document's parents: the boards under the root that have it as a card or a comment, in
  /// breadth-first order from the root.
  private let parentIDs: [Document.ID: [Document.ID]]
  /// Each board's primary ancestors, from the root down to its primary parent: the first of its
  /// parents in breadth-first order, so one of the closest to the root.
  private let primaryAncestorIDs: [Document.ID: [Document.ID]]
  /// Each board's nesting level, as `nestingLevel(of:)` gives it.
  private let nestingLevels: [Document.ID: Int]

  init(rootID: Document.ID, documents: [Document]) {
    let boardsByID = Dictionary(
      documents.compactMap { document -> (Document.ID, Document.Board)? in
        guard case .board(let board) = document else {
          return nil
        }
        return (board.id, board)
      },
      uniquingKeysWith: { first, _ in first }
    )

    let orderedBoards = Self.orderedBoards(rootID: rootID, boardsByID: boardsByID)
    let childParentPairs = orderedBoards.flatMap { entry in
      entry.board.allCards.map { card in (childID: card.documentID, parentID: entry.board.id) }
    }

    self.boardIDs = orderedBoards.map { entry in entry.board.id }
    self.parentIDs = Dictionary(grouping: childParentPairs, by: { pair in pair.childID })
      .mapValues { pairs in
        pairs.uniqued(on: { pair in pair.parentID }).map { pair in pair.parentID }
      }
    self.primaryAncestorIDs = Dictionary(
      uniqueKeysWithValues: orderedBoards.map { entry in
        (entry.board.id, entry.primaryAncestorIDs)
      })
    self.nestingLevels = Dictionary(
      uniqueKeysWithValues: orderedBoards.map { entry in
        (entry.board.id, Self.nestingLevel(of: entry.board, boardsByID: boardsByID, visiting: []))
      })
  }

  /// The boards under the root that have the document as a card or a comment, in breadth-first order
  /// from the root, so a board's primary parent comes first.
  public func parents(of documentID: Document.ID) -> [Document.ID] {
    parentIDs[documentID, default: []]
  }

  /// A board's primary ancestors, from the root down to its primary parent: the first of its parents
  /// in breadth-first order, so one of the closest to the root.
  public func primaryAncestors(of boardID: Document.ID) -> [Document.ID] {
    primaryAncestorIDs[boardID, default: []]
  }

  /// How many levels of boards the board holds: 0 when none of its cards is a board, and otherwise
  /// one more than the highest of theirs. Linked boards can hold each other in a cycle, which counts
  /// up to where it closes. 0 for other documents and unknown IDs.
  public func nestingLevel(of boardID: Document.ID) -> Int {
    nestingLevels[boardID, default: 0]
  }

  private static func nestingLevel(
    of board: Document.Board, boardsByID: [Document.ID: Document.Board],
    visiting: Set<Document.ID>
  ) -> Int {
    let visiting = visiting.union([board.id])
    return board.cards.compactMap { card in boardsByID[card.documentID] }
      .filter { child in !visiting.contains(child.id) }
      .map { child in nestingLevel(of: child, boardsByID: boardsByID, visiting: visiting) + 1 }
      .max() ?? 0
  }

  private struct BoardWithPrimaryAncestors {
    let board: Document.Board
    let primaryAncestorIDs: [Document.ID]
  }

  /// The root and the boards under it, in breadth-first order: level by level, and within a level in
  /// the order of the previous level's cards.
  private static func orderedBoards(
    rootID: Document.ID,
    boardsByID: [Document.ID: Document.Board]
  ) -> [BoardWithPrimaryAncestors] {
    /// The boards below the level, level by level, leaving out the boards already known.
    func boardsBelow(_ level: [BoardWithPrimaryAncestors], excluding known: Set<Document.ID>)
      -> [BoardWithPrimaryAncestors]
    {
      // A board that several boards on this level have as a card keeps the first one's path.
      let nextLevel = level.flatMap { parent in
        parent.board.allCards
          .compactMap { card in boardsByID[card.documentID] }
          .filter { child in !known.contains(child.id) }
          .map { child in
            BoardWithPrimaryAncestors(
              board: child, primaryAncestorIDs: parent.primaryAncestorIDs + [parent.board.id])
          }
      }
      .uniqued(on: { child in child.board.id })
      guard !nextLevel.isEmpty else {
        return []
      }

      return nextLevel
        + boardsBelow(nextLevel, excluding: known.union(nextLevel.map { child in child.board.id }))
    }

    return boardsByID[rootID].map { root in
      let rootLevel = [BoardWithPrimaryAncestors(board: root, primaryAncestorIDs: [])]
      return rootLevel + boardsBelow(rootLevel, excluding: [rootID])
    } ?? []
  }
}

extension Document.Board {
  /// Its own cards, then those in its comment threads.
  fileprivate var allCards: [Card] {
    let threadCards = chains.flatMap { chain -> [Card] in
      switch chain {
      case .text: []
      case .comments(let thread): thread.cards
      }
    }
    return cards + threadCards
  }
}
