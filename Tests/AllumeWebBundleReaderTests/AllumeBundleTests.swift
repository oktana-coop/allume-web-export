import Foundation
import Testing

@testable import AllumeWebBundleReader

@Suite struct AllumeBundleTests {
  @Test func opensTheFixture() throws {
    let bundle = try AllumeBundle(contentsOf: fixtureURL)

    #expect(bundle.folder == fixtureURL)
    #expect(bundle.metadata.bundleVersion == 6)
    #expect(bundle.contents.documents.count == 56)
    #expect(bundle.contents.users?.count == 2)

    guard case .board(let root) = bundle.contents.documents[bundle.contents.root] else {
      Issue.record("The root isn't a board")
      return
    }
    #expect(root.label == "Languages")
  }

  @Test func decodesUnknownDocumentTypes() throws {
    let json = Data(#"{"type" : "video", "label" : "A talk"}"#.utf8)

    let document = try JSONDecoder().decode(BundleDocument.self, from: json)

    guard case .unknown(let type) = document else {
      Issue.record("Expected an unknown document")
      return
    }
    #expect(type == "video")
  }

  @Test func rejectsAMissingFile() {
    #expect(throws: UnreadableBundleError.missingFile("metadata.json")) {
      try AllumeBundle(contentsOf: URL(filePath: "/nonexistent"))
    }
  }

  @Test func rejectsInvalidJSONSayingWhere() throws {
    let contents = #"{"documents" : {"a" : {"type" : "url"}}, "root" : "a"}"#

    let error = try withBundleFolder(contents: contents) { folder in
      #expect(throws: UnreadableBundleError.self) {
        try AllumeBundle(contentsOf: folder)
      }
    }

    guard case .invalidJSON(let file, let reason) = error else {
      Issue.record("Expected invalid JSON, got \(String(describing: error))")
      return
    }
    #expect(file == "contents.json")
    #expect(reason.hasPrefix("documents.a: "))
    #expect(reason.contains("url"))
  }
}
