import AllumeWebModels
import Foundation

/// A root board with a card for each document.
func makeContents(with documents: [Document]) throws -> Contents {
  let cards = documents.map { document in
    Card(
      documentID: document.id, frame: Rect(x: 0, y: 0, width: 100, height: 100), zIndex: 0,
      color: nil)
  }

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

func makeImage(_ name: String) -> Document {
  .image(
    Document.Image(
      id: Document.ID(rawValue: name), label: nil,
      file: Asset(name: name, url: URL(filePath: "/bundle/files/\(name)")), excerpt: nil))
}

func makeLink(_ id: String, url: String) -> Document {
  .link(Document.Link(id: Document.ID(rawValue: id), url: url, title: nil, label: nil))
}
