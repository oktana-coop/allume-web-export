import AllumeWebModels
import Foundation
import Testing

@testable import AllumeWebBundleReader

@Suite struct DocumentsTests {
  @Test func readsTheFixtureWithoutWarnings() throws {
    let bundle = try AllumeBundle(contentsOf: fixtureURL)

    let (documents, warnings) = readDocuments(in: bundle)

    let kinds = Dictionary(grouping: documents, by: kind).mapValues { group in group.count }
    #expect(kinds == ["note": 7, "link": 10, "image": 18, "pdf": 2, "comment": 6])
    #expect(warnings.isEmpty)
  }

  @Test func readsACommentsAuthorAndDate() throws {
    let bundle = try AllumeBundle(contentsOf: fixtureURL)
    let jonas = bundle.contents.users?.first { _, user in user.userFullName == "Jonas Berg" }?.key

    let comments = readDocuments(in: bundle).documents.compactMap { document -> Document.Comment? in
      guard case .comment(let comment) = document else {
        return nil
      }
      return comment
    }

    let datalog = comments.first { comment in comment.text == "Datalog would fit here too." }
    #expect(datalog?.authorID?.rawValue == jonas)
    #expect(datalog?.modifiedAt.formatted(.iso8601) == "2026-10-28T10:45:00Z")
  }

  @Test func readsANotesTextFromItsFile() throws {
    let contents = makeContents(documents: #""n" : {"type" : "text", "original_file" : "n.txt"}"#)

    let (documents, warnings) = try withBundle(contents: contents, files: ["n.txt": "One\n\nTwo"]) {
      bundle in readDocuments(in: bundle)
    }

    #expect(documents == [.note(Document.Note(id: Document.ID(rawValue: "n"), text: "One\n\nTwo"))])
    #expect(warnings.isEmpty)
  }

  @Test func leavesANoteEmptyWhenItsFileIsMissing() throws {
    let contents = makeContents(documents: #""n" : {"type" : "text", "original_file" : "n.txt"}"#)

    let (documents, warnings) = try withBundle(contents: contents) { bundle in
      readDocuments(in: bundle)
    }

    #expect(documents == [.note(Document.Note(id: Document.ID(rawValue: "n"), text: ""))])
    #expect(warnings == [.missingFile(name: "n.txt")])
  }

  @Test func turnsEmptyLabelsAndTitlesIntoNil() throws {
    let contents = makeContents(
      documents: #"""
        "l" : {"type" : "url", "url" : "example.com", "title" : "", "label" : ""},
        "p" : {"type" : "pdf", "label" : ""}
        """#)

    let documents = try withBundle(contents: contents) { bundle in
      readDocuments(in: bundle).documents
    }

    #expect(
      documents == [
        .link(
          Document.Link(id: Document.ID(rawValue: "l"), url: "example.com", title: nil, label: nil)),
        .pdf(Document.PDF(id: Document.ID(rawValue: "p"), label: nil)),
      ])
  }

  @Test func keepsAnImageWhoseFileIsMissing() throws {
    let contents = makeContents(
      documents: #""i" : {"type" : "image", "label" : "", "original_file" : "i.png"}"#)

    let (documents, warnings) = try withBundle(contents: contents) { bundle in
      readDocuments(in: bundle)
    }

    guard case .image(let image) = documents.first else {
      Issue.record("Expected the image")
      return
    }
    #expect(image.file.name == "i.png")
    #expect(image.file.url.path(percentEncoded: false).hasSuffix("/files/i.png"))
    #expect(warnings == [.missingFile(name: "i.png")])
  }

  @Test func dropsAnExcerptWhoseSourceIsMissing() throws {
    let contents = makeContents(
      documents: #"""
        "i" : {
          "type" : "image", "label" : "", "original_file" : "i.png",
          "excerpt_info" : {"excerpted_id" : "gone"}
        }
        """#)

    let (documents, warnings) = try withBundle(contents: contents, files: ["i.png": ""]) { bundle in
      readDocuments(in: bundle)
    }

    guard case .image(let image) = documents.first else {
      Issue.record("Expected the image")
      return
    }
    #expect(image.excerpt == nil)
    #expect(
      warnings == [
        .missingExcerptSource(Document.ID(rawValue: "i"), sourceID: Document.ID(rawValue: "gone"))
      ])
  }

  @Test func dropsACommentWithAnInvalidDate() throws {
    let contents = makeContents(
      documents: #""c" : {"type" : "comment", "text" : "Hi", "modifiedAt" : "yesterday"}"#)

    let (documents, warnings) = try withBundle(contents: contents) { bundle in
      readDocuments(in: bundle)
    }

    #expect(documents.isEmpty)
    #expect(warnings == [.invalidCommentDate(Document.ID(rawValue: "c"), "yesterday")])
  }

  @Test func keepsACommentWithoutAKnownAuthor() throws {
    let contents = makeContents(
      documents: #"""
        "c" : {
          "type" : "comment", "text" : "Hi", "deviceId" : "phone",
          "modifiedAt" : "2026-10-28T10:45:00Z"
        }
        """#)

    let (documents, warnings) = try withBundle(contents: contents) { bundle in
      readDocuments(in: bundle)
    }

    guard case .comment(let comment) = documents.first else {
      Issue.record("Expected the comment")
      return
    }
    #expect(comment.authorID == nil)
    #expect(warnings == [.unknownCommentAuthor(Document.ID(rawValue: "c"))])
  }

  @Test func warnsAboutUnknownDocumentTypes() throws {
    let contents = makeContents(documents: #""v" : {"type" : "video"}"#)

    let (documents, warnings) = try withBundle(contents: contents) { bundle in
      readDocuments(in: bundle)
    }

    #expect(documents.isEmpty)
    #expect(warnings == [.unknownDocumentType(Document.ID(rawValue: "v"), type: "video")])
  }
}

private func kind(of document: Document) -> String {
  switch document {
  case .board: "board"
  case .note: "note"
  case .image: "image"
  case .link: "link"
  case .pdf: "pdf"
  case .comment: "comment"
  }
}
