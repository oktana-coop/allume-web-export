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

  @Option(help: "The folder to write the site to. It's emptied first.")
  var out = "out"

  @Flag(
    inversion: .prefixedNo,
    help: "Fetch each link's favicon. --no-favicons skips the download, e.g. to build offline."
  )
  var favicons = true

  func run() throws {
    FileHandle.standardError.write(Data("Not implemented yet.\n".utf8))
    throw ExitCode.failure
  }
}
