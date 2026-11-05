#!/bin/bash
# Optional read-only source check. This is NOT a GUI automation test.
set -euo pipefail
if ! command -v curl >/dev/null || ! command -v python3 >/dev/null; then
  echo "Requires curl and python3." >&2
  exit 2
fi
ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT
BASE="https://cdn.jsdelivr.net/gh/ganjoor/ganjoor-data@main"

for path in manifest.json poets/hafez/ghazal/_cat.json poets/hafez/ghazal/sh1.json poets/hafez/ghazal/sh2.json; do
  target="$ROOT/$path"
  mkdir -p "$(dirname "$target")"
  echo "Fetching $path"
  curl --fail --location --silent --show-error --retry 2 \
    --connect-timeout 10 --max-time 45 \
    --output "$target" "$BASE/$path"
done

python3 - "$ROOT" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
def load(relative):
    return json.loads((root / relative).read_text(encoding="utf-8"))

manifest = load("manifest.json")
assert any(p.get("FullUrl") == "/hafez" for p in manifest["Poets"]), "Hafez missing from manifest"
category = load("poets/hafez/ghazal/_cat.json")
assert category["FullUrl"] == "/hafez/ghazal"
entries = {p["FullUrl"]: p for p in category["Poems"]}
for number, ident in [(1, 2130), (2, 2131)]:
    path = f"/hafez/ghazal/sh{number}"
    poem = load(f"poets/hafez/ghazal/sh{number}.json")
    assert entries[path]["Id"] == ident, f"category ID mismatch: {path}"
    assert poem["Id"] == ident and poem["FullUrl"] == path, f"poem ID/path mismatch: {path}"
    assert poem["Title"] == entries[path]["Title"], f"title mismatch: {path}"
    print(f"PASS: {path} / ID {ident} / {poem['Title']}")
print("PASS: official Ganjoor manifest and Hafez poem 1/2 metadata")
PY
