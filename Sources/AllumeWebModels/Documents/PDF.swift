extension Document {
  /// Carries no file, since PDFs are never published.
  public struct PDF: Equatable, Sendable {
    public let id: ID
    public let label: String?

    public init(id: ID, label: String?) {
      self.id = id
      self.label = label
    }
  }
}
