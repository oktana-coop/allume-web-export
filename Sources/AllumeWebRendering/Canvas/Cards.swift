import AllumeWebModels
import Foundation

/// A card on the board, at the board's depth: 0 on the board's own page, more inside previews,
/// which leave out whatever can be clicked.
func drawCard(
  _ card: Card, on board: Document.Board, depth: Int, contents: Contents,
  layouts: [Document.ID: BoardLayout], favicons: [String: Asset],
  thumbnails: [String: Asset]
) -> HTML? {
  let interactive = depth == 0
  let menu =
    interactive && isLinked(card.documentID, in: contents)
    ? drawLinkedCardMenu(
      for: card.documentID, current: board.id,
      popoverID: "allume-linked-\(card.documentID.rawValue)",
      contents: contents)
    : []

  switch contents.document(card.documentID) {
  case .board(let child)?:
    let preview = drawPreview(
      of: child, in: card.frame, depth: depth + 1, contents: contents, layouts: layouts,
      favicons: favicons, thumbnails: thumbnails)
    return drawBoardCard(
      card, showing: child, preview: preview, menu: menu, interactive: interactive,
      contents: contents)

  case .note(let note)?:
    let body = HTML.element("div", ["class": "allume-body"], [.text(note.text)])
    return cardElement(
      card, kind: "note", style: boxStyle(card.frame), interactive: interactive,
      children: [body] + (interactive ? [copyButton] : []) + menu)

  case .image(let image)?:
    return cardElement(
      card, kind: "image", style: boxStyle(card.frame), interactive: interactive,
      children: [
        drawImage(
          image, thumbnail: interactive ? nil : thumbnails[image.file.name], contents: contents)
      ] + menu)

  case .link(let link)?:
    return cardElement(
      card, kind: "link", style: boxStyle(card.frame), interactive: interactive,
      children: [drawLink(link, favicons: favicons, interactive: interactive)] + menu)

  case .pdf(let pdf)?:
    return cardElement(
      card, kind: "pdf", style: pdfStyle(card.frame), interactive: interactive,
      children: [drawPDF(pdf)] + menu)

  case .comment?, nil:
    return nil
  }
}

func boxStyle(_ frame: Rect) -> String {
  "left:\(number: frame.x)px;top:\(number: frame.y)px;width:\(number: frame.width)px;"
    + "height:\(number: frame.height)px"
}

var copyButton: HTML {
  .element(
    "button", ["type": "button", "class": "allume-copy", "aria-label": "Copy text"],
    [Icon.copy.html(class: "allume-icon-copy"), Icon.copied.html(class: "allume-icon-copied")])
}

/// The host whose favicon a link shows, lowercased. Nil when the link isn't a web address.
package func faviconHost(of url: String) -> String? {
  guard let parsed = URL(string: url), ["http", "https"].contains(parsed.scheme?.lowercased()),
    let host = parsed.host(), !host.isEmpty
  else {
    return nil
  }

  return host.lowercased()
}

private func cardElement(
  _ card: Card, kind: String, style: String, interactive: Bool, children: [HTML]
) -> HTML {
  .element(
    "div",
    [
      "class": "allume-card allume-\(kind)-card",
      "data-allume-doc": .text(card.documentID.rawValue),
      "id": interactive ? .text("card-\(card.documentID.rawValue)") : nil,
      "data-allume-color": card.color.map { color in .text(color.rawValue) },
      "style": .text("\(style);z-index:\(card.zIndex)"),
    ],
    children)
}

private func drawBoardCard(
  _ card: Card, showing child: Document.Board, preview: HTML?, menu: [HTML], interactive: Bool,
  contents: Contents
) -> HTML {
  let title = HTML.element(
    "div", ["class": "allume-board-title"],
    linkedIcon(of: child, menu: menu, contents: contents)
      + [.element("span", [:], [.text(child.displayLabel)])])
  let panelContents = preview.map { preview in [preview] } ?? []
  let panel: HTML =
    interactive
    ? .element(
      "a",
      [
        "class": "allume-body allume-panel", "href": .board(child.id),
        "aria-label": .text(child.displayLabel),
      ], panelContents)
    : .element("div", ["class": "allume-body allume-panel"], panelContents)

  return cardElement(
    card, kind: "board", style: boxStyle(card.frame), interactive: interactive,
    children: [title, panel])
}

/// The menu of the boards a linked board is a card on, or only its icon in a preview, which has no
/// menu.
private func linkedIcon(of board: Document.Board, menu: [HTML], contents: Contents) -> [HTML] {
  guard isLinked(board.id, in: contents) else {
    return []
  }

  if menu.isEmpty {
    return [.element("span", ["class": "allume-linked"], [Icon.linked.html()])]
  }
  return menu
}

/// The image, or its thumbnail, which previews show instead when there's one.
private func drawImage(_ image: Document.Image, thumbnail: Asset?, contents: Contents) -> HTML {
  let sourceLabel = image.excerpt.flatMap { excerpt in label(of: excerpt.sourceID, in: contents) }
  let file =
    thumbnail.map { thumbnail in
      PublishedFile(path: "thumbs/\(thumbnail.name)", source: thumbnail.url)
    }
    ?? PublishedFile(path: image.file.name, source: image.file.url)

  return .element(
    "img",
    [
      "class": "allume-body",
      "src": .file(file),
      "alt": .text(image.label ?? ""),
      "title": sourceLabel.map { label in .text("From \(label)") },
      "loading": "lazy",
      "decoding": "async",
      "draggable": "false",
    ], [])
}

private func drawLink(_ link: Document.Link, favicons: [String: Asset], interactive: Bool) -> HTML {
  let favicon = faviconHost(of: link.url).flatMap { host in favicons[host] }
  let logo =
    favicon.map { favicon -> HTML in
      .element(
        "img",
        [
          "class": "allume-favicon",
          "src": .file(PublishedFile(path: "favicons/\(favicon.name)", source: favicon.url)),
          "alt": "",
          "loading": "lazy",
          "draggable": "false",
        ], [])
    } ?? Icon.url.html()
  let content = [
    logo,
    .element("span", ["class": "allume-title"], [.text(link.title ?? link.label ?? link.url)]),
    .element("span", ["class": "allume-host"], [.text(shownHost(of: link.url))]),
  ]

  return interactive
    ? .element(
      "a",
      ["class": "allume-body", "href": .text(link.url), "target": "_blank", "rel": "noopener"],
      content)
    : .element("div", ["class": "allume-body"], content)
}

/// PDFs aren't published, so their cards show only the title.
private func drawPDF(_ pdf: Document.PDF) -> HTML {
  .element(
    "div", ["class": "allume-body", "title": .text(pdf.label ?? "")],
    [
      Icon.pdf.html(),
      .element("span", ["class": "allume-title"], [.text(pdf.label ?? "PDF")]),
      .element("span", ["class": "allume-host"], [.text("PDF")]),
    ])
}

private func label(of documentID: Document.ID, in contents: Contents) -> String? {
  switch contents.document(documentID) {
  case .board(let board)?: board.label
  case .image(let image)?: image.label
  case .link(let link)?: link.label
  case .pdf(let pdf)?: pdf.label
  case .note?, .comment?, nil: nil
  }
}

/// A PDF card is a tile with the title, as wide as the card up to 320, and as high as its text.
private func pdfStyle(_ frame: Rect) -> String {
  "left:\(number: frame.x)px;top:\(number: frame.y)px;width:\(number: min(frame.width, 320))px"
}

/// The host a link shows: its URL's host without `www.`, or the whole URL when it has no scheme.
private func shownHost(of url: String) -> String {
  guard let parsed = URL(string: url), parsed.scheme != nil else {
    return url
  }

  let host = (parsed.host() ?? "").lowercased()
  return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
}
