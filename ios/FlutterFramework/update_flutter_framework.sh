#!/bin/bash
# Copies the Flutter engine's Flutter.xcframework (Debug/simulator+device)
# from the currently active Flutter SDK into this package's Frameworks/
# folder, so that Swift Package Manager can resolve `import Flutter` when
# opening/building kount_sdk_wrapper directly in Xcode.
#
# Usage:
#   ./update_flutter_framework.sh
#
# Requires `flutter` to be available on PATH.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="$SCRIPT_DIR/Frameworks"
DEST="$DEST_DIR/Flutter.xcframework"

FLUTTER_BIN="$(command -v flutter || true)"
if [ -z "$FLUTTER_BIN" ]; then
  echo "error: 'flutter' not found on PATH. Install/activate Flutter and try again." >&2
  exit 1
fi

# Resolve FLUTTER_ROOT by following the flutter script's real location.
FLUTTER_BIN_REAL="$(cd "$(dirname "$FLUTTER_BIN")" && pwd -P)/$(basename "$FLUTTER_BIN")"
FLUTTER_ROOT="$(cd "$(dirname "$FLUTTER_BIN_REAL")/.." && pwd)"

SRC="$FLUTTER_ROOT/bin/cache/artifacts/engine/ios/Flutter.xcframework"

if [ ! -d "$SRC" ]; then
  echo "error: could not find Flutter.xcframework at: $SRC" >&2
  echo "Try running 'flutter precache --ios' first." >&2
  exit 1
fi

mkdir -p "$DEST_DIR"
rm -rf "$DEST"
cp -R "$SRC" "$DEST"

echo "Copied Flutter.xcframework from:"
echo "  $SRC"
echo "to:"
echo "  $DEST"

