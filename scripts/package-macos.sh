#!/bin/bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This packaging script must be run on macOS." >&2
  exit 1
fi

# QA deliberately uses a different bundle ID and Application Support folder.
# Never change the real app's bundle ID, existing cache, or preferences.
case "${1:-}" in
  "")
    APP_BASENAME="ArashKam"
    BUNDLE_ID="com.arashkam.reader"
    DISPLAY_NAME="آرش کمانگیر"
    ;;
  "--qa")
    APP_BASENAME="ArashKam-QA"
    BUNDLE_ID="com.arashkam.reader.qa"
    DISPLAY_NAME="آرش کمانگیر — QA"
    ;;
  *)
    echo "Usage: bash scripts/package-macos.sh [--qa]" >&2
    exit 2
    ;;
esac

cd "$(dirname "$0")/.."
swift build -c release --product ArashKam
BIN_DIR="$(swift build -c release --show-bin-path)"
APP="$PWD/dist/$APP_BASENAME.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/ArashKam" "$APP/Contents/MacOS/ArashKam"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>ArashKam</string>
<key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
<key>CFBundleName</key><string>$APP_BASENAME</string>
<key>CFBundleIconFile</key><string>AppIcon.icns</string>
<key>CFBundleDisplayName</key><string>$DISPLAY_NAME</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST

# Render the original bow-and-arrow brand as a native macOS .icns.
# Keep intermediates outside the project; iconutil requires an .iconset folder.
ICON_TEMP="$(mktemp -d)"
trap 'rm -rf "$ICON_TEMP"' EXIT
BASE_ICON="$ICON_TEMP/arash-1024.png"
ICON_SET="$ICON_TEMP/ArashKam.iconset"
mkdir -p "$ICON_SET"
swift scripts/create-app-icon.swift "$BASE_ICON"
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" "$BASE_ICON" \
    --out "$ICON_SET/icon_${size}x${size}.png" >/dev/null
  twice=$((size * 2))
  sips -z "$twice" "$twice" "$BASE_ICON" \
    --out "$ICON_SET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICON_SET" -o "$APP/Contents/Resources/AppIcon.icns"

codesign --force --sign - "$APP"
echo "Created $APP ($BUNDLE_ID, ad-hoc signed; not notarized)"
if [[ "$BUNDLE_ID" == "com.arashkam.reader.qa" ]]; then
  echo "QA library: ~/Library/Application Support/ArashKamQA/GanjoorData/"
  echo "QA preferences are stored under the separate bundle ID."
fi
