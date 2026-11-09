import Testing

@testable import AllumeWebRendering

@Suite struct IconsTests {
  @Test func drawAnIconFromTheSprite() {
    let html = Icon.linked.html()

    let rendered = html.rendered(resolving: { _ in "" })

    #expect(
      rendered
        == markup(
          #"""
          <svg width="14" height="14" aria-hidden="true">
            <use href="#allume-icon-linked"/>
          </svg>
          """#))
  }

  @Test func giveAnIconAClass() {
    let html = Icon.copy.html(class: "allume-icon-copy")

    let rendered = html.rendered(resolving: { _ in "" })

    #expect(rendered.hasPrefix(#"<svg class="allume-icon-copy" width="14""#))
  }

  @Test func holdEveryIconOnceInTheSpriteWithTheAttribution() {
    let rendered = Icon.sprite.rendered(resolving: { _ in "" })

    #expect(
      rendered.hasPrefix(
        markup(
          #"""
          <svg class="allume-icon-sprite" aria-hidden="true">
            <!-- Icons: Font Awesome Free by @fontawesome
          """#)))
    #expect(rendered.contains("(CC BY 4.0) -->"))
    #expect(
      Icon.allCases.allSatisfy { icon in
        rendered.components(
          separatedBy: #"<symbol id="allume-icon-\#(icon.rawValue)" viewBox="0 0 "#
        )
        .count == 2
      })
    #expect(rendered.components(separatedBy: #"<path fill="currentColor" d="M"#).count == 6)
  }
}
