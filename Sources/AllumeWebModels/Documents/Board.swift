extension Document {
    /// Coordinates on the board are measured from its top left.
    public struct Board: Equatable, Sendable {
        public let id: ID
        public let label: String?
        public let cards: [Card]
        public let chains: [Chain]
        public let connections: [Connection]
        public let ink: [Ink]

        public init(
            id: ID,
            label: String?,
            cards: [Card],
            chains: [Chain],
            connections: [Connection],
            ink: [Ink]
        ) {
            self.id = id
            self.label = label
            self.cards = cards
            self.chains = chains
            self.connections = connections
            self.ink = ink
        }
    }
}
