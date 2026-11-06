import AllumeWeb
import AllumeWebBundleReader
import AllumeWebModels
import Foundation

// Each message says what's affected, what's wrong, and what was done about it, naming boards and
// people by their names, with their IDs after.

func warningMessage(for warning: BundleWarning, in contents: Contents) -> String {
  switch warning {
  case .unknownBundleVersion(let version):
    "The export's bundle version is \(version), but only 6 is known, so the site may be missing "
      + "things."
  case .unknownDocumentType(let documentID, let type):
    "Document \(documentID.rawValue) has an unknown type, \(type), so it's left out."
  case .missingFile(let name):
    "The export's files folder has no \(name)."
  case .unknownCommentAuthor(let commentID):
    "The author of comment \(commentID.rawValue) isn't one of the export's users, so it's shown "
      + "without one."
  case .invalidUserColor(let userID, let color):
    "The color of \(user(userID, in: contents)), \(color), isn't a hex color, so a default is used."
  case .invalidCommentDate(let commentID, let date):
    "The date of comment \(commentID.rawValue), \(date), isn't valid, so the comment is left out."
  case .unknownCardColor(let boardID, let documentID, let color):
    "The card for \(document(documentID, in: contents)) on \(board(boardID, in: contents)) has an "
      + "unknown color, \(color), so it's shown without one."
  case .unknownHighlightColor(let chainID, let color):
    "A paragraph in text block \(chainID.rawValue) has an unknown highlight color, \(color), so "
      + "it isn't highlighted."
  case .inkOnChain(let chainID):
    "The ink on text block or comment thread \(chainID.rawValue) isn't drawn."
  case .unknownConnectionEnd(let boardID, let end):
    "A connection on \(board(boardID, in: contents)) has an unknown end, \(end), so it's left out."
  case .malformedConnection(let boardID):
    "A connection on \(board(boardID, in: contents)) doesn't have two ends, so it's left out."
  case .cardForMissingDocument(let boardID, let documentID):
    "A card on \(board(boardID, in: contents)) is for document \(documentID.rawValue), which "
      + "isn't in the export, so the card is left out."
  case .cardOfWrongKind(let boardID, let documentID):
    "A card on \(board(boardID, in: contents)) is for \(document(documentID, in: contents)), "
      + "which can't be a card there, so the card is left out."
  case .repeatedCard(let boardID, let documentID):
    "There's more than one card for \(document(documentID, in: contents)) on "
      + "\(board(boardID, in: contents)), so only the first is kept."
  case .excerptWithMissingSource(let imageID):
    "Image \(imageID.rawValue) is an excerpt whose source isn't in the export, so it doesn't say "
      + "where it's from."
  case .documentOutsideRoot(let documentID):
    "Document \(documentID.rawValue) isn't inside the exported board, so it's left out."
  }
}

func warningMessage(for warning: PublishingWarning) -> String {
  switch warning {
  case .missingFile(_, let source):
    "Couldn't copy \(source.lastPathComponent), which is missing, so the site goes without it."
  case .faviconCacheUnwritable(let cache, let reason):
    "Couldn't keep favicons in \(shownPath(of: cache)), so they'll be fetched again next time. "
      + reason
  }
}

func errorMessage(for error: UnreadableBundleError) -> String {
  switch error {
  case .missingFile(let name):
    "The export folder has no \(name). Is it an Allume export?"
  case .invalidJSON(let file, let reason):
    "The export's \(file) can't be read: \(reason)"
  case .invalidContents(let error):
    errorMessage(for: error)
  }
}

func errorMessage(for error: InvalidContentsError) -> String {
  switch error {
  case .missingRoot(let rootID):
    "The export's root board, \(rootID.rawValue), isn't among its documents."
  case .rootNotABoard(let rootID):
    "The export's root, \(rootID.rawValue), isn't a board."
  case .duplicateDocument(let documentID):
    "The export has more than one document with the ID \(documentID.rawValue)."
  }
}

func errorMessage(for error: UnwritableFolderError) -> String {
  switch error {
  case .notAFolder(let url):
    "\(shownPath(of: url)) isn't a folder."
  case .notEmpty(let url):
    "\(shownPath(of: url)) has something in it. Choose an empty folder, or pass --replace to "
      + "replace its contents."
  case .pathOutsideFolder(let path):
    "The site's file \(path) would be written outside the --out folder, so nothing was written."
  case .writeFailed(let url, let reason):
    "Couldn't write \(shownPath(of: url)). \(reason) The --out folder is left as it was."
  }
}

/// `board "Reading" (309b7a21…)`, or the ID alone when the contents don't have the board.
private func board(_ boardID: Document.ID, in contents: Contents) -> String {
  contents.board(boardID).flatMap(\.label).map { label in "board \"\(label)\" (\(boardID.rawValue))"
  }
    ?? "board \(boardID.rawValue)"
}

/// The document's kind and ID, and a board's label too.
private func document(_ documentID: Document.ID, in contents: Contents) -> String {
  switch contents.document(documentID) {
  case .board?: board(documentID, in: contents)
  case .note?: "note \(documentID.rawValue)"
  case .image?: "image \(documentID.rawValue)"
  case .link?: "link \(documentID.rawValue)"
  case .pdf?: "PDF \(documentID.rawValue)"
  case .comment?: "comment \(documentID.rawValue)"
  case nil: "document \(documentID.rawValue)"
  }
}

private func user(_ userID: User.ID, in contents: Contents) -> String {
  contents.users[userID].map { user in "user \"\(user.name)\" (\(userID.rawValue))" }
    ?? "user \(userID.rawValue)"
}

/// The path with the home folder as `~`, and no slash at the end.
private func shownPath(of url: URL) -> String {
  let path = withoutFinalSlash(url.path(percentEncoded: false))
  let home = withoutFinalSlash(
    FileManager.default.homeDirectoryForCurrentUser.path(percentEncoded: false))

  return path == home || path.hasPrefix(home + "/") ? "~" + path.dropFirst(home.count) : path
}

private func withoutFinalSlash(_ path: String) -> String {
  path.count > 1 && path.hasSuffix("/") ? String(path.dropLast()) : path
}
