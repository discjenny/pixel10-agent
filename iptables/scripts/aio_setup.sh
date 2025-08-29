#!/usr/bin/env bash
set -euo pipefail

# All-in-one: validate -> push -> build module -> install -> set default -> optional reboot

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_PROFILE=""
REBOOT=0
VALIDATE=1
INSTALL=1

usage(){
  cat <<USAGE
Usage: $(basename "$0") [--default FW_HOME|FW_AI|FW_LOCKED] [--no-validate] [--no-install] [--reboot]
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --default)
      DEFAULT_PROFILE="${2:-}"; shift 2 ;;
    --no-validate)
      VALIDATE=0; shift ;;
    --no-install)
      INSTALL=0; shift ;;
    --reboot)
      REBOOT=1; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

die(){ echo "[!] $*" >&2; exit 1; }
ok(){ echo "[+] $*"; }

adb get-state >/dev/null || die "No device connected"
adb shell su -c 'id -u' | grep -q '^0$' || die "Root (su) not available on device"

if [ -n "$DEFAULT_PROFILE" ]; then
  case "$DEFAULT_PROFILE" in
    FW_HOME|FW_AI|FW_LOCKED) :;;
    *) die "--default must be one of FW_HOME|FW_AI|FW_LOCKED" ;;
  esac
fi

if [ $VALIDATE -eq 1 ]; then
  "$ROOT/scripts/test_apply.sh"
fi

"$ROOT/scripts/push_profiles.sh"

# Build Magisk module zip
bash "$ROOT/../magisk/build_firewall_module_zip.sh"

if [ $INSTALL -eq 1 ]; then
  ZIP_PATH="$ROOT/../magisk/firewall-magisk.zip"
  adb push "$ZIP_PATH" /sdcard/ >/dev/null
  if adb shell su -c 'command -v magisk >/dev/null 2>&1'; then
    echo "[*] Attempting module install via magisk CLI"
    if adb shell su -c 'magisk --install-module /sdcard/firewall-magisk.zip >/dev/null 2>&1'; then
      ok "Module install requested; reboot required"
    else
      echo "[!] magisk CLI failed; install zip manually in Magisk app" >&2
    fi
  else
    echo "[*] magisk CLI not found; install zip manually in Magisk app" >&2
  fi
fi

if [ -n "$DEFAULT_PROFILE" ]; then
  adb shell su -c "printf '%s\n' '$DEFAULT_PROFILE' > /data/adb/firewall/default_profile"
  ok "Default profile set to $DEFAULT_PROFILE"
fi

if [ $REBOOT -eq 1 ]; then
  adb reboot
  ok "Rebooting"
else
  echo "[i] Reboot to apply module and default profile"
fi
