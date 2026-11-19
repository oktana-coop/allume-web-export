# Releasing

A release is a zip on GitHub with the tool for Apple silicon and Intel, signed with Oktana's
Developer ID certificate and notarized by Apple, beside its SHA-256. The
[Release workflow](../.github/workflows/release.yml) makes it, run by hand on `main`.

## Running a Release

On GitHub, open **Actions › Release › Run workflow**, keep the branch as `main`, and choose which
part of the version to bump: patch, minor or major. The workflow:

1. runs the tests;
2. bumps the version in `Sources/AllumeWebCLI/Version.swift`, which holds the latest release's;
3. builds the tool, signs it and has Apple notarize it;
4. commits the version as `chore: release vX.Y.Z`, tags the commit `vX.Y.Z`, and pushes both;
5. publishes the release, with the zip and its SHA-256.

## Secrets

The workflow reads five secrets from the repository's `release` environment, which only `main` can
use:

- `DEVELOPER_ID_CERTIFICATE`: the Developer ID Application certificate and its private key, as a
  `.p12` file encoded in base64.
- `DEVELOPER_ID_CERTIFICATE_PASSWORD`: the `.p12` file's password.
- `APPLE_ID`: the Apple ID notarization signs in with.
- `APPLE_TEAM_ID`: the team's ID, which the certificate's name ends with, in parentheses.
- `APPLE_APP_SPECIFIC_PASSWORD`: an app-specific password of that Apple ID, for this workflow.

## When a Release Doesn't Finish

Until it pushes the version and the tag, a run leaves nothing on GitHub, so after a failure it can
simply run again.

If publishing fails after the push, the workflow deletes the tag and reverts the version, unless
the release did get published. When a run stops there without undoing, for example when it's
cancelled, undo it by hand the same way:

```sh
gh release delete vX.Y.Z --yes    # only if a draft was left
git push --delete origin vX.Y.Z
git revert <the release commit> && git push
```

Then run the workflow again.
