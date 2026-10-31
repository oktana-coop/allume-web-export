extension Document {
    public struct Note: Equatable, Sendable {
        public let id: ID
        public let text: String

        public init(id: ID, text: String) {
            self.id = id
            self.text = text
        }
    }
}
