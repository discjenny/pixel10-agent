#!/system/bin/sh
# Magisk service: restore iptables profiles and select default at boot

MODDIR=${0%/*}

# Optional kill switch
[ -f /data/adb/service.d/.fw-disable ] && exit 0
[ -f "$MODDIR/.fw-disable" ] && exit 0

# Where profiles live (Magisk-owned). Create if missing.
V4_DIR="/data/adb/firewall/v4"
V6_DIR="/data/adb/firewall/v6"
mkdir -p "$V4_DIR" "$V6_DIR"

# Default profile selection
DEFAULT_PROFILE="FW_LOCKED"
if [ -f /data/adb/firewall/default_profile ]; then
  dp=$(head -n1 /data/adb/firewall/default_profile 2>/dev/null | tr -d '\r' | tr -dc 'A-Z_')
  case "$dp" in
    FW_HOME|FW_AI|FW_LOCKED) DEFAULT_PROFILE="$dp" ;;
  esac
fi

# Create chains if missing
for CH in FW_ACTIVE FW_HOME FW_AI FW_LOCKED; do
  iptables -N $CH 2>/dev/null || true
  if command -v ip6tables >/dev/null 2>&1; then
    ip6tables -N $CH 2>/dev/null || true
  fi
done

# Ensure OUTPUT -> FW_ACTIVE at position 1
iptables -C OUTPUT -j FW_ACTIVE 2>/dev/null || iptables -I OUTPUT 1 -j FW_ACTIVE
if command -v ip6tables >/dev/null 2>&1; then
  ip6tables -C OUTPUT -j FW_ACTIVE 2>/dev/null || ip6tables -I OUTPUT 1 -j FW_ACTIVE
fi

# Default-deny new connections
iptables -P OUTPUT DROP
if command -v ip6tables >/dev/null 2>&1; then
  ip6tables -P OUTPUT DROP
fi

# Helper: load one profile file into chain
load_chain() {
  fam="$1"; chain="$2"; file="$3"
  [ -f "$file" ] || return 0
  case "$fam" in
    v4) ipt=iptables ;;
    v6) ipt=ip6tables ;;
  esac
  $ipt -F "$chain"
  while IFS= read -r l; do
    [ -z "$l" ] && continue
    printf '%s\n' "$l" | grep -qE "^-A[[:space:]]+$chain([[:space:]]|$)" || continue
    $ipt $l
  done < "$file"
}

# Load all profiles from disk (if present)
for CH in FW_HOME FW_AI FW_LOCKED; do
  [ -f "$V4_DIR/${CH}.rules" ] && load_chain v4 "$CH" "$V4_DIR/${CH}.rules"
  if command -v ip6tables >/dev/null 2>&1 && [ -f "$V6_DIR/${CH}.rules" ]; then
    load_chain v6 "$CH" "$V6_DIR/${CH}.rules"
  fi
done

# Select default profile
iptables -F FW_ACTIVE
iptables -A FW_ACTIVE -j "$DEFAULT_PROFILE"
if command -v ip6tables >/dev/null 2>&1; then
  ip6tables -F FW_ACTIVE
  ip6tables -A FW_ACTIVE -j "$DEFAULT_PROFILE"
fi

exit 0
