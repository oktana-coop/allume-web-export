public enum InvalidContentsError: Error, Equatable, Sendable {
    case missingRoot(Document.ID)
    case rootNotABoard(Document.ID)
    case duplicateDocument(Document.ID)
}
