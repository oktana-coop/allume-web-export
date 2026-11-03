import AllumeWebModels

/// A board or a file, which becomes a URL when the HTML is rendered.
enum Reference: Hashable {
  case board(Document.ID, card: Document.ID? = nil)
  case file(PublishedFile)
}
