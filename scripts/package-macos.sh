#!/bin/bash
set -euo pipefail
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This packaging script must be run on macOS." >&2
  exit 1
fi
cd "$(dirname "$0")/.."
swift build -c release --product ArashKam
BIN_DIR="$(swift build -c release --show-bin-path)"
APP="$PWD/dist/ArashKam.app"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN_DIR/ArashKam" "$APP/Contents/MacOS/ArashKam"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>ArashKam</string>
<key>CFBundleIdentifier</key><string>com.arashkam.reader</string>
<key>CFBundleName</key><string>Arash Kamangir</string>
<key>CFBundleDisplayName</key><string>آرش کمانگیر</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$APP"
echo "Created $APP (ad-hoc signature; not notarized)"
