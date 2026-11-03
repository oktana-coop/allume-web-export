import AllumeWebModels

func makeBoard(_ id: String, label: String? = nil, cards documentIDs: [String] = []) -> Document {
  .board(
    Document.Board(
      id: Document.ID(rawValue: id), label: label, cards: documentIDs.map(makeCard), chains: [],
      connections: [], ink: []))
}

private func makeCard(_ documentID: String) -> Card {
  Card(
    documentID: Document.ID(rawValue: documentID), frame: Rect(x: 0, y: 0, width: 100, height: 100),
    zIndex: 0, color: nil)
}
