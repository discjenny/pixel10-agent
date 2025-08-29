#!/usr/bin/env bash
set -euo pipefail

# Validates iptables rule files by attempting to load them into
# temporary chains on the device (no persistent changes made).

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
V4_DIR="$ROOT/profiles/v4"
V6_DIR="$ROOT/profiles/v6"

die(){ echo "[!] $*" >&2; exit 1; }
ok(){ echo "[+] $*"; }

adb get-state >/dev/null || die "No device connected"
adb shell su -c 'id -u' | grep -q '^0$' || die "Root (su) not available on device"

# Ensure local v4 profiles exist
for f in FW_HOME.rules FW_AI.rules FW_LOCKED.rules; do
  [[ -f "$V4_DIR/$f" ]] || die "Missing $V4_DIR/$f"
done

# Prepare a staging dir on /sdcard, then move to /data/local/tmp (root-owned)
STAGE_SD="/sdcard/fwtest"
STAGE_DEV="/data/local/tmp/fwtest"

adb shell rm -rf "$STAGE_SD" >/dev/null 2>&1 || true
adb shell mkdir -p "$STAGE_SD/v4" >/dev/null
for f in FW_HOME.rules FW_AI.rules FW_LOCKED.rules; do
  adb push "$V4_DIR/$f" "$STAGE_SD/v4/$f" >/dev/null
done

# Push v6 if ip6tables exists and local files present
HAS_V6=0
if adb shell su -c 'command -v ip6tables >/dev/null'; then
  for f in FW_HOME.rules FW_AI.rules FW_LOCKED.rules; do
    [[ -f "$V6_DIR/$f" ]] || die "Missing $V6_DIR/$f"
  done
  adb shell mkdir -p "$STAGE_SD/v6" >/dev/null
  for f in FW_HOME.rules FW_AI.rules FW_LOCKED.rules; do
    adb push "$V6_DIR/$f" "$STAGE_SD/v6/$f" >/dev/null
  done
  HAS_V6=1
else
  echo "[*] ip6tables not present; skipping IPv6 validation"
fi

# Device-side runner script that attempts to apply rules into temp chains
RUN_SD="/sdcard/fwtest_runner.sh"
RUN_DEV="/data/local/tmp/fwtest_runner.sh"

cat > /tmp/fwtest_runner.sh <<'EOS'
#!/system/bin/sh
set -eu

STAGE_DEV="/data/local/tmp/fwtest"

test_family() {
  fam="$1"; ipt="$2"; dir="$3"
  for CH in FW_HOME FW_AI FW_LOCKED; do
    file="$dir/${CH}.rules"
    [ -f "$file" ] || continue
    TMP="FW_TEST_${CH}"
    $ipt -N "$TMP" 2>/dev/null || true
    $ipt -F "$TMP"
    while IFS= read -r l; do
      [ -z "$l" ] && continue
      # Only consider rules that append to the expected chain
      printf '%s\n' "$l" | grep -qE "^-A[[:space:]]+$CH([[:space:]]|$)" || continue
      # Substitute the target chain with the temporary chain
      l1=$(printf '%s\n' "$l" | sed -E "s/^(-A[[:space:]]+)$CH([[:space:]]|$)/\1$TMP\2/")
      if ! $ipt $l1 2>/dev/null; then
        echo "[FAIL] $fam $CH -> $l" >&2
        exit 20
      fi
    done < "$file"
    # cleanup temp chain
    $ipt -F "$TMP" 2>/dev/null || true
    $ipt -X "$TMP" 2>/dev/null || true
  done
  echo "[OK] $fam rules syntactically valid"
}

test_family v4 iptables "$STAGE_DEV/v4"
if command -v ip6tables >/dev/null 2>&1 && [ -d "$STAGE_DEV/v6" ]; then
  test_family v6 ip6tables "$STAGE_DEV/v6"
fi
exit 0
EOS

adb push /tmp/fwtest_runner.sh "$RUN_SD" >/dev/null
adb shell su -c "rm -rf '$STAGE_DEV'; mv '$STAGE_SD' '$STAGE_DEV'; mv '$RUN_SD' '$RUN_DEV'; chmod 700 '$RUN_DEV'" >/dev/null

set +e
adb shell su -c "$RUN_DEV"
rc=$?
set -e

# Cleanup
adb shell su -c "rm -rf '$STAGE_DEV' '$RUN_DEV'" >/dev/null
adb shell rm -f "$RUN_SD" >/dev/null 2>&1 || true

if [ $rc -eq 0 ]; then
  ok "Profile rules validated successfully"
else
  die "Validation failed (see messages above)"
fi
