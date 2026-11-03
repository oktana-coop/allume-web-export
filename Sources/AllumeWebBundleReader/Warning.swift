import AllumeWebModels

/// Something the reader left out or worked around, which doesn't stop publishing.
package enum BundleWarning: Equatable, Sendable {
  case unknownDocumentType(Document.ID, type: String)
  /// A file the documents refer to that isn't in the bundle's `files` folder. A missing
  /// `contents.json` or `metadata.json` is an error instead.
  case missingFile(name: String)
  case missingExcerptSource(Document.ID, sourceID: Document.ID)
  case unknownCommentAuthor(Document.ID)
  case invalidCommentDate(Document.ID, String)
}
