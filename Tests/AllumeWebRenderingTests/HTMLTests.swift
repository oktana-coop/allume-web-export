import AllumeWebModels
import Foundation
import Testing

@testable import AllumeWebRendering

@Suite struct HTMLTests {
  @Suite struct Rendering {
    @Test func escapesTextAndAttributeValues() {
      let html = HTML.element(
        "p", ["title": #"Tom & Jerry's <"show">"#], [.text(#"Tom & Jerry's <"show">"#)])

      let rendered = html.rendered(resolving: describe)

      #expect(
        rendered
          == markup(
            #"""
            <p title="Tom &amp; Jerry&#39;s &lt;&quot;show&quot;&gt;">
              Tom &amp; Jerry&#39;s &lt;&quot;show&quot;&gt;
            </p>
            """#))
    }

    @Test func keepsTheOrderOfAttributesAndLeavesOutNilOnes() {
      let html = HTML.element("a", ["href": "#top", "id": nil, "class": "up"], [.text("Top")])

      let rendered = html.rendered(resolving: describe)

      #expect(
        rendered
          == markup(
            #"""
            <a href="#top" class="up">Top</a>
            """#))
    }

    @Test func rendersAnEmptyAttributeAsItsName() {
      let html = HTML.element("div", ["popover": .empty, "id": "menu"], [])

      let rendered = html.rendered(resolving: describe)

      #expect(rendered == #"<div popover id="menu"></div>"#)
    }

    @Test func rendersVoidElementsWithoutEndTags() {
      let html = HTML.element(
        "p", [:], [.element("img", ["src": "a.png", "alt": ""], []), .element("br", [:], [])])

      let rendered = html.rendered(resolving: describe)

      #expect(rendered == #"<p><img src="a.png" alt=""><br></p>"#)
    }

    @Test func closesSVGElementsWithoutChildrenThemselves() {
      let html = HTML.element(
        "span", [:],
        [
          .element("svg", ["width": "14"], [.element("use", ["href": "#icon-copy"], [])]),
          .element("span", ["class": "avatar"], []),
        ])

      let rendered = html.rendered(resolving: describe)

      #expect(
        rendered
          == markup(
            #"""
            <span>
              <svg width="14"><use href="#icon-copy"/></svg>
              <span class="avatar"></span>
            </span>
            """#))
    }

    @Test func rendersReferencesAsTheResolverSays() {
      let html = HTML.element(
        "a",
        ["href": .board(Document.ID(rawValue: "b"), card: Document.ID(rawValue: "c"))],
        [.element("img", ["src": .file(makeFile("a&b.png"))], [])])

      let rendered = html.rendered(resolving: describe)

      #expect(rendered == #"<a href="board:b#c"><img src="file:a&amp;b.png"></a>"#)
    }

    @Test func rendersTheDoctypeAndComments() {
      let html = [HTML.doctype, .comment("Icons: Font Awesome Free")]

      let rendered = html.map { node in node.rendered(resolving: describe) }

      #expect(rendered == ["<!doctype html>", "<!-- Icons: Font Awesome Free -->"])
    }
  }

  @Suite struct LineBreaks {
    @Test func goBetweenNodes() {
      let nodes = separatedByLineBreaks([.text("A"), .text("B"), .text("C")])

      let rendered = nodes.map { node in node.rendered(resolving: describe) }.joined()

      #expect(rendered == "A\nB\nC")
    }

    @Test func putNodesOnLinesOfTheirOwnInsideTheirParent() {
      let html = HTML.element("p", [:], onLinesOfTheirOwn([.text("A"), .text("B")]))

      let rendered = html.rendered(resolving: describe)

      #expect(rendered == "<p>\nA\nB\n</p>")
    }
  }

  @Suite struct Files {
    @Test func listTheFileReferencesInOrderWithRepeats() {
      let html = HTML.element(
        "div", ["data-image": .file(makeFile("a.png"))],
        [
          .element("a", ["href": .board(Document.ID(rawValue: "b"))], [.text("B")]),
          .element("img", ["src": .file(makeFile("b.svg"))], []),
          .element("p", [:], [.element("img", ["src": .file(makeFile("a.png"))], [])]),
        ])

      let files = html.files

      #expect(files.map(\.path) == ["a.png", "b.svg", "a.png"])
    }

    @Test func areEmptyWithoutElements() {
      let html = HTML.text("No files")

      let files = html.files

      #expect(files.isEmpty)
    }
  }
}

private func makeFile(_ path: String) -> PublishedFile {
  PublishedFile(path: path, source: URL(filePath: "/bundle/files/\(path)"))
}
