extension Document {
    public struct Link: Equatable, Sendable {
        public let id: ID
        /// As Allume stores it, which isn't always a valid URL.
        public let url: String
        public let title: String?
        public let label: String?

        public init(id: ID, url: String, title: String?, label: String?) {
            self.id = id
            self.url = url
            self.title = title
            self.label = label
        }
    }
}
