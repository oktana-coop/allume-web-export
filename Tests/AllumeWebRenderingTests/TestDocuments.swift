import AllumeWebModels
import Foundation

@testable import AllumeWebRendering

func makeBoard(
  _ id: String, label: String? = nil, cards documentIDs: [String] = [],
  comments commentIDs: [String] = []
) -> Document {
  let thread = CommentThread(
    id: Chain.ID(rawValue: "\(id) thread"),
    cards: commentIDs.map { commentID in makeCard(commentID) })

  return .board(
    Document.Board(
      id: Document.ID(rawValue: id), label: label,
      cards: documentIDs.map { documentID in makeCard(documentID) },
      chains: commentIDs.isEmpty ? [] : [.comments(thread)], connections: [], ink: []))
}

func makeCard(
  _ documentID: String, frame: Rect = Rect(x: 0, y: 0, width: 100, height: 100),
  zIndex: Int = 0, color: CardColor? = nil
) -> Card {
  Card(documentID: Document.ID(rawValue: documentID), frame: frame, zIndex: zIndex, color: color)
}

func makeNote(_ id: String, label: String? = nil, text: String = "A note") -> Document {
  .note(Document.Note(id: Document.ID(rawValue: id), label: label, text: text))
}

func makeImage(_ id: String, label: String? = nil, excerptOf sourceID: String? = nil) -> Document {
  .image(
    Document.Image(
      id: Document.ID(rawValue: id), label: label, file: makeAsset("\(id).png"),
      excerpt: sourceID.map { sourceID in
        Document.Excerpt(sourceID: Document.ID(rawValue: sourceID))
      }))
}

func makeLink(_ id: String, url: String, title: String? = nil, label: String? = nil) -> Document {
  .link(Document.Link(id: Document.ID(rawValue: id), url: url, title: title, label: label))
}

func makePDF(_ id: String, label: String? = nil) -> Document {
  .pdf(Document.PDF(id: Document.ID(rawValue: id), label: label))
}

func makeComment(_ id: String, text: String = "A comment", author authorID: String? = nil)
  -> Document
{
  .comment(
    Document.Comment(
      id: Document.ID(rawValue: id), text: text,
      authorID: authorID.map { authorID in User.ID(rawValue: authorID) },
      modifiedAt: Date(timeIntervalSince1970: 1_730_452_304)))
}

func makeAsset(_ name: String) -> Asset {
  Asset(name: name, url: URL(filePath: "/bundle/files/\(name)"))
}

/// What the renderer draws for the card of the document on the board, with references described.
func drawn(
  _ documentID: String, on boardID: String, in contents: Contents, depth: Int = 0,
  favicons: [String: Asset] = [:], images: [String: ImageFiles] = [:],
  previews: [CardPreview: PreviewImageFiles] = [:]
) -> String? {
  let board = contents.board(Document.ID(rawValue: boardID))
  let card = board?.cards.first { card in card.documentID.rawValue == documentID }

  return board.flatMap { board in
    card.flatMap { card in
      drawCard(
        card, on: board, depth: depth, contents: contents, favicons: favicons, images: images,
        previews: previews
      )?
      .rendered(resolving: describe)
    }
  }
}

/// What the renderer draws for the board's contents, piece by piece, with references described.
func drawnContents(of boardID: String, in contents: Contents, depth: Int = 0) -> [String]? {
  contents.board(Document.ID(rawValue: boardID)).map { board in
    drawBoardContents(
      board, depth: depth, contents: contents, layouts: layouts(in: contents), favicons: [:],
      images: [:], previews: [:]
    )
    .map { piece in piece.rendered(resolving: describe) }
  }
}
