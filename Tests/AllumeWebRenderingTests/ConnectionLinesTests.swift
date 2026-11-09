import AllumeWebModels
import Testing

@testable import AllumeWebRendering

@Suite struct ConnectionLinesTests {
  @Test func fillOneSVGFromTheBoardsOriginToTheFarEdgesOfItsContents() {
    let layout = BoardLayout(
      contentBounds: Rect(x: 80, y: 40, width: 1628, height: 840),
      connectionLines: [
        Line(from: Point(x: 606, y: 372.5), to: Point(x: 626, y: 372.5)),
        Line(from: Point(x: 1384.25, y: 554), to: Point(x: 1370.5, y: 590.75)),
      ])

    let html = drawConnectionLines(layout)?.rendered(resolving: describe)

    #expect(
      html
        == markup(
          #"""
          <svg class="allume-connections" width="1708" height="880" aria-hidden="true">
            <line x1="606" y1="372.5" x2="626" y2="372.5"/>
            <line x1="1384.25" y1="554" x2="1370.5" y2="590.75"/>
          </svg>
          """#))
  }

  @Test func areLeftOutWithoutConnections() {
    let layout = BoardLayout(
      contentBounds: Rect(x: 80, y: 40, width: 1628, height: 840), connectionLines: [])

    let html = drawConnectionLines(layout)

    #expect(html == nil)
  }
}
