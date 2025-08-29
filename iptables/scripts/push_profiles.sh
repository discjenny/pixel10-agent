#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
V4_DIR="$ROOT/profiles/v4"
V6_DIR="$ROOT/profiles/v6"

die(){ echo "[!] $*" >&2; exit 1; }
ok(){ echo "[+] $*"; }

adb get-state >/dev/null || die "No device"
adb shell su -c 'id -u' | grep -q '^0$' || die "No root (su)"

# Ensure local files exist
for f in FW_HOME.rules FW_AI.rules FW_LOCKED.rules; do
  [[ -f "$V4_DIR/$f" ]] || die "Missing $V4_DIR/$f"
done

# Validate profiles on device (dry-run) before pushing
echo "[*] Validating profiles before push..."
if ! "$ROOT/scripts/test_apply.sh"; then
  die "Validation failed; aborting push"
fi

TARGET_BASE="/data/adb/firewall"

# Create dirs on device (Magisk-owned area)
adb shell su -c 'mkdir -p /data/adb/firewall/v4 /data/adb/firewall/v6' >/dev/null

# Push v4 as .rules
for f in FW_HOME.rules FW_AI.rules FW_LOCKED.rules; do
  adb push "$V4_DIR/$f" "/sdcard/$f" >/dev/null
done
adb shell su -c 'mv /sdcard/FW_*.rules /data/adb/firewall/v4/'

# Push v6 if present on device and in repo (use .rules as well)
if adb shell su -c 'command -v ip6tables >/dev/null'; then
  for f in FW_HOME.rules FW_AI.rules FW_LOCKED.rules; do
    [[ -f "$V6_DIR/$f" ]] || die "Missing $V6_DIR/$f"
    adb push "$V6_DIR/$f" "/sdcard/$f" >/dev/null
  done
  adb shell su -c 'mv /sdcard/FW_*.rules /data/adb/firewall/v6/'
else
  echo "[*] ip6tables not present or unused; skipping v6 push."
fi

ok "Profiles synced to /data/adb/firewall/{v4,v6}."
