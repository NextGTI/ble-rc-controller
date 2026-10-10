#!/usr/bin/env bash
# Publishes a GitHub Release for the version in pubspec.yaml, using the
# packages CI already built for the current commit.
#
# The release is created with YOUR gh login (so it shows your user as the
# author, not a bot) and points at a SIGNED tag (git tag -s), so GitHub shows
# "Verified". Needs commit/tag signing configured (see CONTRIBUTING.md).
# Usage:  tool/release.sh
#
# Before running: bump `version:` in pubspec.yaml, commit, push to main, and
# wait for the "Build" workflow to pass. Optional notes: release-notes/vX.Y.Z.md
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=$(grep '^version:' pubspec.yaml | sed -E 's/version: *//; s/\+.*//')
TAG="v$VERSION"
SHA=$(git rev-parse HEAD)

git diff --quiet && git diff --cached --quiet || { echo "Working tree has uncommitted changes."; exit 1; }
git fetch origin main -q
[ "$(git rev-parse origin/main)" = "$SHA" ] || { echo "HEAD ($SHA) is not the pushed tip of origin/main."; exit 1; }
gh release view "$TAG" >/dev/null 2>&1 && { echo "Release $TAG already exists."; exit 1; }
git rev-parse -q --verify "refs/tags/$TAG" >/dev/null && { echo "Local tag $TAG already exists."; exit 1; }
[ "$(git config --get gpg.format)" = "ssh" ] || [ -n "$(git config --get user.signingkey)" ] || { echo "Signing is not configured."; exit 1; }

RUN=$(gh run list --workflow build.yml --commit "$SHA" --status success --json databaseId --jq '.[0].databaseId // empty')
[ -n "$RUN" ] || { echo "No successful 'Build' run for $SHA yet. Wait for CI."; exit 1; }

rm -rf dist-ci && mkdir dist-ci
gh run download "$RUN" --dir dist-ci
FILES=$(find dist-ci -type f | sort)
echo "Packages:"; echo "$FILES"
[ "$(echo "$FILES" | wc -l)" -ge 3 ] || { echo "Expected Android, macOS and Windows packages."; exit 1; }

NOTES=()
if [ -f "release-notes/$TAG.md" ]; then NOTES=(--notes-file "release-notes/$TAG.md"); else NOTES=(--generate-notes); fi

# Signed, annotated tag first, so the release is built on a verified tag.
git tag -s "$TAG" -m "$TAG" "$SHA"
git push origin "$TAG"

# shellcheck disable=SC2086
gh release create "$TAG" $FILES --title "$TAG" "${NOTES[@]}"
echo "Done: $(gh release view "$TAG" --json url --jq .url)"
