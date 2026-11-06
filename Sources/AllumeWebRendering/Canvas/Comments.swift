import AllumeWebModels
import Foundation

/// A comment, from its card in a comment thread.
func drawComment(_ card: Card, contents: Contents, interactive: Bool) -> HTML? {
  guard case .comment(let comment)? = contents.document(card.documentID) else {
    return nil
  }

  let author = comment.authorID.flatMap { authorID in contents.users[authorID] }
  let avatar =
    author.flatMap { author in
      author.avatar.map { avatar -> HTML in
        .element(
          "img",
          [
            "class": "avatar",
            "src": .reference(.file(PublishedFile(path: avatar.name, source: avatar.url))),
            "alt": .text(author.name),
            "title": .text(author.name),
            "draggable": "false",
          ], [])
      }
    } ?? .element("span", ["class": "avatar"], [])
  // Comments are drawn above the cards and text blocks.
  let style =
    boxStyle(card.frame) + ";z-index:\(9000 + card.zIndex)"
    + (author.map { author in ";--author:\(author.color.hex)" } ?? "")
  let time = HTML.element(
    "time", ["datetime": .text(comment.modifiedAt.formatted(.iso8601))],
    [.text(comment.modifiedAt.formatted(commentDate))])

  return .element(
    "div", ["class": "comment", "style": .text(style)],
    [avatar, .element("div", ["class": "text"], [.text(comment.text)]), time]
      + (interactive ? [copyButton] : []))
}

/// In UTC, so a page doesn't depend on where it was built. The viewer replaces it with a relative
/// date.
private let commentDate = Date.VerbatimFormatStyle(
  format: "\(month: .abbreviated) \(day: .defaultDigits), \(year: .defaultDigits)",
  locale: Locale(identifier: "en_US_POSIX"), timeZone: .gmt,
  calendar: Calendar(identifier: .gregorian))

extension RGBColor {
  /// As CSS writes it, e.g. `#d8b682`.
  fileprivate var hex: String {
    "#"
      + [red, green, blue].map { component in
        (component < 16 ? "0" : "") + String(component, radix: 16)
      }.joined()
  }
}
