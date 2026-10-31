// Every kind is nested, as the export lists them all as documents. It also keeps
// `Image` and `Link` from clashing with SwiftUI's in files that import both.

public enum Document: Equatable, Sendable {
  case board(Board)
  case note(Note)
  case image(Image)
  case link(Link)
  case pdf(PDF)
  case comment(Comment)

  public var id: ID {
    switch self {
    case .board(let board): board.id
    case .note(let note): note.id
    case .image(let image): image.id
    case .link(let link): link.id
    case .pdf(let pdf): pdf.id
    case .comment(let comment): comment.id
    }
  }

  public struct ID: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
      self.rawValue = rawValue
    }
  }
}
