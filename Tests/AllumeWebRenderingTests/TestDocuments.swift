import AllumeWebModels

func makeBoard(_ id: String, label: String? = nil, cards documentIDs: [String] = []) -> Document {
  .board(
    Document.Board(
      id: Document.ID(rawValue: id), label: label,
      cards: documentIDs.map { documentID in makeCard(documentID) }, chains: [], connections: [],
      ink: []))
}

func makeCard(
  _ documentID: String, frame: Rect = Rect(x: 0, y: 0, width: 100, height: 100)
) -> Card {
  Card(documentID: Document.ID(rawValue: documentID), frame: frame, zIndex: 0, color: nil)
}
