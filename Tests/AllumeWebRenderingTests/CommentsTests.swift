import AllumeWebModels
import Testing

@testable import AllumeWebRendering

@Suite struct CommentsTests {
  @Test func showTheirAuthorAndDateInUTC() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        makeBoard("root", comments: ["comment"]), makeComment("comment", author: "mira"),
      ],
      users: [
        User.ID(rawValue: "mira"): User(
          id: User.ID(rawValue: "mira"), name: "Mira Okafor",
          color: RGBColor(red: 0x7f, green: 0x0b, blue: 0xd5), avatar: makeAsset("user_mira.png"))
      ]
    )

    let html = drawnComment("comment", on: "root", in: contents, interactive: false)

    #expect(
      html
        == markup(
          #"""
          <div class="allume-comment"
            style="left:0px;top:0px;width:100px;height:100px;z-index:9000;--author:#7f0bd5">
            <img class="allume-avatar" src="file:user_mira.png" alt="Mira Okafor" title="Mira Okafor"
              draggable="false">
            <div class="allume-text">A comment</div>
            <time datetime="2024-11-01T09:11:44Z">Nov 1, 2024</time>
          </div>
          """#))
  }

  @Test func leaveAnEmptyAvatarWithoutAnAuthor() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [makeBoard("root", comments: ["comment"]), makeComment("comment")],
      users: [:]
    )

    let html = drawnComment("comment", on: "root", in: contents, interactive: true)

    #expect(html?.contains(#"z-index:9000"><span class="allume-avatar"></span>"#) == true)
    #expect(html?.hasSuffix(copyButtonMarkup + "</div>") == true)
  }
}

private func drawnComment(
  _ commentID: String, on boardID: String, in contents: Contents, interactive: Bool
) -> String? {
  let thread = contents.board(Document.ID(rawValue: boardID))?.chains.compactMap {
    chain -> CommentThread? in
    guard case .comments(let thread) = chain else {
      return nil
    }
    return thread
  }.first
  let card = thread?.cards.first { card in card.documentID.rawValue == commentID }

  return card.flatMap { card in
    drawComment(card, contents: contents, interactive: interactive)?.rendered(
      resolving: describe)
  }
}
