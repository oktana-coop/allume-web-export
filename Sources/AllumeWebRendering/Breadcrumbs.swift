import AllumeWebModels

func drawBreadcrumbs(of board: Document.Board, contents: Contents) -> HTML {
  let ancestorIDs = contents.hierarchy.primaryAncestors(of: board.id)
  let ancestors = ancestorIDs.flatMap { ancestorID -> [HTML] in
    [
      .element(
        "a",
        [
          "href": .board(ancestorID),
          "rel": ancestorID == ancestorIDs.last ? "up" : nil,
        ], [.text(contents.board(ancestorID)?.displayLabel ?? "")]),
      .element("span", ["class": "allume-separator", "aria-hidden": "true"], [.text("/")]),
    ]
  }
  let menu =
    isLinked(board.id, in: contents)
    ? drawLinkedCardMenu(
      for: board.id, current: ancestorIDs.last, popoverID: "allume-linked-self", contents: contents)
    : []
  let heading = HTML.element(
    "h1", [:], menu + [.element("span", [:], [.text(board.displayLabel)])])

  return .element(
    "nav", ["class": "allume-breadcrumbs", "aria-label": "Breadcrumbs"], ancestors + [heading])
}
