import AllumeWebModels
import Foundation

/// Writes the standalone site into the folder. A folder with anything in it is only written to when
/// its contents are to be replaced, and a failed run leaves it as it was.
public func publishSite(_ contents: Contents, to folder: URL, replacingContents: Bool)
  throws(UnwritableFolderError) -> [PublishingWarning]
{
  try writeFolder(siteFiles(for: contents), to: folder, replacingContents: replacingContents)
}
