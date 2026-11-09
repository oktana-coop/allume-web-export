import AllumeWeb
import AllumeWebBundleReader
import AllumeWebModels
import ArgumentParser
import Foundation

@main
struct AllumeWebExportCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "allume-web-export",
    abstract: "Publishes an Allume board export on the web.",
    subcommands: [SiteCommand.self, EmbedCommand.self]
  )
}

struct SiteCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "site",
    abstract: "Writes the export as a website of its own, with a page for each board."
  )

  @OptionGroup var options: PublishingOptions

  func run() async throws {
    try await publish(with: options, publishSite(_:to:replacingContents:faviconCache:))
  }
}

struct EmbedCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "embed",
    abstract: "Writes each board's view, for an existing site to embed in its own pages.",
    discussion: """
      The folder holds boards.json, which lists the boards; each board's view, under boards/; the \
      files the views show, under files/; and the viewer, allume.js and allume.css. The views \
      link to boards and files with allume: references, for the site to replace with its own \
      URLs, unless --board-url and --files-url give them. Embedding here means putting a view's \
      HTML in a page, not an <iframe>.
      """
  )

  @OptionGroup var options: PublishingOptions

  @Option(
    help: ArgumentHelp(
      "Each board's URL on the site, with {slug} standing for the board's slug, e.g. "
        + "/boards/{slug}/. Without it, links to boards are kept as allume: references.",
      valueName: "pattern")
  )
  var boardURL: String?

  @Option(
    help: ArgumentHelp(
      "Where the site serves the folder's files/, e.g. /allume/files. Without it, images and "
        + "other files are kept as allume: references.",
      valueName: "url")
  )
  var filesURL: String?

  func validate() throws {
    if let boardURL, !boardURL.contains("{slug}") {
      throw ValidationError(
        "--board-url needs {slug}, which stands for each board's slug, e.g. /boards/{slug}/.")
    }
  }

  func run() async throws {
    try await publish(with: options) {
      contents, folder, replacing, cache async throws(UnwritableFolderError) in
      try await publishEmbed(
        contents, to: folder, replacingContents: replacing, faviconCache: cache,
        boardURL: boardURL, filesURL: filesURL)
    }
  }
}

struct PublishingOptions: ParsableArguments {
  @Argument(help: "The export folder, with contents.json and files/.")
  var exportDir: String

  @Option(
    help: "The folder to write to. It must be missing or empty, unless --replace is given."
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
}

/// Reads the export, publishes it into the --out folder with the function, and reports what was
/// written, then any warnings.
private func publish(
  with options: PublishingOptions,
  _ publishing: (Contents, URL, Bool, URL?) async throws(UnwritableFolderError) -> (
    faviconCount: Int, warnings: [PublishingWarning]
  )
) async throws(CommandFailure) {
  let exportFolder = URL(filePath: options.exportDir, directoryHint: .isDirectory).absoluteURL
  let outFolder = URL(filePath: options.out, directoryHint: .isDirectory).absoluteURL
  let faviconCache = URL.cachesDirectory.appending(path: "allume-web-export/favicons")

  let (contents, readingWarnings) = try await failingWithMessage {
    () throws(UnreadableBundleError) in
    try readBundle(at: exportFolder)
  } message: { error in
    errorMessage(for: error)
  }
  let (faviconCount, publishingWarnings) = try await failingWithMessage {
    () async throws(UnwritableFolderError) in
    try await publishing(
      contents, outFolder, options.replace, options.favicons ? faviconCache : nil)
  } message: { error in
    errorMessage(for: error)
  }

  let name = contents.board(contents.rootID)?.label ?? exportFolder.lastPathComponent
  let boardCount = contents.hierarchy.boardIDs.count
  // Unbuffered, like standard error, so the summary comes before the warnings.
  FileHandle.standardOutput.write(
    Data("\(name): \(boardCount) boards, \(faviconCount) favicons → \(options.out)\n".utf8))
  let warnings =
    readingWarnings.map { warning in warningMessage(for: warning, in: contents) }
    + publishingWarnings.map { warning in warningMessage(for: warning) }
  FileHandle.standardError.write(
    Data(warnings.map { warning in "  warning: \(warning)\n" }.joined().utf8))
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
