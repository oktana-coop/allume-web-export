import AllumeWebModels
import Foundation

func makeBoard(
  _ id: String,
  cards documentIDs: [String] = [],
  commentThread commentIDs: [String] = [],
  connections cardPairs: [(String, String)] = []
) -> Document {
  let thread = CommentThread(
    id: Chain.ID(rawValue: "\(id) thread"), cards: commentIDs.map(makeCard))
  let connections = cardPairs.map { from, to in
    Connection(
      from: .card(Document.ID(rawValue: from)), to: .card(Document.ID(rawValue: to)))
  }
  return .board(
    Document.Board(
      id: Document.ID(rawValue: id), label: nil, cards: documentIDs.map(makeCard),
      chains: commentIDs.isEmpty ? [] : [.comments(thread)], connections: connections, ink: []))
}

func makeNote(_ id: String) -> Document {
  .note(Document.Note(id: Document.ID(rawValue: id), label: nil, text: "A note"))
}

func makeImage(_ id: String, excerptOf sourceID: String? = nil) -> Document {
  .image(
    Document.Image(
      id: Document.ID(rawValue: id), label: nil,
      file: Asset(name: "\(id).png", url: URL(filePath: "/\(id).png")),
      excerpt: sourceID.map { sourceID in
        Document.Excerpt(sourceID: Document.ID(rawValue: sourceID))
      }
    ))
}

func makeComment(_ id: String) -> Document {
  .comment(
    Document.Comment(
      id: Document.ID(rawValue: id), text: "A comment", authorID: nil,
      modifiedAt: Date(timeIntervalSince1970: 0)))
}

private func makeCard(_ documentID: String) -> Card {
  Card(
    documentID: Document.ID(rawValue: documentID), frame: Rect(x: 0, y: 0, width: 100, height: 100),
    zIndex: 0, color: nil)
}
