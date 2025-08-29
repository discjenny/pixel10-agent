#!/usr/bin/env bash
set -euo pipefail

MOD_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/firewall-module" && pwd)"
OUT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OUT_ZIP="$OUT_DIR/firewall-magisk.zip"
ADB_BIN="${ADB:-adb}"

cd "$MOD_DIR"
zip -qr9 "$OUT_ZIP" .
echo "[+] Built $OUT_ZIP"

# Convenience: copy the zip to device storage for Magisk GUI install
if "$ADB_BIN" get-state >/dev/null 2>&1; then
  DEST_DIR="/sdcard/Download"
  # Fallback to /sdcard if Download doesn't exist or is not writable
  if ! "$ADB_BIN" shell "mkdir -p $DEST_DIR >/dev/null 2>&1"; then
    DEST_DIR="/sdcard"
  fi
  if "$ADB_BIN" push "$OUT_ZIP" "$DEST_DIR/" >/dev/null; then
    echo "[+] Copied to $DEST_DIR/firewall-magisk.zip"
    echo "    Open Magisk → Modules → Install from storage → $DEST_DIR/firewall-magisk.zip"
  else
    echo "[*] adb push failed; manually copy $OUT_ZIP to device storage" >&2
  fi
else
  echo "[*] No device detected via adb; built zip is at: $OUT_ZIP" >&2
fi
