#!/usr/bin/env bash
set -euo pipefail

# Flutter web build helper for Vercel
# Downloads (or reuses cached) Flutter SDK, enables web, and builds release bundle.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE_DIR="${VERCEL_CACHE_DIR:-$REPO_ROOT/.vercel/cache}"
FLUTTER_VERSION="${FLUTTER_VERSION:-3.32.5}"
FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"
FLUTTER_ARCHIVE="flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz"
FLUTTER_SDK_DIR="$CACHE_DIR/flutter-${FLUTTER_VERSION}-${FLUTTER_CHANNEL}"

mkdir -p "$CACHE_DIR"

if [ ! -x "$FLUTTER_SDK_DIR/bin/flutter" ]; then
  echo "Downloading Flutter $FLUTTER_VERSION ($FLUTTER_CHANNEL channel)..."
  curl -sSL "https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/linux/$FLUTTER_ARCHIVE" -o "$CACHE_DIR/$FLUTTER_ARCHIVE"
  tar -xf "$CACHE_DIR/$FLUTTER_ARCHIVE" -C "$CACHE_DIR"
  rm -f "$CACHE_DIR/$FLUTTER_ARCHIVE"
  mv "$CACHE_DIR/flutter" "$FLUTTER_SDK_DIR"
else
  echo "Reusing cached Flutter SDK at $FLUTTER_SDK_DIR"
fi

export PATH="$FLUTTER_SDK_DIR/bin:$PATH"
export FLUTTER_ALLOW_ROOT=1
export FLUTTER_SUPPRESS_ANALYTICS=1
export CI=${CI:-true}
export PUB_CACHE="$CACHE_DIR/pub-cache"
mkdir -p "$PUB_CACHE"

git config --global --add safe.directory "$FLUTTER_SDK_DIR" >/dev/null 2>&1 || true

pushd "$REPO_ROOT" >/dev/null

# Create .env file from Vercel environment variables
echo "Creating .env file from environment variables..."
cat > .env << EOF
GEMINI_API_KEY=${GEMINI_API_KEY:-}
RAG_SERVER_URL=${RAG_SERVER_URL:-http://localhost:8001}
GEMINI_MODEL=${GEMINI_MODEL:-gemini-2.0-flash-lite}
API_TIMEOUT=${API_TIMEOUT:-120}
RAG_TIMEOUT=${RAG_TIMEOUT:-120}
EOF

echo ".env file created:"
cat .env

flutter config --enable-web
flutter config --no-analytics --no-cli-animations
flutter --version
flutter pub get
flutter build web --release --no-tree-shake-icons

popd >/dev/null
