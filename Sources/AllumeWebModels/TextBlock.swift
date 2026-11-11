public struct TextBlock: Equatable, Sendable {
  public let id: Chain.ID
  /// The text's top left.
  public let position: Point
  public let lineBreakWidth: Double?
  public let paragraphs: [Paragraph]

  public init(id: Chain.ID, position: Point, lineBreakWidth: Double?, paragraphs: [Paragraph]) {
    self.id = id
    self.position = position
    self.lineBreakWidth = lineBreakWidth
    self.paragraphs = paragraphs
  }

  public struct Paragraph: Equatable, Sendable {
    public let text: String
    public let highlight: CardColor?
    public let role: Role

    public init(text: String, highlight: CardColor?, role: Role = .body) {
      self.text = text
      self.highlight = highlight
      self.role = role
    }

    public enum Role: Sendable {
      case body, heading
    }
  }
}
