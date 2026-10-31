extension Document {
  public struct Excerpt: Equatable, Sendable {
    public let sourceID: ID

    public init(sourceID: ID) {
      self.sourceID = sourceID
    }
  }
}
