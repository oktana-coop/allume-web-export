/// A board, everything inside it, and the people who commented. The boards form
/// a graph, not a tree, since a board can sit in several boards.
public struct Contents: Equatable, Sendable {
  public let rootID: Document.ID
  /// In the order the input lists them.
  public let documents: [Document]
  public let people: [Person.ID: Person]

  private let documentIndices: [Document.ID: Int]

  /// Throws if the root is missing or isn't a board, or if two documents share an ID.
  /// References between documents, like a card's `documentID`, aren't checked.
  public init(
    rootID: Document.ID,
    documents: [Document],
    people: [Person.ID: Person]
  ) throws(InvalidContentsError) {
    let documentIndices = Dictionary(
      documents.enumerated().map { index, document in (document.id, index) },
      // For duplicate IDs, use the first index the document is found at.
      uniquingKeysWith: { first, _ in first }
    )
    if let duplicateIndex = documents.indices.first(where: { index in
      documentIndices[documents[index].id] != index
    }) {
      throw .duplicateDocument(documents[duplicateIndex].id)
    }
    guard let rootIndex = documentIndices[rootID] else {
      throw .missingRoot(rootID)
    }
    guard case .board = documents[rootIndex] else {
      throw .rootNotABoard(rootID)
    }
    self.rootID = rootID
    self.documents = documents
    self.people = people
    self.documentIndices = documentIndices
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
}
