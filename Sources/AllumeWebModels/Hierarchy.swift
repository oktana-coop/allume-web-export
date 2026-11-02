public struct Hierarchy: Equatable, Sendable {
  /// Each document's parents: the boards that have it as a card or a comment.
  private let parentIDs: [Document.ID: [Document.ID]]
  /// A board's primary ancestors, from the root down to its primary parent. That's the board that
  /// first reaches it on a breadth-first walk from the root, so it's one of the closest to the root.
  private let primaryAncestorIDs: [Document.ID: [Document.ID]]

  init(rootID: Document.ID, documents: [Document]) throws(InvalidContentsError) {
    let boards: [Document.Board] = documents.compactMap { document in
      guard case .board(let board) = document else {
        return nil
      }
      return board
    }
    let boardsByID = Dictionary(
      boards.map { board in (board.id, board) },
      uniquingKeysWith: { first, _ in first }
    )

    let primaryAncestorIDs = Self.primaryAncestorIDs(rootID: rootID, boards: boardsByID)

    let childParentPairs = boards.flatMap { board in
      board.allCards.map { card in (childID: card.documentID, parentID: board.id) }
    }

    let reachableIDs = Set(
      childParentPairs
        .filter { pair in primaryAncestorIDs[pair.parentID] != nil }
        .map { pair in pair.childID }
    ).union([rootID])
    if let unreachable = documents.first(where: { document in
      !reachableIDs.contains(document.id)
    }) {
      throw .unreachableDocument(unreachable.id)
    }

    self.parentIDs = Dictionary(grouping: childParentPairs, by: { pair in pair.childID })
      .mapValues { pairs in
        pairs.uniqued(by: { pair in pair.parentID }).map { pair in pair.parentID }
      }
    self.primaryAncestorIDs = primaryAncestorIDs
  }

  /// The boards that have the document as a card or a comment, in the order the input lists them.
  public func parents(of documentID: Document.ID) -> [Document.ID] {
    parentIDs[documentID] ?? []
  }

  /// A board's primary ancestors, from the root down to its primary parent. That's the board that
  /// first reaches it on a breadth-first walk from the root, so it's one of the closest to the root.
  public func primaryAncestors(of boardID: Document.ID) -> [Document.ID] {
    primaryAncestorIDs[boardID] ?? []
  }

  private static func primaryAncestorIDs(
    rootID: Document.ID,
    boards: [Document.ID: Document.Board]
  ) -> [Document.ID: [Document.ID]] {
    func walk(
      level: [Document.ID],
      known: [Document.ID: [Document.ID]]
    ) -> [Document.ID: [Document.ID]] {
      // A board that several boards on this level have as a card keeps the first one's path.
      let newPaths = level.flatMap { parentID in
        let path = (known[parentID] ?? []) + [parentID]
        return (boards[parentID]?.allCards ?? [])
          .map { card in card.documentID }
          .filter { childID in boards[childID] != nil && known[childID] == nil }
          .map { childID in (childID, path) }
      }
      .uniqued(by: { childID, _ in childID })
      guard !newPaths.isEmpty else {
        return known
      }

      return walk(
        level: newPaths.map { childID, _ in childID },
        known: known.merging(newPaths, uniquingKeysWith: { first, _ in first })
      )
    }

    return walk(level: [rootID], known: [rootID: []])
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
