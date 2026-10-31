/// An SVG whose origin is the board's origin.
public struct Ink: Equatable, Sendable {
    public let file: Asset
    public let size: Size

    public init(file: Asset, size: Size) {
        self.file = file
        self.size = size
    }
}
