import Foundation
import Testing

@testable import AllumeWeb

@Suite struct FolderWriterTests {
  @Test func writesTextAndCopiesFilesIntoANewFolder() throws {
    let root = try makeTemporaryFolder()
    defer { try? FileManager.default.removeItem(at: root) }
    let image = try makeFile("image.png", text: "PNG", in: root)
    let folder = root.appending(path: "sites/languages")

    let warnings = try writeFolder(
      [
        SiteFile(path: "index.html", source: .text("<p>Languages</p>")),
        SiteFile(path: "files/image.png", source: .copy(image)),
      ],
      to: folder, replacingContents: false)

    #expect(warnings.isEmpty)
    #expect(try text(of: "index.html", in: folder) == "<p>Languages</p>")
    #expect(try text(of: "files/image.png", in: folder) == "PNG")
  }

  @Test func writesIntoAnEmptyFolderWithoutBeingAsked() throws {
    let root = try makeTemporaryFolder()
    defer { try? FileManager.default.removeItem(at: root) }

    _ = try writeFolder(
      [SiteFile(path: "index.html", source: .text("<p>Languages</p>"))], to: root,
      replacingContents: false)

    #expect(try text(of: "index.html", in: root) == "<p>Languages</p>")
  }

  @Test func refusesAFolderWithAnythingInIt() throws {
    let root = try makeTemporaryFolder()
    defer { try? FileManager.default.removeItem(at: root) }
    _ = try makeFile("notes.txt", text: "Mine", in: root)

    #expect(throws: UnwritableFolderError.notEmpty(root)) {
      try writeFolder(
        [SiteFile(path: "index.html", source: .text("<p>Languages</p>"))], to: root,
        replacingContents: false)
    }
    #expect(try text(of: "notes.txt", in: root) == "Mine")
  }

  @Test func replacesAFoldersContentsWhenAskedTo() throws {
    let root = try makeTemporaryFolder()
    defer { try? FileManager.default.removeItem(at: root) }
    _ = try makeFile("old.html", text: "Old", in: root)

    _ = try writeFolder(
      [SiteFile(path: "index.html", source: .text("<p>Languages</p>"))], to: root,
      replacingContents: true)

    #expect(try FileManager.default.contentsOfDirectory(atPath: root.path()) == ["index.html"])
  }

  @Test func refusesAFileInPlaceOfTheFolder() throws {
    let root = try makeTemporaryFolder()
    defer { try? FileManager.default.removeItem(at: root) }
    let file = try makeFile("site", text: "Not a folder", in: root)

    #expect(throws: UnwritableFolderError.notAFolder(file)) {
      try writeFolder(
        [SiteFile(path: "index.html", source: .text("<p>Languages</p>"))], to: file,
        replacingContents: true)
    }
  }

  @Test func rejectsPathsThatLeaveTheFolder() throws {
    let root = try makeTemporaryFolder()
    defer { try? FileManager.default.removeItem(at: root) }
    let folder = root.appending(path: "site")

    #expect(throws: UnwritableFolderError.pathOutsideFolder("files/../../escaped.txt")) {
      try writeFolder(
        [SiteFile(path: "files/../../escaped.txt", source: .text("Out"))], to: folder,
        replacingContents: false)
    }
    #expect(try FileManager.default.contentsOfDirectory(atPath: root.path()).isEmpty)
  }

  @Test func goesWithoutAMissingFileWithAWarning() throws {
    let root = try makeTemporaryFolder()
    defer { try? FileManager.default.removeItem(at: root) }
    let missing = root.appending(path: "missing.png")
    let folder = root.appending(path: "site")

    let warnings = try writeFolder(
      [
        SiteFile(path: "index.html", source: .text("<p>Languages</p>")),
        SiteFile(path: "files/missing.png", source: .copy(missing)),
      ],
      to: folder, replacingContents: false)

    #expect(warnings == [.missingFile(path: "files/missing.png", source: missing)])
    #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path()) == ["index.html"])
  }

  @Test func leavesTheFolderAsItWasWhenAWriteFails() throws {
    let root = try makeTemporaryFolder()
    defer { try? FileManager.default.removeItem(at: root) }
    _ = try makeFile("index.html", text: "Old", in: root)

    // A file can't also be a folder, so the second write fails.
    #expect(throws: UnwritableFolderError.self) {
      try writeFolder(
        [
          SiteFile(path: "files", source: .text("A file")),
          SiteFile(path: "files/image.png", source: .text("PNG")),
        ],
        to: root, replacingContents: true)
    }
    #expect(try FileManager.default.contentsOfDirectory(atPath: root.path()) == ["index.html"])
    #expect(try text(of: "index.html", in: root) == "Old")
  }
}

private func makeTemporaryFolder() throws -> URL {
  let folder = FileManager.default.temporaryDirectory.appending(path: "FolderWriterTests-\(UUID())")
  try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
  return folder
}

private func makeFile(_ name: String, text: String, in folder: URL) throws -> URL {
  let file = folder.appending(path: name)
  try Data(text.utf8).write(to: file)
  return file
}

private func text(of path: String, in folder: URL) throws -> String {
  try String(contentsOf: folder.appending(path: path), encoding: .utf8)
}
