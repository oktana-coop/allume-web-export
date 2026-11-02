import Foundation

/// The public fixture export, `Fixtures/Languages` at the root of the repository.
let fixtureURL = URL(filePath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .appending(path: "Fixtures/Languages")
