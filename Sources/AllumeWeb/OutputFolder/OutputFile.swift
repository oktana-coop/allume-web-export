import Foundation

/// A file of an output: of a published site, or of the folder a site embeds board views from.
public struct OutputFile: Equatable, Sendable {
  /// From the folder, e.g. `index.html` or `files/user_6e359fff.png`.
  public let path: String
  public let source: Source

  public enum Source: Equatable, Sendable {
    case text(String)
    /// A file whose bytes are copied as they are.
    case copy(URL)
    /// Bytes made while publishing, such as an image.
    case data(Data)
  }
}
