#!/bin/bash
set -e

# Download the latest Linux bundle from GitHub Releases.
# Usage: ./download-linux-bundle.sh [version]
#   ./download-linux-bundle.sh          # latest release
#   ./download-linux-bundle.sh v0.8.6   # specific version

REPO="bibliogenius/bibliogenius-app"
DEST="../_ressources/bundle"
VERSION="${1:-latest}"

echo "=== Download BiblioGenius Linux Bundle ==="

# Check for required tools
if ! command -v gh &> /dev/null && ! command -v curl &> /dev/null; then
  echo "❌ Either 'gh' (GitHub CLI) or 'curl' is required."
  exit 1
fi

# Get download URL
if [ "$VERSION" = "latest" ]; then
  echo "Fetching latest release..."
  if command -v gh &> /dev/null; then
    URL=$(gh release view --repo "$REPO" --json assets --jq '.assets[] | select(.name | test("Linux")) | .url' 2>/dev/null)
    TAG=$(gh release view --repo "$REPO" --json tagName --jq '.tagName' 2>/dev/null)
  else
    TAG=$(curl -sf "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name"' | cut -d'"' -f4)
    URL="https://github.com/$REPO/releases/download/$TAG/BiblioGenius-Linux.tar.gz"
  fi
else
  TAG="$VERSION"
  URL="https://github.com/$REPO/releases/download/$TAG/BiblioGenius-Linux.tar.gz"
fi

if [ -z "$URL" ] && [ -z "$TAG" ]; then
  echo "❌ Could not find a release. Check https://github.com/$REPO/releases"
  exit 1
fi

echo "Version: $TAG"

# Download
TMPFILE=$(mktemp /tmp/bibliogenius-linux-XXXXXX.tar.gz)
echo "Downloading..."

if command -v gh &> /dev/null; then
  gh release download "$TAG" --repo "$REPO" --pattern "BiblioGenius-Linux.tar.gz" --output "$TMPFILE" --clobber
else
  curl -fL "$URL" -o "$TMPFILE"
fi

# Extract
echo "Extracting to $DEST..."
rm -rf "$DEST"
mkdir -p "$DEST"
tar -xzf "$TMPFILE" --strip-components=1 -C "$DEST"
rm -f "$TMPFILE"

# Verify
if [ -f "$DEST/app" ]; then
  echo "✅ Bundle ready at $DEST"
  echo "   Run: docker compose run --rm --service-ports linux-app vnc"
else
  echo "❌ Extraction failed — 'app' binary not found in $DEST"
  ls -la "$DEST"
  exit 1
fi
