extension AllumeBundle {
  enum Document: Decodable {
    case board(Board)
    case text(Text)
    case image(Image)
    case url(Link)
    case pdf(PDF)
    case comment(Comment)
    case unknown(type: String)

    init(from decoder: any Decoder) throws {
      let type = try decoder.container(keyedBy: TypeKey.self).decode(String.self, forKey: .type)
      self =
        switch type {
        case "board": .board(try Board(from: decoder))
        case "text": .text(try Text(from: decoder))
        case "image": .image(try Image(from: decoder))
        case "url": .url(try Link(from: decoder))
        case "pdf": .pdf(try PDF(from: decoder))
        case "comment": .comment(try Comment(from: decoder))
        default: .unknown(type: type)
        }
    }

    private enum TypeKey: String, CodingKey {
      case type
    }
  }

  struct Text: Decodable {
    let originalFile: String

    enum CodingKeys: String, CodingKey {
      case originalFile = "original_file"
    }
  }

  struct Image: Decodable {
    let label: String?
    let originalFile: String
    let excerptInfo: ExcerptInfo?

    enum CodingKeys: String, CodingKey {
      case label
      case originalFile = "original_file"
      case excerptInfo = "excerpt_info"
    }
  }

  struct ExcerptInfo: Decodable {
    let excerptedID: String

    enum CodingKeys: String, CodingKey {
      case excerptedID = "excerpted_id"
    }
  }

  /// Not `URL`, which is Foundation's.
  struct Link: Decodable {
    let url: String
    let title: String?
    let label: String?
  }

  struct PDF: Decodable {
    let label: String?
  }

  struct Comment: Decodable {
    let text: String
    let deviceID: String?
    let modifiedAt: String

    enum CodingKeys: String, CodingKey {
      case text
      case deviceID = "deviceId"
      case modifiedAt
    }
  }
}
