public struct CommentThread: Equatable, Sendable {
    public let id: Chain.ID
    /// Each places a comment.
    public let cards: [Card]

    public init(id: Chain.ID, cards: [Card]) {
        self.id = id
        self.cards = cards
    }
}
