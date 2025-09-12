#!/usr/bin/env bash
set -euo pipefail

# Generate HuntScope/StreamPresets.json from Config/urls_plain.txt with XOR+Base64 obfuscation.
# - Increments version on rebuild
# - Adds generatedAt (ISO8601Z)
# - Skips invalid URLs (warns)
# - Rebuilds if urls_plain.txt is newer than generatedAt in existing JSON

SRCROOT_DIR="${SRCROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
INPUT_TXT="$SRCROOT_DIR/Config/urls_plain.txt"
OUTPUT_JSON="$SRCROOT_DIR/HuntScope/StreamPresets.json"

# 16-byte key (duplicate in Obfuscation.swift)
KEY_HEX="7f11a9235dc48bee0137492a6cd09e3b"

if [[ ! -f "$INPUT_TXT" ]]; then
  echo "[generate_stream_presets] Input not found: $INPUT_TXT" >&2
  exit 0
fi

# Small Python helper to compare mtime vs generatedAt and (re)generate JSON
PYTHON_BIN="${PYTHON:-$(command -v python3 || true)}"
if [[ -z "${PYTHON_BIN}" ]]; then
  echo "[generate_stream_presets] python3 not found; skipping" >&2
  exit 0
fi

"${PYTHON_BIN}" - << 'PY'
import os, sys, json, base64, binascii, time, datetime, re

SRCROOT = os.environ.get('SRCROOT')
if not SRCROOT:
    # Fallback: current working directory (Xcode sets SRCROOT normally)
    SRCROOT = os.getcwd()
INPUT_TXT = os.path.join(SRCROOT, 'Config', 'urls_plain.txt')
OUTPUT_JSON = os.path.join(SRCROOT, 'HuntScope', 'StreamPresets.json')
KEY_HEX = '7f11a9235dc48bee0137492a6cd09e3b'

def iso8601_now_z():
    return datetime.datetime.utcnow().replace(microsecond=0).isoformat() + 'Z'

def load_existing(path):
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception:
        return None

def parse_generated_at(existing):
    if not existing: return None
    ts = existing.get('generatedAt')
    if not ts: return None
    try:
        if ts.endswith('Z'):
            ts = ts[:-1] + '+00:00'
        dt = datetime.datetime.fromisoformat(ts)
        return int(dt.timestamp())
    except Exception:
        return None

def url_is_valid(u: str) -> bool:
    # Minimal check: must start with rtsp:// or rtsps:// and contain at least one slash after host
    if not (u.startswith('rtsp://') or u.startswith('rtsps://')):
        return False
    # crude: require something after scheme and '://'
    return len(u) > len('rtsp://') and '/' in u[len('rtsp://'):]

def xor_bytes(data: bytes, key: bytes) -> bytes:
    out = bytearray(len(data))
    for i, b in enumerate(data):
        out[i] = b ^ key[i % len(key)]
    return bytes(out)

key = binascii.unhexlify(KEY_HEX)
existing = load_existing(OUTPUT_JSON)
existing_ver = int(existing.get('version', 0)) if existing else 0
existing_gen = parse_generated_at(existing)

input_mtime = int(os.path.getmtime(INPUT_TXT))

def needs_rebuild():
    if not existing:
        return True
    if not existing_gen:
        return True
    return input_mtime > existing_gen

if not needs_rebuild():
    print('[generate_stream_presets] Up to date; skip')
    sys.exit(0)

# Build list
presets = []
with open(INPUT_TXT, 'r', encoding='utf-8') as f:
    for ln, line in enumerate(f, 1):
        s = line.strip()
        if not s or s.startswith('#'):
            continue
        if not url_is_valid(s):
            print(f"[generate_stream_presets] Warning: invalid URL at line {ln}: {s}", file=sys.stderr)
            continue
        obf = xor_bytes(s.encode('utf-8'), key)
        b64 = base64.b64encode(obf).decode('ascii')
        presets.append(b64)

new_ver = existing_ver + 1 if existing else 1
doc = {
    'version': new_ver,
    'generatedAt': iso8601_now_z(),
    'presets': presets,
}

os.makedirs(os.path.dirname(OUTPUT_JSON), exist_ok=True)
with open(OUTPUT_JSON, 'w', encoding='utf-8') as f:
    json.dump(doc, f, indent=2, sort_keys=True)
    f.write('\n')

print(f"[generate_stream_presets] Wrote {OUTPUT_JSON} (version {new_ver}, {len(presets)} entries)")
PY

exit 0
