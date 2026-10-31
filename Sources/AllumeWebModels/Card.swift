public struct Card: Equatable, Sendable {
  public let documentID: Document.ID
  public let frame: Rect
  public let zIndex: Int
  public let color: CardColor?

  public init(documentID: Document.ID, frame: Rect, zIndex: Int, color: CardColor?) {
    self.documentID = documentID
    self.frame = frame
    self.zIndex = zIndex
    self.color = color
  }
}

public enum CardColor: String, CaseIterable, Sendable {
  case purple, red, green, yellow, blue, gray
}
