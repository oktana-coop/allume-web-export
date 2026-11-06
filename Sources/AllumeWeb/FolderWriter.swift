import Foundation

/// Writes the files into a new folder, and swaps it in for the given one once they're all written,
/// so a failed run leaves the folder as it was. A folder with anything in it is only replaced when
/// asked to, since replacing deletes what's there.
func writeFolder(_ files: [SiteFile], to folder: URL, replacingContents: Bool)
  throws(UnwritableFolderError) -> [PublishingWarning]
{
  if let outside = files.first(where: { file in leavesFolder(file.path) }) {
    throw .pathOutsideFolder(outside.path)
  }
  let folderExists = try checkCanWrite(to: folder, replacingContents: replacingContents)

  let parent = folder.deletingLastPathComponent()
  try attempt(at: parent) {
    try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
  }
  let staging = try attempt(at: parent) {
    try FileManager.default.url(
      for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: parent, create: true)
  }
  defer { try? FileManager.default.removeItem(at: staging) }
  let newFolder = staging.appending(path: folder.lastPathComponent)

  let warnings = try files.map { file throws(UnwritableFolderError) in
    try write(file, into: newFolder)
  }
  try attempt(at: folder) {
    try FileManager.default.createDirectory(at: newFolder, withIntermediateDirectories: true)
    if folderExists {
      _ = try FileManager.default.replaceItemAt(folder, withItemAt: newFolder)
    } else {
      try FileManager.default.moveItem(at: newFolder, to: folder)
    }
  }

  return warnings.compactMap { $0 }
}

/// Whether the folder exists, after checking it can be written: a missing folder can, and so can
/// an empty one, or one whose contents are to be replaced.
private func checkCanWrite(to folder: URL, replacingContents: Bool)
  throws(UnwritableFolderError) -> Bool
{
  switch try? folder.resourceValues(forKeys: [.isDirectoryKey]).isDirectory {
  case nil:
    return false
  case false?:
    throw .notAFolder(folder)
  case true?:
    let contents = try attempt(at: folder) {
      try FileManager.default.contentsOfDirectory(atPath: folder.path(percentEncoded: false))
    }
    guard contents.isEmpty || replacingContents else {
      throw .notEmpty(folder)
    }
    return true
  }
}

/// Paths come from the bundle's data, so none may climb out of the folder or start from the root.
private func leavesFolder(_ path: String) -> Bool {
  path.hasPrefix("/") || path.split(separator: "/").contains("..")
}

/// Nil once the file is written, or a warning when its source is missing.
private func write(_ file: SiteFile, into folder: URL)
  throws(UnwritableFolderError) -> PublishingWarning?
{
  let destination = folder.appending(path: file.path)

  switch file.source {
  case .text(let text):
    try attempt(at: destination) {
      try createParent(of: destination)
      try Data(text.utf8).write(to: destination)
    }
    return nil

  case .copy(let source):
    guard FileManager.default.fileExists(atPath: source.path(percentEncoded: false)) else {
      return .missingFile(path: file.path, source: source)
    }
    try attempt(at: destination) {
      try createParent(of: destination)
      try FileManager.default.copyItem(at: source, to: destination)
    }
    return nil
  }
}

private func createParent(of file: URL) throws {
  try FileManager.default.createDirectory(
    at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
}

/// Runs the body, turning whatever it throws into a failed write at the URL.
private func attempt<Result>(at url: URL, _ body: () throws -> Result)
  throws(UnwritableFolderError) -> Result
{
  do {
    return try body()
  } catch {
    throw .writeFailed(url, reason: error.localizedDescription)
  }
}
