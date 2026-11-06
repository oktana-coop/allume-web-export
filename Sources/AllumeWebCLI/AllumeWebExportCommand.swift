import AllumeWeb
import AllumeWebBundleReader
import AllumeWebModels
import ArgumentParser
import Foundation

@main
struct AllumeWebExportCommand: ParsableCommand {
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
    help: "Fetch each link's favicon. --no-favicons skips the download, e.g. to build offline."
  )
  var favicons = true

  func run() throws {
    let exportFolder = URL(filePath: exportDir, directoryHint: .isDirectory).absoluteURL
    let outFolder = URL(filePath: out, directoryHint: .isDirectory).absoluteURL

    let (contents, readingWarnings) = try failingWithMessage { () throws(UnreadableBundleError) in
      try readBundle(at: exportFolder)
    } message: { error in
      errorMessage(for: error)
    }
    let publishingWarnings = try failingWithMessage { () throws(UnwritableFolderError) in
      try publishSite(contents, to: outFolder, replacingContents: replace)
    } message: { error in
      errorMessage(for: error)
    }

    let name = contents.board(contents.rootID)?.label ?? exportFolder.lastPathComponent
    // Unbuffered, like standard error, so the summary comes before the warnings.
    FileHandle.standardOutput.write(
      Data("\(name): \(contents.hierarchy.boardIDs.count) boards, 0 favicons → \(out)\n".utf8))
    let warnings =
      readingWarnings.map { warning in warningMessage(for: warning, in: contents) }
      + publishingWarnings.map { warning in warningMessage(for: warning) }
      + (favicons ? [faviconsNotFetched] : [])
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
  _ body: () throws(Failure) -> Result, message: (Failure) -> String
) throws(CommandFailure) -> Result {
  do {
    return try body()
  } catch {
    throw CommandFailure(description: message(error))
  }
}
