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
    #expect(contents.omissions.isEmpty)
  }

  @Test func findsOnlyBoardsAsBoards() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [makeBoard("root", cards: ["b"]), makeNote("b")],
      people: [:]
    )

    #expect(contents.board(Document.ID(rawValue: "root"))?.id == Document.ID(rawValue: "root"))
    #expect(contents.board(Document.ID(rawValue: "b")) == nil)
  }

  @Test func rejectsAMissingRoot() {
    #expect(throws: InvalidContentsError.missingRoot(Document.ID(rawValue: "root"))) {
      try Contents(
        rootID: Document.ID(rawValue: "root"),
        documents: [makeBoard("a")],
        people: [:]
      )
    }
  }

  @Test func rejectsARootThatIsNotABoard() {
    #expect(throws: InvalidContentsError.rootNotABoard(Document.ID(rawValue: "root"))) {
      try Contents(
        rootID: Document.ID(rawValue: "root"),
        documents: [makeNote("root")],
        people: [:]
      )
    }
  }

  @Test func rejectsDuplicateDocuments() {
    #expect(throws: InvalidContentsError.duplicateDocument(Document.ID(rawValue: "a"))) {
      try Contents(
        rootID: Document.ID(rawValue: "a"),
        documents: [makeBoard("a"), makeNote("a")],
        people: [:]
      )
    }
  }

  @Test func omitsDocumentsOutsideTheRoot() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [makeBoard("root"), makeBoard("a", cards: ["note"]), makeNote("note")],
      people: [:]
    )

    #expect(contents.documents.map(\.id.rawValue) == ["root"])
    #expect(contents.omissions.documentsOutsideRoot.map(\.rawValue) == ["a", "note"])
  }

  @Test func omitsCardsForMissingDocuments() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [makeBoard("root", cards: ["note", "missing"]), makeNote("note")],
      people: [:]
    )

    let cards = contents.board(Document.ID(rawValue: "root"))?.cards
    #expect(cards?.map(\.documentID.rawValue) == ["note"])
    #expect(contents.omissions.cardsForMissingDocuments == [omittedCard("root", "missing")])
  }

  @Test func omitsCardsOfTheWrongKindAndTheDocumentsLeftOutsideTheRoot() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        makeBoard("root", cards: ["comment"], commentThread: ["note"]),
        makeComment("comment"),
        makeNote("note"),
      ],
      people: [:]
    )

    #expect(
      contents.omissions.cardsOfWrongKind == [
        omittedCard("root", "comment"), omittedCard("root", "note"),
      ])
    #expect(contents.omissions.documentsOutsideRoot.map(\.rawValue) == ["comment", "note"])
  }

  @Test func omitsConnectionsToOmittedCards() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        makeBoard(
          "root", cards: ["a", "b", "missing"], connections: [("a", "b"), ("a", "missing")]),
        makeNote("a"),
        makeNote("b"),
      ],
      people: [:]
    )

    let connections = contents.board(Document.ID(rawValue: "root"))?.connections
    #expect(
      connections == [
        Connection(from: .card(Document.ID(rawValue: "a")), to: .card(Document.ID(rawValue: "b")))
      ])
  }

  @Test func omitsExcerptsWhoseSourceIsMissingOrOutsideTheRoot() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        makeBoard("root", cards: ["first", "second"]),
        makeImage("first", excerptOf: "missing"),
        makeImage("second", excerptOf: "outside"),
        makeNote("outside"),
      ],
      people: [:]
    )

    #expect(contents.document(Document.ID(rawValue: "first")) == makeImage("first"))
    #expect(contents.document(Document.ID(rawValue: "second")) == makeImage("second"))
    #expect(contents.omissions.excerptsWithMissingSources.map(\.rawValue) == ["first", "second"])
    #expect(contents.omissions.documentsOutsideRoot.map(\.rawValue) == ["outside"])
  }

  @Test func acceptsCommentsOnlyInThreads() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [makeBoard("root", commentThread: ["comment"]), makeComment("comment")],
      people: [:]
    )

    #expect(contents.document(Document.ID(rawValue: "comment")) == makeComment("comment"))
    #expect(contents.omissions.isEmpty)
  }
}

private func omittedCard(_ boardID: String, _ documentID: String) -> Contents.Omissions.Card {
  Contents.Omissions.Card(
    boardID: Document.ID(rawValue: boardID), documentID: Document.ID(rawValue: documentID))
}
