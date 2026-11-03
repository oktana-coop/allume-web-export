import AllumeWebModels
import Foundation

enum BundleDocument: Decodable {
  case board(BundleBoard)
  case text(BundleText)
  case image(BundleImage)
  case url(BundleLink)
  case pdf(BundlePDF)
  case comment(BundleComment)
  case unknown(type: String)

  init(from decoder: any Decoder) throws {
    let type = try decoder.container(keyedBy: TypeKey.self).decode(String.self, forKey: .type)
    self =
      switch type {
      case "board": .board(try BundleBoard(from: decoder))
      case "text": .text(try BundleText(from: decoder))
      case "image": .image(try BundleImage(from: decoder))
      case "url": .url(try BundleLink(from: decoder))
      case "pdf": .pdf(try BundlePDF(from: decoder))
      case "comment": .comment(try BundleComment(from: decoder))
      default: .unknown(type: type)
      }
  }

  private enum TypeKey: String, CodingKey {
    case type
  }
}

struct BundleText: Decodable {
  let originalFile: String

  enum CodingKeys: String, CodingKey {
    case originalFile = "original_file"
  }
}

struct BundleImage: Decodable {
  let label: String?
  let originalFile: String
  let excerptInfo: BundleExcerptInfo?

  enum CodingKeys: String, CodingKey {
    case label
    case originalFile = "original_file"
    case excerptInfo = "excerpt_info"
  }
}

struct BundleExcerptInfo: Decodable {
  let excerptedID: String

  enum CodingKeys: String, CodingKey {
    case excerptedID = "excerpted_id"
  }
}

struct BundleLink: Decodable {
  let url: String
  let title: String?
  let label: String?
}

struct BundlePDF: Decodable {
  let label: String?
}

struct BundleComment: Decodable {
  let text: String
  let deviceID: String?
  let modifiedAt: String

  enum CodingKeys: String, CodingKey {
    case text
    case deviceID = "deviceId"
    case modifiedAt
  }
}

/// Every document, as the models have them, in order of ID, since the export's order
/// means nothing, with what reading them left out or worked around.
func readDocuments(in bundle: AllumeBundle) -> (documents: [Document], warnings: [BundleWarning]) {
  let results = bundle.contents.documents
    .sorted { first, second in first.key < second.key }
    .map { id, json in Document.read(json, id: Document.ID(rawValue: id), in: bundle) }

  return (
    results.compactMap { result in result.document },
    results.flatMap { result in result.warnings }
  )
}

extension Document {
  /// No document for the documents the reader leaves out.
  static func read(_ json: BundleDocument, id: ID, in bundle: AllumeBundle)
    -> (document: Document?, warnings: [BundleWarning])
  {
    switch json {
    case .board(let json):
      let (board, warnings) = Board.read(json, id: id, in: bundle)
      return (.board(board), warnings)

    case .text(let json):
      let (note, warnings) = Note.read(json, id: id, in: bundle)
      return (.note(note), warnings)

    case .image(let json):
      let (image, warnings) = Image.read(json, id: id, in: bundle)
      return (.image(image), warnings)

    case .url(let json):
      return (.link(Link.read(json, id: id)), [])

    case .pdf(let json):
      return (.pdf(PDF(id: id, label: json.label.nonEmpty)), [])

    case .comment(let json):
      let (comment, warnings) = Comment.read(json, id: id, in: bundle)
      return (comment.map(Document.comment), warnings)

    case .unknown(let type):
      return (nil, [.unknownDocumentType(id, type: type)])
    }
  }
}

extension Document.Note {
  /// A missing text file leaves the note empty, as in the POC.
  static func read(_ json: BundleText, id: Document.ID, in bundle: AllumeBundle)
    -> (note: Document.Note, warnings: [BundleWarning])
  {
    let text = bundle.text(ofFile: json.originalFile)

    return (
      Document.Note(id: id, text: text ?? ""),
      text == nil ? [.missingFile(name: json.originalFile)] : []
    )
  }
}

extension Document.Image {
  /// A missing file is kept, as the POC renders the card anyway.
  static func read(_ json: BundleImage, id: Document.ID, in bundle: AllumeBundle)
    -> (image: Document.Image, warnings: [BundleWarning])
  {
    let excerpt = json.excerptInfo.map { info in
      Document.Excerpt(sourceID: Document.ID(rawValue: info.excerptedID))
    }
    let image = Document.Image(
      id: id, label: json.label.nonEmpty, file: bundle.asset(named: json.originalFile),
      excerpt: excerpt)

    let warnings: [BundleWarning] =
      bundle.hasFile(named: json.originalFile) ? [] : [.missingFile(name: json.originalFile)]

    return (image, warnings)
  }
}

extension Document.Link {
  static func read(_ json: BundleLink, id: Document.ID) -> Document.Link {
    Document.Link(id: id, url: json.url, title: json.title.nonEmpty, label: json.label.nonEmpty)
  }
}

extension Document.Comment {
  /// No comment without a valid date, since it couldn't be shown. A device that matches no user
  /// leaves the comment without an author.
  static func read(_ json: BundleComment, id: Document.ID, in bundle: AllumeBundle)
    -> (comment: Document.Comment?, warnings: [BundleWarning])
  {
    guard let modifiedAt = try? Date(json.modifiedAt, strategy: .iso8601) else {
      return (nil, [.invalidCommentDate(id, json.modifiedAt)])
    }

    let authorID = bundle.userID(ofDevice: json.deviceID).map { userID in
      User.ID(rawValue: userID)
    }
    let comment = Document.Comment(
      id: id, text: json.text, authorID: authorID, modifiedAt: modifiedAt)

    return (comment, authorID == nil ? [.unknownCommentAuthor(id)] : [])
  }
}
