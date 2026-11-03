/// The export leaves out empty arrays, so every array here is optional.
struct BundleBoard: Decodable {
  let label: String?
  let cards: [BundleCard]?
  let chains: [BundleChain]?
  let connections: [[String]]?
  let inkModels: [String: BundleInkModel]?

  enum CodingKeys: String, CodingKey {
    case label
    case cards
    case chains
    case connections
    case inkModels = "ink_models"
  }
}

struct BundleCard: Decodable {
  let cardID: String?
  let documentID: String
  let positionX: Double
  let positionY: Double
  let sizeWidth: Double
  let sizeHeight: Double
  let z: Int
  let color: String?

  enum CodingKeys: String, CodingKey {
    case cardID = "card_id"
    case documentID = "document_id"
    case positionX = "position_x"
    case positionY = "position_y"
    case sizeWidth = "size_width"
    case sizeHeight = "size_height"
    case z
    case color
  }
}

struct BundleChain: Decodable {
  let chainID: String
  let positionX: Double
  let positionY: Double
  let cards: [BundleCard]?
  let textFile: String?
  let lineBreakWidth: Double?
  let format: [String: BundleFormat]?
  let inkModels: [String: BundleInkModel]?

  enum CodingKeys: String, CodingKey {
    case chainID = "chain_id"
    case positionX = "position_x"
    case positionY = "position_y"
    case cards
    case textFile = "text_file"
    case lineBreakWidth = "line_break_width"
    case format
    case inkModels = "ink_models"
  }
}

struct BundleFormat: Decodable {
  let color: String?
}

struct BundleInkModel: Decodable {
  let inkSVG: String
  let scale: Double

  enum CodingKeys: String, CodingKey {
    case inkSVG = "ink_svg"
    case scale
  }
}
