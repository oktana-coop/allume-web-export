import AllumeWebModels
import Foundation
import Testing

@testable import AllumeWebBundleReader

@Suite struct ReaderTests {
  @Test func readsTheFixtureWithoutWarnings() throws {
    let (contents, warnings) = try readBundle(at: fixtureURL)

    #expect(contents.documents.count == 56)
    #expect(contents.users.count == 2)
    #expect(contents.omissions.isEmpty)
    #expect(warnings.isEmpty)
  }

  @Test func warnsAboutAnUnknownBundleVersion() throws {
    let contents = makeContents(documents: #""root" : {"type" : "board"}"#)

    let (_, warnings) = try withBundleFolder(
      metadata: #"{"bundle_version" : 7}"#, contents: contents
    ) { folder in try readBundle(at: folder) }

    #expect(warnings == [.unknownBundleVersion(7)])
  }

  @Test func rejectsARootThatIsNotABoard() {
    let contents = makeContents(documents: #""root" : {"type" : "pdf", "label" : "A PDF"}"#)

    #expect(
      throws: UnreadableBundleError.invalidContents(.rootNotABoard(Document.ID(rawValue: "root")))
    ) {
      try withBundleFolder(contents: contents) { folder in try readBundle(at: folder) }
    }
  }

  @Test func warnsAboutWhatTheContentsLeftOut() throws {
    let cards = ["image", "image", "missing", "comment"].map { id in makeCardJSON(id) }
    let contents = makeContents(
      documents: #"""
        "root" : {"type" : "board", "cards" : [\#(cards.joined(separator: ", "))]},
        "image" : {
          "type" : "image", "label" : "", "original_file" : "i.png",
          "excerpt_info" : {"excerpted_id" : "gone"}
        },
        "comment" : {"type" : "comment", "text" : "Hi", "modifiedAt" : "2026-10-28T10:45:00Z"},
        "lost" : {"type" : "board"}
        """#)

    let (_, warnings) = try withBundleFolder(contents: contents, files: ["i.png": ""]) { folder in
      try readBundle(at: folder)
    }

    let root = Document.ID(rawValue: "root")
    #expect(
      warnings == [
        .unknownCommentAuthor(Document.ID(rawValue: "comment")),
        .cardForMissingDocument(boardID: root, documentID: Document.ID(rawValue: "missing")),
        .cardOfWrongKind(boardID: root, documentID: Document.ID(rawValue: "comment")),
        .repeatedCard(boardID: root, documentID: Document.ID(rawValue: "image")),
        .excerptWithMissingSource(Document.ID(rawValue: "image")),
        .documentOutsideRoot(Document.ID(rawValue: "comment")),
        .documentOutsideRoot(Document.ID(rawValue: "lost")),
      ])
  }
}
