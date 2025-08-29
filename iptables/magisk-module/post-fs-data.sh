#!/system/bin/sh
# Prepare firewall profile directories early and install switcher

MODDIR=${0%/*}

mkdir -p /data/adb/firewall/v4 /data/adb/firewall/v6

# Install/refresh switcher to a convenient path
if [ -f "$MODDIR/fw_switch_active.sh" ]; then
  cp -p "$MODDIR/fw_switch_active.sh" /data/local/bin/fw_switch_active.sh 2>/dev/null || cp "$MODDIR/fw_switch_active.sh" /data/local/bin/fw_switch_active.sh
  chmod 755 /data/local/bin/fw_switch_active.sh 2>/dev/null || true
fi

exit 0
