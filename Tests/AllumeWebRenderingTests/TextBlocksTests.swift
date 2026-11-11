import AllumeWebModels
import Testing

@testable import AllumeWebRendering

@Suite struct TextBlocksTests {
  @Test func drawTheirParagraphsWithTheirHighlights() {
    let block = makeTextBlock(
      lineBreakWidth: 400,
      paragraphs: [("Pure functions", .purple), ("Same input, same output.", nil)])

    let html = drawTextBlock(block, interactive: false).rendered(resolving: describe)

    #expect(
      html
        == markup(
          #"""
          <div class="allume-text-block" style="left:700px;top:40px;max-width:400px">
            <p data-allume-color="purple">Pure functions</p>
            <p>Same input, same output.</p>
          </div>
          """#))
  }

  @Test func drawTheirHeadingsAsH3() {
    let block = TextBlock(
      id: Chain.ID(rawValue: "text"), position: Point(x: 0, y: 0), lineBreakWidth: 400,
      paragraphs: [
        TextBlock.Paragraph(text: "Value", highlight: nil, role: .heading),
        TextBlock.Paragraph(text: "Scarcity", highlight: nil),
      ])

    let html = drawTextBlock(block, interactive: false).rendered(resolving: describe)

    #expect(html.contains("<h3>Value</h3><p>Scarcity</p>"))
  }

  @Test func keepAnEmptyParagraphsLineWithoutItsHighlight() {
    let block = makeTextBlock(
      lineBreakWidth: 400, paragraphs: [("Laziness", nil), ("", .green), ("Thunks", nil)])

    let html = drawTextBlock(block, interactive: false).rendered(resolving: describe)

    #expect(html.contains("<p>Laziness</p><p><br></p><p>Thunks</p>"))
  }

  @Test func are600WideWithoutALineBreakWidth() {
    let block = makeTextBlock(lineBreakWidth: nil, paragraphs: [("Laziness", nil)])

    let html = drawTextBlock(block, interactive: false).rendered(resolving: describe)

    #expect(html.contains(#"style="left:700px;top:40px;max-width:600px""#))
  }

  @Test func haveACopyButtonOnTheBoardsOwnPage() {
    let block = makeTextBlock(lineBreakWidth: nil, paragraphs: [("Laziness", nil)])

    let html = drawTextBlock(block, interactive: true).rendered(resolving: describe)

    #expect(html.hasSuffix("<p>Laziness</p>" + copyButtonMarkup + "</div>"))
  }
}

private func makeTextBlock(lineBreakWidth: Double?, paragraphs: [(String, CardColor?)])
  -> TextBlock
{
  TextBlock(
    id: Chain.ID(rawValue: "text"), position: Point(x: 700, y: 40), lineBreakWidth: lineBreakWidth,
    paragraphs: paragraphs.map { text, highlight in
      TextBlock.Paragraph(text: text, highlight: highlight)
    })
}
