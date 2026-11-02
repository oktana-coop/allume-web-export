extension Document {
  /// Leaves out the PDF's file, which the export includes.
  public struct PDF: Equatable, Sendable {
    public let id: ID
    public let label: String?

    public init(id: ID, label: String?) {
      self.id = id
      self.label = label
    }
  }
}
