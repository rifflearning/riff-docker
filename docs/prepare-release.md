Creating Releases
=================

## General preparation and merging the release branch

----
We're (rifflearning) not quite ready for this, but it is a good process that should not get lost.

Make sure all [closed pull requests](https://github.com/rifflearning/riff-rtc/pulls?q=is%3Apr+is%3Aclosed)
have a target version.

Postpone all remaining open issues and pull requests targeted at this version and create a new version
milestone for the next release.
----

## Creating the Release

Create a new release branch `release/major.minor.x` (patches are always committed to an existing
release branch they don't have their own so the branch name always is `*.x` (from the appropriate
commit on the `develop` branch).

On this new release branch:
  - Update the `CHANGELOG.md` and commit it with a message like _update CHANGELOG for 1.0.0 release_
  - Bump the version number in `package.json` (using the `npm version` command with update package.json
    and package-lock.json) in the next commit (if npm creates a tag, delete it because we don't want it
    on this commit)

Merge the release branch into `master` (or `main`) with a merge commit, so the head of master
is the latest release.

  - Tag the merge commit at the HEAD of master with the release version (use a `v` prefix) and make sure
    it is signed with a trusted GPG key, and push the signed tag to github.
  - FF (fast forward) merge the release branch to the merge commit.

Then

- Merge the release tag back into `develop` (equivalent to merging `master` or the release branch
  as all refer to the same commit, but the tag merge should provide a better commit message)
- Add a new commit to `develop` bumping the version number to a prerelease dev.0 (or dev.1)
  of the next minor version. The next release version may be a minor bump or a major
  bump, but the this dev prerelease should be the smallest version bump from the last release.
```
npm version preminor --preid=dev
```
  Use dev.0 if the code in develop is functionally identical to the release, and dev.1
  if there is code in develop that is not yet in the release.
- Push all changes as well as the new release tag.

A release branch should live for as long as that release needs to be supported, in order
to add fixes for patch releases.

