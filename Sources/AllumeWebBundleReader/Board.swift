import AllumeWebModels
import Foundation

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

extension Document.Board {
  static func read(_ json: BundleBoard, id: Document.ID, in bundle: AllumeBundle)
    -> (board: Document.Board, warnings: [BundleWarning])
  {
    let cards = (json.cards ?? []).map { card in Card.read(card, boardID: id) }
    let chains = (json.chains ?? []).map { chain in Chain.read(chain, boardID: id, in: bundle) }
    let endpoints = connectionEndpoints(of: json)
    let connections = (json.connections ?? []).map { ends in
      Connection.read(ends, boardID: id, endpoints: endpoints)
    }
    let ink = (json.inkModels ?? [:])
      .sorted { first, second in
        (Int(first.key) ?? .max, first.key) < (Int(second.key) ?? .max, second.key)
      }
      .map { _, model in Ink.read(model, in: bundle) }

    let board = Document.Board(
      id: id, label: json.label.nonEmpty,
      cards: cards.map { result in result.card },
      chains: chains.map { result in result.chain },
      connections: connections.compactMap { result in result.connection },
      ink: ink.compactMap { result in result.ink })
    let warnings =
      cards.flatMap { result in result.warnings } + chains.flatMap { result in result.warnings }
      + connections.flatMap { result in result.warnings }
      + ink.flatMap { result in result.warnings }

    return (board, warnings)
  }

  /// What a connection's ends can name: a card on the board or in one of its threads, by its
  /// `card_id`, or a chain.
  private static func connectionEndpoints(of json: BundleBoard) -> [String: Connection.Endpoint] {
    let cards = (json.cards ?? []) + (json.chains ?? []).flatMap { chain in chain.cards ?? [] }
    let cardEndpoints = cards.compactMap { card in
      card.cardID.map { cardID in
        (cardID, Connection.Endpoint.card(Document.ID(rawValue: card.documentID)))
      }
    }
    let chainEndpoints = (json.chains ?? []).map { chain in
      (chain.chainID, Connection.Endpoint.chain(Chain.ID(rawValue: chain.chainID)))
    }

    return Dictionary(cardEndpoints + chainEndpoints, uniquingKeysWith: { first, _ in first })
  }
}

extension Card {
  /// An unknown color is left out.
  static func read(_ json: BundleCard, boardID: Document.ID) -> (
    card: Card, warnings: [BundleWarning]
  ) {
    let documentID = Document.ID(rawValue: json.documentID)
    let color = json.color.flatMap { name in CardColor(rawValue: name.lowercased()) }

    let card = Card(
      documentID: documentID,
      frame: Rect(
        x: json.positionX, y: json.positionY, width: json.sizeWidth, height: json.sizeHeight),
      zIndex: json.z, color: color)
    let warnings: [BundleWarning] =
      switch (json.color, color) {
      case (.some(let name), .none):
        [.unknownCardColor(boardID: boardID, documentID: documentID, color: name)]
      default: []
      }

    return (card, warnings)
  }
}

extension Chain {
  /// A chain with cards is a comment thread, and any other is canvas text. Ink on either is left out.
  static func read(_ json: BundleChain, boardID: Document.ID, in bundle: AllumeBundle)
    -> (chain: Chain, warnings: [BundleWarning])
  {
    let id = Chain.ID(rawValue: json.chainID)
    let inkWarnings: [BundleWarning] = (json.inkModels ?? [:]).isEmpty ? [] : [.inkOnChain(id)]

    guard let cards = json.cards else {
      let (text, warnings) = TextBlock.read(json, in: bundle)
      return (.text(text), warnings + inkWarnings)
    }

    let read = cards.map { card in Card.read(card, boardID: boardID) }
    let thread = CommentThread(id: id, cards: read.map { result in result.card })
    return (.comments(thread), read.flatMap { result in result.warnings } + inkWarnings)
  }
}

extension TextBlock {
  /// A missing text file leaves the text empty. Paragraphs are split on `\n` only, and an unknown
  /// highlight color is left out.
  static func read(_ json: BundleChain, in bundle: AllumeBundle)
    -> (text: TextBlock, warnings: [BundleWarning])
  {
    let id = Chain.ID(rawValue: json.chainID)
    let text = json.textFile.flatMap { file in bundle.text(ofFile: file) }

    let paragraphs = (text ?? "").components(separatedBy: "\n").enumerated().map {
      index, paragraph -> (paragraph: Paragraph, warnings: [BundleWarning]) in
      let name = json.format?[String(index)]?.color
      let highlight = name.flatMap { name in CardColor(rawValue: name.lowercased()) }
      let warnings: [BundleWarning] =
        switch (name, highlight) {
        case (.some(let name), .none): [.unknownHighlightColor(id, color: name)]
        default: []
        }
      return (Paragraph(text: paragraph, highlight: highlight), warnings)
    }
    let fileWarnings: [BundleWarning] =
      switch (json.textFile, text) {
      case (.some(let file), .none): [.missingFile(name: file)]
      default: []
      }

    let block = TextBlock(
      id: id, position: Point(x: json.positionX, y: json.positionY),
      lineBreakWidth: json.lineBreakWidth,
      paragraphs: paragraphs.map { result in result.paragraph })

    return (block, fileWarnings + paragraphs.flatMap { result in result.warnings })
  }
}

extension Connection {
  static func read(_ ends: [String], boardID: Document.ID, endpoints: [String: Endpoint])
    -> (connection: Connection?, warnings: [BundleWarning])
  {
    guard ends.count == 2 else {
      return (nil, [.malformedConnection(boardID: boardID)])
    }

    let unknownEnds = ends.filter { end in endpoints[end] == nil }
    guard let from = endpoints[ends[0]], let to = endpoints[ends[1]] else {
      return (nil, unknownEnds.map { end in .unknownConnectionEnd(boardID: boardID, end: end) })
    }

    return (Connection(from: from, to: to), [])
  }
}

extension Ink {
  /// The size is the SVG's `width` and `height` times its scale, a missing attribute counting as 0.
  /// A missing SVG is left out, since its size can't be read.
  static func read(_ json: BundleInkModel, in bundle: AllumeBundle)
    -> (ink: Ink?, warnings: [BundleWarning])
  {
    guard let svg = bundle.text(ofFile: json.inkSVG) else {
      return (nil, [.missingFile(name: json.inkSVG)])
    }

    let width = svg.firstMatch(of: #/<svg[^>]*\swidth="([\d.]+)"/#).flatMap { match in
      Double(match.1)
    }
    let height = svg.firstMatch(of: #/<svg[^>]*\sheight="([\d.]+)"/#).flatMap { match in
      Double(match.1)
    }
    let size = Size(width: (width ?? 0) * json.scale, height: (height ?? 0) * json.scale)

    return (Ink(file: bundle.asset(named: json.inkSVG), size: size), [])
  }
}
