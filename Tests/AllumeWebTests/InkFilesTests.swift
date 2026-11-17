import AllumeWebModels
import Foundation
import Testing

@testable import AllumeWeb

@Suite struct InkFilesTests {
  @Test func makeACopyShowingTranslucentInkAsAllumeDoes() throws {
    let folder = try makeTemporaryFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let svg = #"<svg width="10" height="20"><path stroke-opacity="0.5" d="M0 0L5 5"/></svg>"#
    let file = folder.appending(path: "ink.svg")
    try Data(svg.utf8).write(to: file)
    let contents = try makeContents(withInk: Asset(name: "ink.svg", url: file))

    let files = makeInkFiles(of: contents, in: folder.appending(path: "made"))

    let copy = try #require(files["ink.svg"])
    #expect(copy.name == "ink.svg")
    #expect(try String(contentsOf: copy.url, encoding: .utf8) == darkeningTranslucentInk(in: svg))
  }

  @Test func leaveOutInkWhoseFileIsMissing() throws {
    let folder = try makeTemporaryFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let contents = try makeContents(
      withInk: Asset(name: "ink.svg", url: folder.appending(path: "ink.svg")))

    let files = makeInkFiles(of: contents, in: folder.appending(path: "made"))

    #expect(files.isEmpty)
  }

  @Test func leaveOutInkWhoseNameLeavesTheFolder() throws {
    let folder = try makeTemporaryFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let file = folder.appending(path: "ink.svg")
    try Data("<svg></svg>".utf8).write(to: file)
    let contents = try makeContents(withInk: Asset(name: "../ink.svg", url: file))

    let files = makeInkFiles(of: contents, in: folder.appending(path: "made"))

    #expect(files.isEmpty)
    #expect(try String(contentsOf: file, encoding: .utf8) == "<svg></svg>")
  }
}

@Suite struct DarkeningTranslucentInkTests {
  @Test func putsItsRuleFirstInTheRoot() {
    let svg = """
      <?xml version="1.0" encoding="UTF-8"?>
      <svg  xmlns="http://www.w3.org/2000/svg" height="20" width="10">
      <path stroke="#c69eff" stroke-opacity="0.5" d="M0 0L5 5"/>
      </svg>
      """

    let darkened = darkeningTranslucentInk(in: svg)

    #expect(
      darkened == """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg  xmlns="http://www.w3.org/2000/svg" height="20" width="10">\
        <style>svg { isolation: isolate; } path[stroke-opacity] { mix-blend-mode: darken; }</style>
        <path stroke="#c69eff" stroke-opacity="0.5" d="M0 0L5 5"/>
        </svg>
        """)
  }

  @Test(arguments: ["<svg/>", #"<svg width="10" />"#, "Not an SVG"])
  func leavesAnSVGWithoutARootToPutItInAsItIs(svg: String) {
    #expect(darkeningTranslucentInk(in: svg) == svg)
  }
}

private func makeContents(withInk file: Asset) throws -> Contents {
  try Contents(
    rootID: Document.ID(rawValue: "root"),
    documents: [
      .board(
        Document.Board(
          id: Document.ID(rawValue: "root"), label: "Languages", cards: [], chains: [],
          connections: [], ink: [Ink(file: file, size: Size(width: 10, height: 20))]))
    ],
    users: [:]
  )
}

private func makeTemporaryFolder() throws -> URL {
  let folder = FileManager.default.temporaryDirectory.appending(path: "Ink files \(UUID())")
  try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
  return folder
}
