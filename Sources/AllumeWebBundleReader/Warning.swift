import AllumeWebModels

/// Something the reader left out or worked around, which doesn't stop publishing.
package enum BundleWarning: Equatable, Sendable {
  case unknownDocumentType(Document.ID, type: String)
  /// A file the documents refer to that isn't in the bundle's `files` folder. A missing
  /// `contents.json` or `metadata.json` is an error instead.
  case missingFile(name: String)
  case missingExcerptSource(Document.ID, sourceID: Document.ID)
  case unknownCommentAuthor(Document.ID)
  case invalidUserColor(User.ID, color: String)
  case invalidCommentDate(Document.ID, String)
  case unknownCardColor(boardID: Document.ID, documentID: Document.ID, color: String)
  case unknownHighlightColor(Chain.ID, color: String)
  /// Ink drawn on canvas text or a comment thread, which the models have no place for.
  case inkOnChain(Chain.ID)
  case unknownConnectionEnd(boardID: Document.ID, end: String)
  /// A connection that doesn't have exactly two ends.
  case malformedConnection(boardID: Document.ID)
}
