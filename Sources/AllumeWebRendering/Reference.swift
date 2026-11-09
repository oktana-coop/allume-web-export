import AllumeWebModels
import Foundation

/// What a link leads to, or what an image shows, named by what it is rather than where it is.
package enum Reference: Hashable, Sendable {
  case board(BoardReference)
  case file(FileReference)

  /// How a page holds it: `allume:board/<board-id>`, followed by `#card-<document-id>` for a card
  /// on the board, or `allume:file/<path>`. Each part is percent-encoded, so it needs no escaping
  /// in HTML.
  package var text: String {
    switch self {
    case .board(let board):
      "allume:board/\(percentEncoded(board.boardID.rawValue))"
        + (board.cardID.map { cardID in "#card-\(percentEncoded(cardID.rawValue))" } ?? "")
    case .file(let file):
      "allume:file/\(file.encodedPath)"
    }
  }

  /// The reference the text holds, or nil if it isn't one.
  package init?(text: some StringProtocol) {
    let text = String(text)
    guard
      let reference = boardReference(in: text).map(Reference.board)
        ?? fileReference(in: text).map(Reference.file)
    else {
      return nil
    }

    self = reference
  }
}

/// A board, and optionally a card on it.
package struct BoardReference: Hashable, Sendable {
  package let boardID: Document.ID
  package let cardID: Document.ID?

  package init(boardID: Document.ID, cardID: Document.ID? = nil) {
    self.boardID = boardID
    self.cardID = cardID
  }
}

/// A file, by its path under `files/`, e.g. `favicons/github.com.png`.
package struct FileReference: Hashable, Sendable {
  package let path: String

  package init(path: String) {
    self.path = path
  }

  /// Its path, with each segment percent-encoded, as it goes in a URL.
  package var encodedPath: String {
    path.split(separator: "/", omittingEmptySubsequences: false)
      .map { segment in percentEncoded(String(segment)) }
      .joined(separator: "/")
  }
}

/// The HTML with each reference in it replaced by the URL the function gives it.
package func resolvingReferences<Failure: Error>(
  in html: String, with url: (Reference) throws(Failure) -> String
) throws(Failure) -> String {
  let matches = html.matches(of: anyForm)
  let urls = try matches.map { match throws(Failure) -> String in
    guard let reference = Reference(text: match.output) else {
      return String(match.output)
    }
    return escaped(try url(reference))
  }

  // The HTML around and between the references, followed by each reference's URL.
  let gaps = zip(
    [html.startIndex] + matches.map(\.range.upperBound),
    matches.map(\.range.lowerBound) + [html.endIndex]
  ).map { start, end in html[start..<end] }
  return zip(gaps, urls + [""]).map { gap, url in gap + url }.joined()
}

private func boardReference(in text: String) -> BoardReference? {
  guard let match = text.wholeMatch(of: boardForm), let boardID = match.1.removingPercentEncoding
  else {
    return nil
  }

  guard let card = match.2 else {
    return BoardReference(boardID: Document.ID(rawValue: boardID))
  }
  return card.removingPercentEncoding.map { cardID in
    BoardReference(boardID: Document.ID(rawValue: boardID), cardID: Document.ID(rawValue: cardID))
  }
}

private func fileReference(in text: String) -> FileReference? {
  guard let match = text.wholeMatch(of: fileForm), let path = match.1.removingPercentEncoding else {
    return nil
  }

  return FileReference(path: path)
}

// Each part holds only the characters it may have once percent-encoded.
private var boardForm: Regex<(Substring, Substring, Substring?)> {
  /allume:board\/([A-Za-z0-9._~%-]+)(?:#card-([A-Za-z0-9._~%-]+))?/
}

private var fileForm: Regex<(Substring, Substring)> {
  /allume:file\/([A-Za-z0-9._~%\/-]+)/
}

private var anyForm: Regex<Substring> {
  /allume:(?:board\/[A-Za-z0-9._~%-]+(?:#card-[A-Za-z0-9._~%-]+)?|file\/[A-Za-z0-9._~%\/-]+)/
}

/// Everything but the characters URLs never need to encode, RFC 3986's unreserved ones,
/// percent-encoded, so the result is safe in a URL and in HTML alike.
private func percentEncoded(_ text: String) -> String {
  text.addingPercentEncoding(withAllowedCharacters: unreserved) ?? text
}

private let unreserved = CharacterSet(
  charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
