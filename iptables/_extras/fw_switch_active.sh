#!/system/bin/sh
# usage: fw_switch_active.sh <FW_HOME|FW_AI|FW_LOCKED>
set -eu
PROFILE="${1:-}"; case "$PROFILE" in FW_HOME|FW_AI|FW_LOCKED) :;; *) echo "usage: $0 <FW_HOME|FW_AI|FW_LOCKED>" >&2; exit 2;; esac

iptables -F FW_ACTIVE 2>/dev/null || { iptables -N FW_ACTIVE; iptables -I OUTPUT 1 -j FW_ACTIVE; }
iptables -A FW_ACTIVE -j "$PROFILE"

if command -v ip6tables >/dev/null 2>&1; then
  ip6tables -F FW_ACTIVE 2>/dev/null || { ip6tables -N FW_ACTIVE; ip6tables -I OUTPUT 1 -j FW_ACTIVE; }
  ip6tables -A FW_ACTIVE -j "$PROFILE"
fi
echo "Active profile: $PROFILE"
