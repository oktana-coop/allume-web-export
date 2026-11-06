import Foundation
import Testing

/// The public fixture export, `Fixtures/Languages` at the root of the repository.
let fixtureURL = URL(filePath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .appending(path: "Fixtures/Languages")

/// The accepted output, next to the tests so that `ACCEPT=1` can write it.
let expectedURL = URL(filePath: #filePath).deletingLastPathComponent().appending(path: "Expected")

/// Compares each file's text with the expected file of the same name in the folder, which holds no
/// others. With `ACCEPT=1`, replaces the folder with the output instead.
func compareWithExpectedFiles(_ output: [String: String], in folder: URL) throws {
  if ProcessInfo.processInfo.environment["ACCEPT"] == "1" {
    try? FileManager.default.removeItem(at: folder)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    for (name, text) in output {
      try text.write(to: folder.appending(path: name), atomically: true, encoding: .utf8)
    }
    return
  }

  let expectedNames = try FileManager.default.contentsOfDirectory(atPath: folder.path())
  let differences = output.sorted { a, b in a.key < b.key }.compactMap { name, text in
    let expected = (try? String(contentsOf: folder.appending(path: name), encoding: .utf8)) ?? ""
    return firstDifference(between: text, and: expected).map { difference in
      "\(name), \(difference)"
    }
  }

  #expect(
    Set(expectedNames) == Set(output.keys),
    "The output's files aren't the expected ones. Run with ACCEPT=1 to accept them.")
  #expect(
    differences.isEmpty,
    """
    The output differs from the expected files. Run with ACCEPT=1 to accept it, then check \
    `git diff`.
    \(differences.joined(separator: "\n"))
    """)
}

/// The first line where the texts differ, or nil when they're the same.
private func firstDifference(between actual: String, and expected: String) -> String? {
  let actualLines = actual.split(separator: "\n", omittingEmptySubsequences: false)
  let expectedLines = expected.split(separator: "\n", omittingEmptySubsequences: false)
  guard actualLines != expectedLines else {
    return nil
  }

  let index =
    zip(actualLines, expectedLines).enumerated().first { _, lines in lines.0 != lines.1 }?.offset
    ?? min(actualLines.count, expectedLines.count)
  let line = { (lines: [Substring]) -> Substring in
    lines.indices.contains(index) ? lines[index].prefix(200) : "(none)"
  }
  return "line \(index + 1)\n  expected: \(line(expectedLines))\n  actual:   \(line(actualLines))"
}
