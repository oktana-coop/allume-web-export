/// A board, everything inside it, and the users who commented. The boards form
/// a graph, not a tree, since a board can sit in several boards.
public struct Contents: Equatable, Sendable {
  public let rootID: Document.ID
  public let documents: [Document]
  public let users: [User.ID: User]
  public let hierarchy: Hierarchy
  public let omissions: Omissions

  private let documentIndices: [Document.ID: Int]

  /// Throws if the root is missing or isn't a board, or if two documents share an ID. Whatever else
  /// would make the contents inconsistent is left out, and recorded in `omissions`. A connection
  /// repeated in either direction is left out too, but not recorded, since its ends stay connected.
  public init(
    rootID: Document.ID,
    documents: [Document],
    users: [User.ID: User]
  ) throws(InvalidContentsError) {
    let inputIndices = Dictionary(
      documents.enumerated().map { index, document in (document.id, index) },
      // For duplicate IDs, use the first index the document is found at.
      uniquingKeysWith: { first, _ in first }
    )
    if let duplicateIndex = documents.indices.first(where: { index in
      inputIndices[documents[index].id] != index
    }) {
      throw .duplicateDocument(documents[duplicateIndex].id)
    }

    guard let rootIndex = inputIndices[rootID] else {
      throw .missingRoot(rootID)
    }
    guard case .board = documents[rootIndex] else {
      throw .rootNotABoard(rootID)
    }

    let (validDocuments, omissions) = Self.removingInconsistencies(from: documents, rootID: rootID)

    self.rootID = rootID
    self.documents = validDocuments
    self.users = users
    self.hierarchy = Hierarchy(rootID: rootID, documents: validDocuments)
    self.omissions = omissions
    self.documentIndices = Dictionary(
      uniqueKeysWithValues: validDocuments.enumerated().map { index, document in
        (document.id, index)
      })
  }

  public func document(_ id: Document.ID) -> Document? {
    documentIndices[id].map { documents[$0] }
  }

  public func board(_ id: Document.ID) -> Document.Board? {
    guard case .board(let board) = document(id) else {
      return nil
    }
    return board
  }

  /// Each step can leave something for the next to remove: removing a card can leave its document
  /// outside the root, and a document outside the root can be an excerpt's source. Repeats are removed
  /// after invalid cards, so a valid card is never dropped for repeating an invalid one.
  private static func removingInconsistencies(from documents: [Document], rootID: Document.ID)
    -> (documents: [Document], omissions: Omissions)
  {
    let steps: [([Document]) -> (documents: [Document], omissions: Omissions)] = [
      { documents in removingInvalidCards(from: documents) },
      { documents in removingRepeatedCards(from: documents) },
      { documents in (removingRepeatedConnections(from: documents), .empty) },
      { documents in removingDocumentsOutsideRoot(from: documents, rootID: rootID) },
      { documents in removingMissingExcerptSources(from: documents) },
    ]

    return steps.reduce((documents: documents, omissions: .empty)) { result, step in
      let (documents, omissions) = step(result.documents)
      return (documents, result.omissions + omissions)
    }
  }

  private static func removingInvalidCards(from documents: [Document])
    -> (documents: [Document], omissions: Omissions)
  {
    let documentsByID = Dictionary(
      uniqueKeysWithValues: documents.map { document in (document.id, document) })

    let results = documents.map { document -> (document: Document, omissions: Omissions) in
      guard case .board(let board) = document else {
        return (document, .empty)
      }
      let (validBoard, omissions) = removingInvalidCards(from: board, among: documentsByID)
      return (.board(validBoard), omissions)
    }

    return (
      results.map { result in result.document },
      results.map { result in result.omissions }.reduce(.empty, +)
    )
  }

  /// A board keeps the first card for each document: its own cards first, then its threads' cards.
  private static func removingRepeatedCards(from documents: [Document])
    -> (documents: [Document], omissions: Omissions)
  {
    let results = documents.map { document -> (document: Document, omissions: Omissions) in
      guard case .board(let board) = document else {
        return (document, .empty)
      }
      let (withoutRepeats, omissions) = removingRepeatedCards(from: board)
      return (.board(withoutRepeats), omissions)
    }

    return (
      results.map { result in result.document },
      results.map { result in result.omissions }.reduce(.empty, +)
    )
  }

  private static func removingRepeatedCards(from board: Document.Board)
    -> (board: Document.Board, omissions: Omissions)
  {
    // Where each card is: nil for the board's own cards, else the index of its chain.
    let locatedCards =
      board.cards.enumerated().map { index, card in (chain: Int?.none, index: index, card: card) }
      + board.chains.enumerated().flatMap { chainIndex, chain in
        guard case .comments(let thread) = chain else {
          return [(chain: Int?, index: Int, card: Card)]()
        }
        return thread.cards.enumerated().map { index, card in
          (chain: Int?.some(chainIndex), index: index, card: card)
        }
      }
    let firstPlaces = Dictionary(
      locatedCards.map { located in (located.card.documentID, (located.chain, located.index)) },
      uniquingKeysWith: { first, _ in first }
    )
    let isFirst = { (chain: Int?, index: Int, card: Card) in
      firstPlaces[card.documentID].map { first in first == (chain, index) } ?? false
    }

    let cards = board.cards.enumerated().filter { index, card in isFirst(nil, index, card) }
      .map { _, card in card }
    let chains = board.chains.enumerated().map { chainIndex, chain -> Chain in
      guard case .comments(let thread) = chain else {
        return chain
      }
      let firstCards = thread.cards.enumerated().filter { index, card in
        isFirst(chainIndex, index, card)
      }.map { _, card in card }
      return .comments(CommentThread(id: thread.id, cards: firstCards))
    }
    let repeats = locatedCards.filter { located in
      !isFirst(located.chain, located.index, located.card)
    }

    let withoutRepeats = Document.Board(
      id: board.id, label: board.label, cards: cards, chains: chains,
      connections: board.connections, ink: board.ink)
    let omissions = Omissions(
      repeatedCards: repeats.map { located in
        Omissions.Card(boardID: board.id, documentID: located.card.documentID)
      })

    return (withoutRepeats, omissions)
  }

  /// Allume stores some connections in both directions. A board keeps the first connection for each
  /// pair of ends.
  private static func removingRepeatedConnections(from documents: [Document]) -> [Document] {
    documents.map { document in
      guard case .board(let board) = document else {
        return document
      }
      let connections = board.connections.uniqued { connection in
        Set([connection.from, connection.to])
      }
      return .board(
        Document.Board(
          id: board.id, label: board.label, cards: board.cards, chains: board.chains,
          connections: connections, ink: board.ink))
    }
  }

  /// The hierarchy only lists parents under the root.
  private static func removingDocumentsOutsideRoot(from documents: [Document], rootID: Document.ID)
    -> (documents: [Document], omissions: Omissions)
  {
    let hierarchy = Hierarchy(rootID: rootID, documents: documents)
    let isUnderRoot = { (document: Document) in
      document.id == rootID || !hierarchy.parents(of: document.id).isEmpty
    }

    return (
      documents.filter(isUnderRoot),
      Omissions(
        documentsOutsideRoot: documents.filter { document in !isUnderRoot(document) }
          .map { document in document.id })
    )
  }

  /// An excerpt goes when its source is missing, or was outside the root. The image stays.
  private static func removingMissingExcerptSources(from documents: [Document])
    -> (documents: [Document], omissions: Omissions)
  {
    let documentIDs = Set(documents.map { document in document.id })

    let results = documents.map { document -> (document: Document, omissions: Omissions) in
      guard case .image(let image) = document, let sourceID = image.excerpt?.sourceID,
        !documentIDs.contains(sourceID)
      else {
        return (document, .empty)
      }
      let withoutExcerpt = Document.Image(
        id: image.id, label: image.label, file: image.file, excerpt: nil)
      return (.image(withoutExcerpt), Omissions(excerptsWithMissingSources: [image.id]))
    }

    return (
      results.map { result in result.document },
      results.map { result in result.omissions }.reduce(.empty, +)
    )
  }

  /// The board without its invalid cards, and without the connections to them, with the cards it
  /// left out.
  private static func removingInvalidCards(
    from board: Document.Board, among documentsByID: [Document.ID: Document]
  ) -> (board: Document.Board, omissions: Omissions) {
    let boardCards = board.cards.map { card in
      (card: card, reason: card.omissionReason(inThread: false, among: documentsByID))
    }
    let threadCards = board.chains.map { chain -> [(card: Card, reason: Omissions.Reason?)] in
      guard case .comments(let thread) = chain else {
        return []
      }
      return thread.cards.map { card in
        (card: card, reason: card.omissionReason(inThread: true, among: documentsByID))
      }
    }

    let validCards = boardCards.filter { entry in entry.reason == nil }.map { entry in entry.card }
    let validChains = zip(board.chains, threadCards).map { chain, entries -> Chain in
      guard case .comments(let thread) = chain else {
        return chain
      }
      let valid = entries.filter { entry in entry.reason == nil }.map { entry in entry.card }
      return .comments(CommentThread(id: thread.id, cards: valid))
    }

    // A connection goes with the cards it joins.
    let endpoints = Set(
      validCards.map { card in Connection.Endpoint.card(card.documentID) }
        + validChains.flatMap { chain -> [Connection.Endpoint] in
          switch chain {
          case .text(let text): [.chain(text.id)]
          case .comments(let thread):
            [.chain(thread.id)] + thread.cards.map { card in .card(card.documentID) }
          }
        })
    let validConnections = board.connections.filter { connection in
      endpoints.contains(connection.from) && endpoints.contains(connection.to)
    }

    let checkedCards = boardCards + threadCards.flatMap { entries in entries }
    let omitted = { (reason: Omissions.Reason) in
      checkedCards.filter { entry in entry.reason == reason }.map { entry in
        Omissions.Card(boardID: board.id, documentID: entry.card.documentID)
      }
    }

    let validBoard = Document.Board(
      id: board.id, label: board.label, cards: validCards, chains: validChains,
      connections: validConnections, ink: board.ink)
    let omissions = Omissions(
      cardsForMissingDocuments: omitted(.missingDocument), cardsOfWrongKind: omitted(.wrongKind))

    return (validBoard, omissions)
  }
}
