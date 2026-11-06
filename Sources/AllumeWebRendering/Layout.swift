import AllumeWebModels
import Foundation

struct BoardLayout: Equatable {
  /// From the top left of its nearest card or text block to the far edges of everything on it.
  let contentBounds: Rect
  /// Its connections, from edge to edge of what they join.
  let connectionLines: [Line]
}

struct Line: Equatable {
  let from: Point
  let to: Point
}

func layouts(in contents: Contents) -> [Document.ID: BoardLayout] {
  Dictionary(
    uniqueKeysWithValues: contents.hierarchy.boardIDs.compactMap { boardID in
      contents.board(boardID).map { board in (boardID, layout(of: board)) }
    })
}

func layout(of board: Document.Board) -> BoardLayout {
  BoardLayout(
    contentBounds: contentBounds(of: board), connectionLines: connectionLines(of: board))
}

/// A board's preview is scaled so that its contents, and the empty margin between the board's
/// origin and its nearest card, fit the card. It's capped at 0.8, so that it never exceeds the
/// board's actual size.
func previewScale(of contentBounds: Rect, in frame: Rect) -> Double {
  guard contentBounds.maxX > 0 && contentBounds.maxY > 0 else {
    return 0.8
  }

  return min(
    0.8, frame.width / (contentBounds.maxX + contentBounds.x),
    frame.height / (contentBounds.maxY + contentBounds.y))
}

extension TextBlock {
  var maxWidth: Double {
    lineBreakWidth ?? 600
  }
}

extension Rect {
  var maxX: Double {
    x + width
  }

  var maxY: Double {
    y + height
  }

  fileprivate var center: Point {
    Point(x: x + width / 2, y: y + height / 2)
  }
}

private func contentBounds(of board: Document.Board) -> Rect {
  let rects = board.cards.map(\.frame) + board.chains.compactMap(rect(of:))

  // Ink starts at the board's origin, so it only extends the far edges.
  let minX = rects.map(\.x).min() ?? 0
  let minY = rects.map(\.y).min() ?? 0
  let maxX = (rects.map(\.maxX) + board.ink.map(\.size.width)).max() ?? 0
  let maxY = (rects.map(\.maxY) + board.ink.map(\.size.height)).max() ?? 0

  return Rect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
}

/// Nil for a comment thread without cards, since a thread has no position of its own.
private func rect(of chain: Chain) -> Rect? {
  switch chain {
  case .text(let text): estimatedRect(of: text)
  case .comments(let thread): union(of: thread.cards.map(\.frame))
  }
}

/// Exports don't say how wide a text block is, so its width is estimated from its length.
private func estimatedRect(of text: TextBlock) -> Rect {
  let fontSize = 18.0
  let lineHeight = 24.0
  let averageCharacterWidth = fontSize * 0.55

  let naturalWidths = text.paragraphs.map { paragraph in
    Double(paragraph.text.utf16.count) * averageCharacterWidth
  }
  let width = naturalWidths.map { natural in min(natural, text.maxWidth) }.max() ?? 0
  let lines = naturalWidths.map { natural in max(1, (natural / text.maxWidth).rounded(.up)) }
    .reduce(0, +)

  return Rect(x: text.position.x, y: text.position.y, width: width, height: lines * lineHeight)
}

private func union(of rects: [Rect]) -> Rect? {
  guard let minX = rects.map(\.x).min(), let minY = rects.map(\.y).min(),
    let maxX = rects.map(\.maxX).max(), let maxY = rects.map(\.maxY).max()
  else {
    return nil
  }

  return Rect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
}

private func connectionLines(of board: Document.Board) -> [Line] {
  let rects = connectionEndRects(of: board)

  return board.connections.compactMap { connection in
    guard let from = rects[connection.from], let to = rects[connection.to] else {
      return nil
    }
    return line(between: from, and: to)
  }
}

/// The rect of everything on the board a connection can end at: its cards, its comments and its
/// chains.
private func connectionEndRects(of board: Document.Board) -> [Connection.Endpoint: Rect] {
  let threads = board.chains.compactMap { chain -> CommentThread? in
    guard case .comments(let thread) = chain else {
      return nil
    }
    return thread
  }
  let cardRects = (board.cards + threads.flatMap(\.cards)).map { card in
    (Connection.Endpoint.card(card.documentID), card.frame)
  }
  let chainRects = board.chains.compactMap { chain -> (Connection.Endpoint, Rect)? in
    rect(of: chain).map { rect in (.chain(chain.id), rect) }
  }

  return Dictionary(cardRects + chainRects, uniquingKeysWith: { first, _ in first })
}

/// Like Allume's, a line stops short of what it joins. Nil when there's no room for it.
private func line(between first: Rect, and second: Rect) -> Line? {
  let gap = 10.0

  let start = edgePoint(of: first, toward: second.center)
  let end = edgePoint(of: second, toward: first.center)
  let length = hypot(end.x - start.x, end.y - start.y)
  guard length > 2 * gap else {
    return nil
  }

  let step = Point(x: (end.x - start.x) / length * gap, y: (end.y - start.y) / length * gap)
  return Line(
    from: Point(x: start.x + step.x, y: start.y + step.y),
    to: Point(x: end.x - step.x, y: end.y - step.y))
}

/// Where the line from the rect's center toward the point leaves the rect.
private func edgePoint(of rect: Rect, toward point: Point) -> Point {
  let center = rect.center
  let dx = point.x - center.x
  let dy = point.y - center.y
  guard dx != 0 || dy != 0 else {
    return center
  }

  let scale = min(rect.width / 2 / abs(dx), rect.height / 2 / abs(dy))
  return Point(x: center.x + dx * scale, y: center.y + dy * scale)
}

extension Chain {
  fileprivate var id: Chain.ID {
    switch self {
    case .text(let text): text.id
    case .comments(let thread): thread.id
    }
  }
}
