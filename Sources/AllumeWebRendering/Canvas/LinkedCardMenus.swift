import AllumeWebModels

/// Whether the document is a card on more than one board.
func isLinked(_ documentID: Document.ID, in contents: Contents) -> Bool {
  contents.hierarchy.parents(of: documentID).count > 1
}

/// A button that opens the list of the boards the document is a card on, with the current one
/// marked.
func drawLinkedCardMenu(
  for documentID: Document.ID, current currentBoardID: Document.ID?, popoverID: String,
  contents: Contents
) -> [HTML] {
  let boardIDs = contents.hierarchy.parents(of: documentID)
  let appearsIn = "Appears in \(boardIDs.count) boards"

  let items = boardIDs.map { boardID -> HTML in
    .element(
      "li", [:],
      [
        .element(
          "a",
          [
            "href": .board(boardID, card: documentID),
            "aria-current": boardID == currentBoardID ? "true" : nil,
          ], [.text(contents.board(boardID)?.displayLabel ?? "")])
      ])
  }

  return [
    .element(
      "button",
      [
        "type": "button", "class": "allume-linked", "popovertarget": .text(popoverID),
        "aria-label": .text(appearsIn),
      ], [Icon.linked.html()]),
    .element(
      "div", ["popover": .empty, "id": .text(popoverID), "class": "allume-linked-menu"],
      [.element("p", [:], [.text(appearsIn)]), .element("ul", [:], items)]),
  ]
}
