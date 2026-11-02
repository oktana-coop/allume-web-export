public struct Hierarchy: Equatable, Sendable {
  /// Each document's parents: the boards that have it as a card or a comment, in breadth-first order
  /// from the root.
  private let parentIDs: [Document.ID: [Document.ID]]
  /// Each board's primary ancestors, from the root down to its primary parent: the first of its
  /// parents in breadth-first order, so one of the closest to the root.
  private let primaryAncestorIDs: [Document.ID: [Document.ID]]

  init(rootID: Document.ID, documents: [Document]) throws(InvalidContentsError) {
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

    let rootDescendantIDs = Set(childParentPairs.map { pair in pair.childID })
    if let outsider = documents.first(where: { document in
      document.id != rootID && !rootDescendantIDs.contains(document.id)
    }) {
      throw .documentOutsideRoot(outsider.id)
    }

    self.parentIDs = Dictionary(grouping: childParentPairs, by: { pair in pair.childID })
      .mapValues { pairs in
        pairs.uniqued(by: { pair in pair.parentID }).map { pair in pair.parentID }
      }
    self.primaryAncestorIDs = Dictionary(
      uniqueKeysWithValues: orderedBoards.map { entry in
        (entry.board.id, entry.primaryAncestorIDs)
      })
  }

  /// The boards that have the document as a card or a comment, in breadth-first order from the root,
  /// so a board's primary parent comes first.
  public func parents(of documentID: Document.ID) -> [Document.ID] {
    parentIDs[documentID, default: []]
  }

  /// A board's primary ancestors, from the root down to its primary parent: the first of its parents
  /// in breadth-first order, so one of the closest to the root.
  public func primaryAncestors(of boardID: Document.ID) -> [Document.ID] {
    primaryAncestorIDs[boardID, default: []]
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
      .uniqued(by: { child in child.board.id })
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

extension Sequence {
  /// Keeps the first element for each key, in order.
  fileprivate func uniqued<Key: Hashable>(by key: (Element) -> Key) -> [Element] {
    let elements = Array(self)
    let firstIndices = Dictionary(
      elements.enumerated().map { index, element in (key(element), index) },
      uniquingKeysWith: { first, _ in first }
    )
    return elements.indices
      .filter { index in firstIndices[key(elements[index])] == index }
      .map { index in elements[index] }
  }
}
