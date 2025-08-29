#!/usr/bin/env bash
set -euo pipefail

PROFILE="${1:-}"
case "$PROFILE" in
  FW_HOME|FW_AI|FW_LOCKED) :;;
  *) echo "usage: $(basename "$0") <FW_HOME|FW_AI|FW_LOCKED>" >&2; exit 2;;
esac

adb get-state >/dev/null
adb shell su -c 'id -u' | grep -q '^0$' || { echo "[!] Need root (su)"; exit 1; }

adb shell su -c "mkdir -p /data/adb/firewall && printf '%s\n' '$PROFILE' > /data/adb/firewall/default_profile"
echo "[+] Default profile set to $PROFILE (applies on next boot)"
