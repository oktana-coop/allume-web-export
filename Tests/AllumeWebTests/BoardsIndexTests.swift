import AllumeWebModels
import AllumeWebRendering
import Foundation
import Testing

@testable import AllumeWeb

@Suite struct BoardsIndexTests {
  @Test func listEachPublishedBoardWithItsLabelSlugParentsAndView() throws {
    let contents = try makeContents(with: [
      makeBoard("functional", label: "Functional", cards: ["logic"]),
      makeBoard("logic", label: "Logic"),
    ])
    let slug = slugs(in: contents)

    let index = boardsIndex(for: contents)

    #expect(index.root == Document.ID(rawValue: "root"))
    #expect(
      index.boards[Document.ID(rawValue: "logic")]
        == BoardsIndex.Board(
          label: "Logic", slug: try #require(slug[Document.ID(rawValue: "logic")]),
          parents: [Document.ID(rawValue: "root"), Document.ID(rawValue: "functional")],
          view: "boards/logic.html"))
    #expect(index.boards[Document.ID(rawValue: "root")]?.parents == [])
    #expect(index.boards.count == 3)
  }

  @Test func encodeAsBoardsJSON() throws {
    let index = BoardsIndex(
      root: Document.ID(rawValue: "root"),
      boards: [
        Document.ID(rawValue: "root"): BoardsIndex.Board(
          label: "Languages", slug: "languages-abc123", parents: [], view: "boards/root.html"),
        Document.ID(rawValue: "functional"): BoardsIndex.Board(
          label: "Functional", slug: "functional-q5tbqj", parents: [Document.ID(rawValue: "root")],
          view: "boards/functional.html"),
      ])

    let json = boardsJSON(index)

    #expect(
      json == """
        {
          "boards" : {
            "functional" : {
              "label" : "Functional",
              "parents" : [
                "root"
              ],
              "slug" : "functional-q5tbqj",
              "view" : "boards/functional.html"
            },
            "root" : {
              "label" : "Languages",
              "parents" : [

              ],
              "slug" : "languages-abc123",
              "view" : "boards/root.html"
            }
          },
          "root" : "root",
          "version" : 1
        }
        """)
  }
}
