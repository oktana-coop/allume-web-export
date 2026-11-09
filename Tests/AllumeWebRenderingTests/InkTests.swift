import AllumeWebModels
import Testing

@testable import AllumeWebRendering

@Suite struct InkTests {
  @Test func isItsFileAtItsSize() {
    let ink = Ink(file: makeAsset("root_ink.svg"), size: Size(width: 1305.5, height: 193))

    let html = drawInk(ink).rendered(resolving: describe)

    #expect(
      html
        == markup(
          #"""
          <img class="allume-ink" src="file:root_ink.svg" alt="" draggable="false"
            style="width:1305.5px;height:193px">
          """#))
  }
}
