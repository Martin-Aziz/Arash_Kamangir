#!/usr/bin/env python3
"""Read-only manuscript design handoff check; no third-party packages needed."""
from pathlib import Path
import json
import sys
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
folder = root / "assets" / "templates"
manifest = json.loads((folder / "template-tokens.json").read_text("utf-8"))
assert manifest["version"] == 1
expected = {"royalLapis", "shirazGarden", "moonlitDiwan"}
ids = {item["id"] for item in manifest["templates"]}
assert ids == expected, f"Unexpected manuscript IDs: {sorted(ids)}"

native = (root / "Sources/ArashKam/PersianManuscriptTemplates.swift").read_text("utf-8")
reader = (root / "Sources/ArashKam/IlluminatedReaderView.swift").read_text("utf-8")
settings = (root / "Sources/ArashKam/ArashKamApp.swift").read_text("utf-8")
keepsake = (root / "Sources/ArashKam/PoetryKeepsake.swift").read_text("utf-8")

for identifier in expected:
    assert f"case {identifier}" in native, f"{identifier} missing from SwiftUI enum"
    assert identifier in native, f"{identifier} native design missing"

assert "PersianIlluminatedHeadpiece" in reader
assert "PersianIlluminatedFrame" in reader
assert "manuscriptTemplate" in settings
assert "PersianIlluminatedHeadpiece" in keepsake
assert "PersianIlluminatedFrame" in keepsake

svg_ns = "{http://www.w3.org/2000/svg}"
for item in manifest["templates"]:
    path = folder / item["asset"]
    assert path.is_file(), f"SVG missing: {path}"
    assert path.parent == folder, "No assets outside the template directory"
    raw = path.read_text("utf-8")
    assert "<!DOCTYPE" not in raw and "<!ENTITY" not in raw
    assert "<script" not in raw.lower() and "<foreignObject" not in raw
    assert "http://" not in raw.replace("http://www.w3.org/2000/svg", "")
    assert "https://" not in raw
    svg = ET.fromstring(raw)
    assert svg.tag == svg_ns + "svg", f"Not an SVG root: {path}"
    assert svg.attrib.get("viewBox") == "0 0 900 360"
    assert len(list(svg.iter())) >= 100, f"Too sparse for illustration: {path}"
    print("PASS", item["id"], "—", path.relative_to(root))

print("PASS native template wiring, selection persistence and SVG handoff metadata")
print("NOTE: This static source check does not certify macOS rendering, fonts, VoiceOver or visual fidelity.")
