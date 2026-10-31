extension Document {
  public struct Image: Equatable, Sendable {
    public let id: ID
    public let label: String?
    public let file: Asset
    public let excerpt: Excerpt?

    public init(id: ID, label: String?, file: Asset, excerpt: Excerpt?) {
      self.id = id
      self.label = label
      self.file = file
      self.excerpt = excerpt
    }
  }
}
