import Foundation

/// The public sample export, `Fixtures/SampleExport` at the root of the repository.
let fixtureURL = URL(filePath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .appending(path: "Fixtures/SampleExport")
