extension Document {
  public struct Note: Equatable, Sendable {
    public let id: ID
    public let label: String?
    public let text: String

    public init(id: ID, label: String?, text: String) {
      self.id = id
      self.label = label
      self.text = text
    }
  }
}
