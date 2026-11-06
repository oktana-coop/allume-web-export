import Foundation

/// Why a site couldn't be written to its folder. A folder that was there is left as it was.
public enum UnwritableFolderError: Error, Equatable, Sendable {
  /// Something other than a folder is at its path.
  case notAFolder(URL)
  /// The folder has something in it, and replacing its contents wasn't asked for.
  case notEmpty(URL)
  /// A file's path would leave the folder, as `../notes.txt` does.
  case pathOutsideFolder(String)
  case writeFailed(URL, reason: String)
}
