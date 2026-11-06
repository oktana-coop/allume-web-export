import AllumeWeb
import AllumeWebBundleReader
import AllumeWebModels
import ArgumentParser
import Foundation

@main
struct AllumeWebExportCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "allume-web-export",
    abstract: "Renders an Allume board export as a static website."
  )

  @Argument(help: "The export folder, with contents.json and files/.")
  var exportDir: String

  @Option(
    help: "The folder to write the site to. It must be missing or empty, unless --replace is given."
  )
  var out = "out"

  @Flag(
    help: ArgumentHelp(
      "Replace the contents of the --out folder. Without it, a folder with anything in it is "
        + "left alone.")
  )
  var replace = false

  @Flag(
    inversion: .prefixedNo,
    help: ArgumentHelp(
      "Show each link's favicon, fetched once and kept in "
        + "~/Library/Caches/allume-web-export/favicons. --no-favicons leaves them out, e.g. to "
        + "build offline.")
  )
  var favicons = true

  func run() async throws {
    let exportFolder = URL(filePath: exportDir, directoryHint: .isDirectory).absoluteURL
    let outFolder = URL(filePath: out, directoryHint: .isDirectory).absoluteURL
    let faviconCache = URL.cachesDirectory.appending(path: "allume-web-export/favicons")

    let (contents, readingWarnings) = try await failingWithMessage {
      () throws(UnreadableBundleError) in
      try readBundle(at: exportFolder)
    } message: { error in
      errorMessage(for: error)
    }
    let (faviconCount, publishingWarnings) = try await failingWithMessage {
      () async throws(UnwritableFolderError) in
      try await publishSite(
        contents, to: outFolder, replacingContents: replace,
        faviconCache: favicons ? faviconCache : nil)
    } message: { error in
      errorMessage(for: error)
    }

    let name = contents.board(contents.rootID)?.label ?? exportFolder.lastPathComponent
    let boardCount = contents.hierarchy.boardIDs.count
    // Unbuffered, like standard error, so the summary comes before the warnings.
    FileHandle.standardOutput.write(
      Data("\(name): \(boardCount) boards, \(faviconCount) favicons → \(out)\n".utf8))
    let warnings =
      readingWarnings.map { warning in warningMessage(for: warning, in: contents) }
      + publishingWarnings.map { warning in warningMessage(for: warning) }
    FileHandle.standardError.write(
      Data(warnings.map { warning in "  warning: \(warning)\n" }.joined().utf8))
  }
}

/// A failure the command reports in words, which swift-argument-parser prints as `Error: …`.
struct CommandFailure: Error, CustomStringConvertible {
  let description: String
}

/// Runs the body, turning its error into a failure worded by the message.
private func failingWithMessage<Result, Failure: Error>(
  _ body: () async throws(Failure) -> Result, message: (Failure) -> String
) async throws(CommandFailure) -> Result {
  do {
    return try await body()
  } catch {
    throw CommandFailure(description: message(error))
  }
}
