import AllumeWebModels
import Foundation

/// A root board with a card for each document.
func makeContents(with documents: [Document]) throws -> Contents {
  let cards = documents.map { document in makeCard(document.id.rawValue) }

  return try Contents(
    rootID: Document.ID(rawValue: "root"),
    documents: [
      .board(
        Document.Board(
          id: Document.ID(rawValue: "root"), label: "Languages", cards: cards, chains: [],
          connections: [], ink: []))
    ] + documents,
    users: [:]
  )
}

func makeBoard(_ id: String, label: String, cards: [String] = []) -> Document {
  .board(
    Document.Board(
      id: Document.ID(rawValue: id), label: label, cards: cards.map(makeCard), chains: [],
      connections: [], ink: []))
}

func makeCard(_ documentID: String) -> Card {
  Card(
    documentID: Document.ID(rawValue: documentID), frame: Rect(x: 0, y: 0, width: 100, height: 100),
    zIndex: 0, color: nil)
}

func makeImage(_ name: String) -> Document {
  .image(
    Document.Image(
      id: Document.ID(rawValue: name), label: nil,
      file: Asset(name: name, url: URL(filePath: "/bundle/files/\(name)")), excerpt: nil))
}

func makeLink(_ id: String, url: String) -> Document {
  .link(Document.Link(id: Document.ID(rawValue: id), url: url, title: nil, label: nil))
}
