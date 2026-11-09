import AllumeWebModels

/// Something the reader left out or worked around, which doesn't stop publishing.
package enum BundleWarning: Equatable, Sendable {
  case unknownBundleVersion(Int)
  case unknownDocumentType(Document.ID, type: String)
  /// A file the documents refer to that isn't in the bundle's `files` folder. A missing
  /// `contents.json` or `metadata.json` is an error instead.
  case missingFile(name: String)
  case unknownCommentAuthor(Document.ID)
  case invalidUserColor(User.ID, color: String)
  case invalidCommentDate(Document.ID, String)
  case unknownCardColor(boardID: Document.ID, documentID: Document.ID, color: String)
  case unknownHighlightColor(Chain.ID, color: String)
  /// Ink drawn on a text block or a comment thread, which the models have no place for.
  case inkOnChain(Chain.ID)
  case unknownConnectionEnd(boardID: Document.ID, end: String)
  /// A connection that doesn't have exactly two ends.
  case malformedConnection(boardID: Document.ID)
  /// A card whose document is gone, so it has no document ID.
  case cardWithoutDocument(boardID: Document.ID)

  // What the contents left out to stay consistent, one warning for each.
  case cardForMissingDocument(boardID: Document.ID, documentID: Document.ID)
  case cardOfWrongKind(boardID: Document.ID, documentID: Document.ID)
  case repeatedCard(boardID: Document.ID, documentID: Document.ID)
  /// An image whose excerpt was left out, since its source is missing or outside the root.
  case excerptWithMissingSource(Document.ID)
  case documentOutsideRoot(Document.ID)
}
