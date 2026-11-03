extension Contents {
  /// What the initializer left out to keep the contents consistent.
  public struct Omissions: Equatable, Sendable {
    public let cardsForMissingDocuments: [Card]
    /// A comment as one of a board's own cards, or anything but a comment in a comment thread.
    public let cardsOfWrongKind: [Card]
    /// Every card after the first for the same document on a board.
    public let repeatedCards: [Card]
    /// The images whose excerpt was left out.
    public let excerptsWithMissingSources: [Document.ID]
    public let documentsOutsideRoot: [Document.ID]

    static let empty = Self()

    public init(
      cardsForMissingDocuments: [Card] = [],
      cardsOfWrongKind: [Card] = [],
      repeatedCards: [Card] = [],
      excerptsWithMissingSources: [Document.ID] = [],
      documentsOutsideRoot: [Document.ID] = []
    ) {
      self.cardsForMissingDocuments = cardsForMissingDocuments
      self.cardsOfWrongKind = cardsOfWrongKind
      self.repeatedCards = repeatedCards
      self.excerptsWithMissingSources = excerptsWithMissingSources
      self.documentsOutsideRoot = documentsOutsideRoot
    }

    public var isEmpty: Bool {
      cardsForMissingDocuments.isEmpty && cardsOfWrongKind.isEmpty && repeatedCards.isEmpty
        && excerptsWithMissingSources.isEmpty && documentsOutsideRoot.isEmpty
    }

    static func + (first: Self, second: Self) -> Self {
      Self(
        cardsForMissingDocuments: first.cardsForMissingDocuments + second.cardsForMissingDocuments,
        cardsOfWrongKind: first.cardsOfWrongKind + second.cardsOfWrongKind,
        repeatedCards: first.repeatedCards + second.repeatedCards,
        excerptsWithMissingSources: first.excerptsWithMissingSources
          + second.excerptsWithMissingSources,
        documentsOutsideRoot: first.documentsOutsideRoot + second.documentsOutsideRoot)
    }

    /// A card left out, by its board and its document.
    public struct Card: Equatable, Sendable {
      public let boardID: Document.ID
      public let documentID: Document.ID

      public init(boardID: Document.ID, documentID: Document.ID) {
        self.boardID = boardID
        self.documentID = documentID
      }
    }

    /// Why a card is left out.
    enum Reason {
      case missingDocument, wrongKind
    }
  }
}

extension Card {
  /// Nil when the card is valid: its document exists and is of the right kind, a comment in a comment
  /// thread, anything else on the board itself.
  func omissionReason(inThread: Bool, among documentsByID: [Document.ID: Document])
    -> Contents.Omissions.Reason?
  {
    switch documentsByID[documentID] {
    case .none: .missingDocument
    case .comment?: inThread ? nil : .wrongKind
    case .some: inThread ? .wrongKind : nil
    }
  }
}
