public struct Connection: Equatable, Sendable {
  public let from: Endpoint
  public let to: Endpoint

  public init(from: Endpoint, to: Endpoint) {
    self.from = from
    self.to = to
  }

  public enum Endpoint: Hashable, Sendable {
    /// The card placing this document, on the board or in one of its comment threads.
    case card(Document.ID)
    case chain(Chain.ID)
  }
}
