import AllumeWebModels
import Testing

@Suite struct ContentsTests {
  @Test func findsDocumentsByIDAndKeepsTheirOrder() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [makeBoard("root", cards: ["b", "a"]), makeNote("b"), makeBoard("a")],
      people: [:]
    )
    #expect(contents.documents.map(\.id.rawValue) == ["root", "b", "a"])
    #expect(contents.document(Document.ID(rawValue: "b")) == makeNote("b"))
    #expect(contents.document(Document.ID(rawValue: "missing")) == nil)
  }

  @Test func findsOnlyBoardsAsBoards() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [makeBoard("root", cards: ["b"]), makeNote("b")], people: [:])
    #expect(contents.board(Document.ID(rawValue: "root"))?.id == Document.ID(rawValue: "root"))
    #expect(contents.board(Document.ID(rawValue: "b")) == nil)
  }

  @Test func rejectsAMissingRoot() {
    #expect(throws: InvalidContentsError.missingRoot(Document.ID(rawValue: "root"))) {
      try Contents(rootID: Document.ID(rawValue: "root"), documents: [makeBoard("a")], people: [:])
    }
  }

  @Test func rejectsARootThatIsNotABoard() {
    #expect(throws: InvalidContentsError.rootNotABoard(Document.ID(rawValue: "root"))) {
      try Contents(
        rootID: Document.ID(rawValue: "root"), documents: [makeNote("root")], people: [:])
    }
  }

  @Test func rejectsDuplicateDocuments() {
    #expect(throws: InvalidContentsError.duplicateDocument(Document.ID(rawValue: "a"))) {
      try Contents(
        rootID: Document.ID(rawValue: "a"), documents: [makeBoard("a"), makeNote("a")], people: [:])
    }
  }

  @Test func rejectsADocumentOutsideTheRoot() {
    #expect(throws: InvalidContentsError.documentOutsideRoot(Document.ID(rawValue: "a"))) {
      try Contents(
        rootID: Document.ID(rawValue: "root"),
        documents: [makeBoard("root"), makeBoard("a", cards: ["note"]), makeNote("note")],
        people: [:])
    }
  }

  @Test func acceptsCommentsOnlyInThreads() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [makeBoard("root", commentThread: ["comment"]), makeComment("comment")],
      people: [:])
    #expect(contents.document(Document.ID(rawValue: "comment")) == makeComment("comment"))
  }

}
