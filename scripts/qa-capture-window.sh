#!/bin/bash
set -euo pipefail
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This capture helper requires macOS." >&2
  exit 1
fi
if [[ "$#" -ne 1 || -z "$1" ]]; then
  echo "Usage: bash scripts/qa-capture-window.sh /path/to/screenshot.png" >&2
  exit 2
fi
cd "$(dirname "$0")/.."
APP="$PWD/dist/ArashKam-QA.app"
if [[ ! -d "$APP" ]]; then
  echo "First run: bash scripts/package-macos.sh --qa" >&2
  exit 1
fi

# Activate this bundle, not the currently active unrelated application.
open -a "$APP"
sleep 1
WINDOW_ID="$(swift scripts/qa-window-id.swift)"
OUT="$1"
mkdir -p "$(dirname "$OUT")"
screencapture -x -l "$WINDOW_ID" "$OUT"

# A zero-byte file or failed decoder must never count as capture evidence.
test -s "$OUT"
sips -g pixelWidth -g pixelHeight "$OUT" >/dev/null
echo "Captured QA window $WINDOW_ID to: $OUT"
echo "Review the PNG visually before treating it as valid evidence."
