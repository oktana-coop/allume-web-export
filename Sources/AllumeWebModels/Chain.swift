public enum Chain: Equatable, Sendable {
  case text(TextBlock)
  case comments(CommentThread)

  public struct ID: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
      self.rawValue = rawValue
    }
  }
}
