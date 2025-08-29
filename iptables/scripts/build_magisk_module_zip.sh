#!/usr/bin/env bash
set -euo pipefail

MOD_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/magisk-module"
OUT_ZIP="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/iptables-firewall-magisk.zip"

cd "$MOD_DIR"
zip -qr9 "$OUT_ZIP" .
echo "[+] Built $OUT_ZIP"
