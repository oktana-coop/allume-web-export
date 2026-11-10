import AllumeWebModels
import Testing

@Suite struct HierarchyTests {
  @Suite struct BoardIDs {
    @Test func followLevelsThenTheOrderOfCards() throws {
      let contents = try Contents(
        rootID: Document.ID(rawValue: "root"),
        documents: [
          makeBoard("root", cards: ["q", "note", "p"]),
          makeBoard("p", cards: ["x"]),
          makeBoard("q", cards: ["y"]),
          makeBoard("x"),
          makeBoard("y"),
          makeNote("note"),
        ],
        users: [:]
      )

      let boardIDs = contents.hierarchy.boardIDs

      #expect(boardIDs.map(\.rawValue) == ["root", "q", "p", "y", "x"])
    }

    @Test func listEachBoardOnce() throws {
      let contents = try Contents(
        rootID: Document.ID(rawValue: "root"),
        documents: [
          makeBoard("root", cards: ["a", "b"]),
          makeBoard("a", cards: ["b", "root"]),
          makeBoard("b", cards: ["a"]),
        ],
        users: [:]
      )

      let boardIDs = contents.hierarchy.boardIDs

      #expect(boardIDs.map(\.rawValue) == ["root", "a", "b"])
    }
  }

  @Suite struct Parents {
    @Test func followBreadthFirstOrder() throws {
      let contents = try Contents(
        rootID: Document.ID(rawValue: "root"),
        documents: [
          makeNote("note"),
          makeBoard("far", cards: ["note"]),
          makeBoard("middle", cards: ["far"]),
          makeBoard("near", cards: ["note"]),
          makeBoard("root", cards: ["middle", "near"]),
        ],
        users: [:]
      )

      let parents = contents.hierarchy.parents(of: Document.ID(rawValue: "note"))

      #expect(parents.map(\.rawValue) == ["near", "far"])
    }

    @Test func includeTheBoardOfAComment() throws {
      let contents = try Contents(
        rootID: Document.ID(rawValue: "root"),
        documents: [makeBoard("root", commentThread: ["comment"]), makeComment("comment")],
        users: [:]
      )

      let parents = contents.hierarchy.parents(of: Document.ID(rawValue: "comment"))

      #expect(parents.map(\.rawValue) == ["root"])
    }

    @Test func listEachBoardOnce() throws {
      let contents = try Contents(
        rootID: Document.ID(rawValue: "root"),
        documents: [makeBoard("root", cards: ["note", "note"]), makeNote("note")],
        users: [:]
      )

      let parents = contents.hierarchy.parents(of: Document.ID(rawValue: "note"))

      #expect(parents.map(\.rawValue) == ["root"])
    }
  }

  @Suite struct PrimaryAncestors {
    @Test func goThroughTheClosestParent() throws {
      let contents = try Contents(
        rootID: Document.ID(rawValue: "root"),
        documents: [
          makeBoard("root", cards: ["paradigms", "languages"]),
          makeBoard("paradigms", cards: ["functional"]),
          makeBoard("functional", cards: ["haskell"]),
          makeBoard("languages", cards: ["haskell"]),
          makeBoard("haskell"),
        ],
        users: [:]
      )

      let ancestors = contents.hierarchy.primaryAncestors(of: Document.ID(rawValue: "haskell"))

      #expect(ancestors.map(\.rawValue) == ["root", "languages"])
    }

    @Test func carryDownToDescendants() throws {
      let contents = try Contents(
        rootID: Document.ID(rawValue: "root"),
        documents: [
          makeBoard("root", cards: ["paradigms", "languages"]),
          makeBoard("paradigms", cards: ["functional"]),
          makeBoard("functional", cards: ["haskell"]),
          makeBoard("languages", cards: ["haskell"]),
          makeBoard("haskell", cards: ["monads"]),
          makeBoard("monads"),
        ],
        users: [:]
      )

      let ancestors = contents.hierarchy.primaryAncestors(of: Document.ID(rawValue: "monads"))

      #expect(ancestors.map(\.rawValue) == ["root", "languages", "haskell"])
    }

    @Test func settleTiesByTheOrderOfCards() throws {
      let contents = try Contents(
        rootID: Document.ID(rawValue: "root"),
        documents: [
          makeBoard("root", cards: ["b", "a"]),
          makeBoard("a", cards: ["c"]),
          makeBoard("b", cards: ["c"]),
          makeBoard("c"),
        ],
        users: [:]
      )

      let ancestors = contents.hierarchy.primaryAncestors(of: Document.ID(rawValue: "c"))

      #expect(ancestors.map(\.rawValue) == ["root", "b"])
    }

    @Test func settleTiesFurtherDownByBreadthFirstOrder() throws {
      let contents = try Contents(
        rootID: Document.ID(rawValue: "root"),
        documents: [
          makeBoard("root", cards: ["p", "q"]),
          makeBoard("q", cards: ["y"]),
          makeBoard("y", cards: ["z"]),
          makeBoard("p", cards: ["x"]),
          makeBoard("x", cards: ["z"]),
          makeBoard("z"),
        ],
        users: [:]
      )

      let ancestors = contents.hierarchy.primaryAncestors(of: Document.ID(rawValue: "z"))

      #expect(ancestors.map(\.rawValue) == ["root", "p", "x"])
    }

    @Test func ignoreCycles() throws {
      let contents = try Contents(
        rootID: Document.ID(rawValue: "root"),
        documents: [
          makeBoard("root", cards: ["a"]),
          makeBoard("a", cards: ["b", "root"]),
          makeBoard("b", cards: ["a"]),
        ],
        users: [:]
      )

      let hierarchy = contents.hierarchy

      #expect(hierarchy.primaryAncestors(of: Document.ID(rawValue: "root")).isEmpty)
      #expect(
        hierarchy.primaryAncestors(of: Document.ID(rawValue: "a")).map(\.rawValue) == ["root"])
      #expect(
        hierarchy.primaryAncestors(of: Document.ID(rawValue: "b")).map(\.rawValue) == ["root", "a"])
    }

    @Test func areEmptyForOtherDocumentsAndUnknownIDs() throws {
      let contents = try Contents(
        rootID: Document.ID(rawValue: "root"),
        documents: [makeBoard("root", cards: ["note"]), makeNote("note")],
        users: [:]
      )
      #expect(contents.hierarchy.primaryAncestors(of: Document.ID(rawValue: "note")).isEmpty)
      #expect(contents.hierarchy.primaryAncestors(of: Document.ID(rawValue: "missing")).isEmpty)
    }
  }

  @Suite struct NestingLevels {
    @Test func countTheLevelsOfBoardsABoardHolds() throws {
      let contents = try Contents(
        rootID: Document.ID(rawValue: "root"),
        documents: [
          makeBoard("root", cards: ["a", "b"]), makeBoard("a", cards: ["c"]), makeBoard("b"),
          makeBoard("c", cards: ["note"]), makeNote("note"),
        ],
        users: [:]
      )

      let levels = ["root", "a", "b", "c"].map { id in
        contents.hierarchy.nestingLevel(of: Document.ID(rawValue: id))
      }

      // The root holds a, which holds c: the highest of its boards' levels, plus one.
      #expect(levels == [2, 1, 0, 0])
    }

    @Test func countACycleOfLinkedBoardsUpToWhereItCloses() throws {
      let contents = try Contents(
        rootID: Document.ID(rawValue: "root"),
        documents: [
          makeBoard("root", cards: ["a"]), makeBoard("a", cards: ["b"]),
          makeBoard("b", cards: ["a"]),
        ],
        users: [:]
      )

      let levels = ["root", "a", "b"].map { id in
        contents.hierarchy.nestingLevel(of: Document.ID(rawValue: id))
      }

      #expect(levels == [2, 1, 1])
    }

    @Test func areZeroForOtherDocumentsAndUnknownIDs() throws {
      let contents = try Contents(
        rootID: Document.ID(rawValue: "root"),
        documents: [makeBoard("root", cards: ["note"]), makeNote("note")],
        users: [:]
      )

      #expect(contents.hierarchy.nestingLevel(of: Document.ID(rawValue: "note")) == 0)
      #expect(contents.hierarchy.nestingLevel(of: Document.ID(rawValue: "unknown")) == 0)
    }
  }
}
