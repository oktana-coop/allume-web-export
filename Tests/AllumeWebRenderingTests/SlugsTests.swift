import AllumeWebModels
import Testing

@testable import AllumeWebRendering

@Suite struct SlugsTests {
  @Suite struct Slugs {
    @Test func addACodeHashedFromTheIDToTheLabel() throws {
      let contents = try Contents(
        rootID: Document.ID(rawValue: "32beee7c9e676744176571f8879140b8"),
        documents: [
          makeBoard(
            "32beee7c9e676744176571f8879140b8", label: "Functor",
            cards: ["34ff0710fb72a3f59dc37110124986f5"]),
          makeBoard("34ff0710fb72a3f59dc37110124986f5", label: "Notes"),
        ],
        users: [:]
      )

      let slugs = slugs(in: contents)

      #expect(slugs[Document.ID(rawValue: "32beee7c9e676744176571f8879140b8")] == "functor-f574b1")
      #expect(slugs[Document.ID(rawValue: "34ff0710fb72a3f59dc37110124986f5")] == "notes-qy9hju")
    }

    @Test func keepBoardsWithTheSameLabelApart() throws {
      let contents = try Contents(
        rootID: Document.ID(rawValue: "32beee7c9e676744176571f8879140b8"),
        documents: [
          makeBoard(
            "32beee7c9e676744176571f8879140b8", label: "Notes",
            cards: ["34ff0710fb72a3f59dc37110124986f5"]),
          makeBoard("34ff0710fb72a3f59dc37110124986f5", label: "Notes"),
        ],
        users: [:]
      )

      let slugs = slugs(in: contents)

      #expect(slugs[Document.ID(rawValue: "32beee7c9e676744176571f8879140b8")] == "notes-f574b1")
      #expect(slugs[Document.ID(rawValue: "34ff0710fb72a3f59dc37110124986f5")] == "notes-qy9hju")
    }

    @Test func fallBackToUntitledBoard() throws {
      let contents = try Contents(
        rootID: Document.ID(rawValue: "32beee7c9e676744176571f8879140b8"),
        documents: [makeBoard("32beee7c9e676744176571f8879140b8")],
        users: [:]
      )

      let slugs = slugs(in: contents)

      #expect(
        slugs[Document.ID(rawValue: "32beee7c9e676744176571f8879140b8")]
          == "untitled-board-f574b1")
    }

    @Test func useTheWholeIDWhenTwoBoardsWouldShareASlug() throws {
      // Both IDs hash to the code `rtxqkv`.
      let contents = try Contents(
        rootID: Document.ID(rawValue: "root"),
        documents: [
          makeBoard("root", cards: ["board-10208", "board-27339"]),
          makeBoard("board-10208", label: "Notes"),
          makeBoard("board-27339", label: "Notes"),
        ],
        users: [:]
      )

      let slugs = slugs(in: contents)

      #expect(slugs[Document.ID(rawValue: "board-10208")] == "notes-board-10208")
      #expect(slugs[Document.ID(rawValue: "board-27339")] == "notes-board-27339")
    }
  }

  @Suite struct Slugify {
    @Test func keepsLowercaseLettersAndDigits() {
      #expect(slugify("Functional Programming 101") == "functional-programming-101")
    }

    @Test func dropsAccentsAndSplitsLigatures() {
      #expect(slugify("Café ﬁnale") == "cafe-finale")
    }

    @Test func joinsRunsOfOtherCharactersWithOneDash() {
      #expect(slugify("  Monads, Functors & Co.  ") == "monads-functors-co")
    }

    @Test func cutsTo60CharactersWithoutATrailingDash() {
      let word = String(repeating: "a", count: 59)

      let slug = slugify("\(word) bcd")

      #expect(slug == word)
    }

    @Test func cutsWithinAWord() {
      let slug = slugify(String(repeating: "abcdef ", count: 10))

      #expect(slug.count == 60)
      #expect(slug.hasSuffix("-abcd"))
    }

    @Test func fallsBackToBoardWhenNothingIsLeft() {
      #expect(slugify("") == "board")
      #expect(slugify("!!!") == "board")
      #expect(slugify("日本語") == "board")
    }
  }
}
