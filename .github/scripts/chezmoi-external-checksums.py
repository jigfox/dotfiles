#!/usr/bin/env python3
"""Check the sha256 of every file in .chezmoiexternal.toml against its URL.

With --fix, write the checksums of what the URLs serve now (used on Renovate
branches, which bump the version in the URL but can't know the new checksum).
"""
import hashlib
import sys
import tomllib
import urllib.request
from pathlib import Path

path = Path(__file__).resolve().parents[2] / ".chezmoiexternal.toml"
text = path.read_text()
fix = "--fix" in sys.argv[1:]
mismatches = 0

for target, entry in tomllib.loads(text).items():
    expected = entry.get("checksum", {}).get("sha256")
    if entry.get("type") != "file" or not expected:
        continue
    with urllib.request.urlopen(entry["url"]) as response:
        actual = hashlib.sha256(response.read()).hexdigest()
    if actual == expected:
        print(f"ok        {target}")
        continue
    mismatches += 1
    print(f"mismatch  {target}: expected {expected}, {entry['url']} has {actual}")
    text = text.replace(expected, actual)

if fix:
    path.write_text(text)
elif mismatches:
    sys.exit(1)
