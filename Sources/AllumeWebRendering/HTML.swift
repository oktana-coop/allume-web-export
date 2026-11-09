import AllumeWebModels

enum HTML {
  case doctype
  /// Rendered as is, so it mustn't contain `-->`.
  case comment(String)
  /// Escaped when rendered.
  case text(String)
  /// An attribute whose value is nil is left out.
  case element(String, KeyValuePairs<String, AttributeValue?>, [HTML])

  func rendered(resolving url: (Reference) -> String) -> String {
    switch self {
    case .doctype:
      return "<!doctype html>"

    case .comment(let text):
      return "<!-- \(text) -->"

    case .text(let text):
      return escaped(text)

    case .element(let name, let attributes, let children):
      let start =
        "<\(name)"
        + attributes.map { name, value in attribute(name, value, resolving: url) }.joined()
      if voidElements.contains(name) {
        return start + ">"
      }
      if svgElements.contains(name) && children.isEmpty {
        return start + "/>"
      }

      return start + ">" + children.map { child in child.rendered(resolving: url) }.joined()
        + "</\(name)>"
    }
  }

  /// The files its attributes refer to, in order, repeats included.
  var files: [PublishedFile] {
    guard case .element(_, let attributes, let children) = self else {
      return []
    }

    let own = attributes.compactMap { _, value -> PublishedFile? in
      guard case .file(let file)? = value else {
        return nil
      }
      return file
    }
    return own + children.flatMap { child in child.files }
  }
}

enum AttributeValue: ExpressibleByStringInterpolation {
  /// Escaped when rendered.
  case text(String)
  /// Written as a reference to the board, or to a card on it.
  case board(Document.ID, card: Document.ID? = nil)
  /// Written as a reference to the file, which is then published.
  case file(PublishedFile)
  /// Rendered as the attribute's name alone, like `popover`.
  case empty

  init(stringLiteral text: String) {
    self = .text(text)
  }
}

/// The nodes with a line break between each, `A\nB\nC`, so that the source shows them, and diffs
/// them, one per line.
func separatedByLineBreaks(_ nodes: [HTML]) -> [HTML] {
  Array(nodes.map { node in [node] }.joined(separator: [.text("\n")]))
}

/// The nodes each on a line of its own inside their parent: `\nA\nB\nC\n`.
func onLinesOfTheirOwn(_ nodes: [HTML]) -> [HTML] {
  [.text("\n")] + separatedByLineBreaks(nodes) + [.text("\n")]
}

/// HTML elements with no end tag, rendered as `<img …>`.
private let voidElements: Set = [
  "area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "source", "track",
  "wbr",
]

/// SVG elements, rendered as `<use …/>` when they have no children. Only those in use are listed.
private let svgElements: Set = ["line", "path", "svg", "symbol", "use"]

private func attribute(
  _ name: String, _ value: AttributeValue?, resolving url: (Reference) -> String
) -> String {
  switch value {
  case nil:
    ""
  case .empty?:
    " \(name)"
  case .text(let text)?:
    " \(name)=\"\(escaped(text))\""
  case .board(let boardID, let cardID)?:
    " \(name)=\"\(escaped(url(.board(BoardReference(boardID: boardID, cardID: cardID)))))\""
  case .file(let file)?:
    " \(name)=\"\(escaped(url(.file(FileReference(path: file.path)))))\""
  }
}

func escaped(_ text: String) -> String {
  text.unicodeScalars.map { scalar in
    switch scalar {
    case "&": "&amp;"
    case "<": "&lt;"
    case ">": "&gt;"
    case "\"": "&quot;"
    case "'": "&#39;"
    default: String(scalar)
    }
  }.joined()
}
