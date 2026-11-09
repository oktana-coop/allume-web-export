import AllumeWebModels
import Testing

@testable import AllumeWebRendering

@Suite struct ReferenceTests {
  @Suite struct TextForm {
    @Test func namesABoardByItsID() {
      let reference = Reference.board(BoardReference(boardID: Document.ID(rawValue: "functional")))

      #expect(reference.text == "allume:board/functional")
    }

    @Test func addsACardOnTheBoardAsTheHash() {
      let reference = Reference.board(
        BoardReference(
          boardID: Document.ID(rawValue: "functional"), cardID: Document.ID(rawValue: "note")))

      #expect(reference.text == "allume:board/functional#card-note")
    }

    @Test func encodesEachSegmentOfAFilesPath() {
      let reference = Reference.file(FileReference(path: "favicons/Tom & Jerry's.png"))

      #expect(reference.text == "allume:file/favicons/Tom%20%26%20Jerry%27s.png")
    }

    @Test(arguments: [
      Reference.board(BoardReference(boardID: Document.ID(rawValue: "functional"))),
      .board(
        BoardReference(
          boardID: Document.ID(rawValue: "Tom & Jerry"), cardID: Document.ID(rawValue: "#1"))),
      .file(FileReference(path: "favicons/Tom & Jerry's.png")),
    ])
    func readsBackWhatItWrites(reference: Reference) {
      #expect(Reference(text: reference.text) == reference)
    }

    @Test(arguments: [
      "allume:board/", "allume:file/", "allume:card/note", "allume:board/a b",
      "https://ocaml.org", "files/image.png",
    ])
    func readsNoReferenceFromOtherText(text: String) {
      #expect(Reference(text: text) == nil)
    }
  }

  @Suite struct Resolving {
    @Test func replacesEachReferenceWithItsURLEscaped() {
      let html =
        #"<a href="allume:board/functional#card-note"><img src="allume:file/Tom%20%26%20Jerry.png"></a>"#

      let resolved = resolvingReferences(in: html, with: describe)

      #expect(
        resolved == #"<a href="board:functional#note"><img src="file:Tom &amp; Jerry.png"></a>"#)
    }

    @Test func leavesTheRestAsItIs() {
      let html = #"<a href="https://ocaml.org">allume: a board</a>"#

      let resolved = resolvingReferences(in: html, with: describe)

      #expect(resolved == html)
    }
  }
}
