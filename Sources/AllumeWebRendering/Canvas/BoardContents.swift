import AllumeWebModels

/// What's on a board, at its depth: 0 in its own view, more inside previews. In drawing order: the
/// connection lines, the cards by z-index, the chains, the ink.
func drawBoardContents(
  _ board: Document.Board, depth: Int, contents: Contents, layouts: [Document.ID: BoardLayout],
  favicons: [String: Asset]
) -> [HTML] {
  let interactive = depth == 0
  let connectionLines = drawConnectionLines(layouts[board.id] ?? layout(of: board))
  // Cards with the same z-index keep the export's order.
  let cards = board.cards.enumerated()
    .sorted { a, b in (a.element.zIndex, a.offset) < (b.element.zIndex, b.offset) }
    .compactMap { _, card in
      drawCard(
        card, on: board, depth: depth, contents: contents, layouts: layouts, favicons: favicons)
    }
  let chains = board.chains.flatMap { chain in
    drawChain(chain, contents: contents, interactive: interactive)
  }
  let ink = board.ink.map { ink in drawInk(ink) }

  return [connectionLines].compactMap { $0 } + cards + chains + ink
}

private func drawChain(_ chain: Chain, contents: Contents, interactive: Bool) -> [HTML] {
  switch chain {
  case .text(let block):
    [drawTextBlock(block, interactive: interactive)]
  case .comments(let thread):
    thread.cards.compactMap { card in
      drawComment(card, contents: contents, interactive: interactive)
    }
  }
}
