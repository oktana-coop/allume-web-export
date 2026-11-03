import AllumeWebModels
import Foundation

/// The bundle's contents, with what reading them left out or worked around.
package func readBundle(at folder: URL) throws(UnreadableBundleError)
  -> (contents: Contents, warnings: [BundleWarning])
{
  let bundle = try AllumeBundle(contentsOf: folder)
  let version = bundle.metadata.bundleVersion
  let versionWarnings: [BundleWarning] = version == 6 ? [] : [.unknownBundleVersion(version)]

  let (documents, documentWarnings) = readDocuments(in: bundle)
  let (users, userWarnings) = readUsers(in: bundle)

  let contents: Contents
  do {
    contents = try Contents(
      rootID: Document.ID(rawValue: bundle.contents.root), documents: documents, users: users)
  } catch {
    throw .invalidContents(error)
  }

  return (
    contents,
    versionWarnings + documentWarnings + userWarnings + warnings(about: contents.omissions)
  )
}

private func warnings(about omissions: Contents.Omissions) -> [BundleWarning] {
  let cardsForMissingDocuments = omissions.cardsForMissingDocuments.map { card -> BundleWarning in
    .cardForMissingDocument(boardID: card.boardID, documentID: card.documentID)
  }
  let cardsOfWrongKind = omissions.cardsOfWrongKind.map { card -> BundleWarning in
    .cardOfWrongKind(boardID: card.boardID, documentID: card.documentID)
  }
  let repeatedCards = omissions.repeatedCards.map { card -> BundleWarning in
    .repeatedCard(boardID: card.boardID, documentID: card.documentID)
  }
  let excerpts = omissions.excerptsWithMissingSources.map { imageID -> BundleWarning in
    .excerptWithMissingSource(imageID)
  }
  let documentsOutsideRoot = omissions.documentsOutsideRoot.map { documentID -> BundleWarning in
    .documentOutsideRoot(documentID)
  }

  return cardsForMissingDocuments + cardsOfWrongKind + repeatedCards + excerpts
    + documentsOutsideRoot
}
