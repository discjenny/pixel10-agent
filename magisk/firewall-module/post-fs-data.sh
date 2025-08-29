#!/system/bin/sh
# Prepare firewall profile directories early
mkdir -p /data/adb/firewall/v4 /data/adb/firewall/v6
chmod 755 /data/adb/firewall 2>/dev/null || true
chmod 755 /data/adb/firewall/v4 2>/dev/null || true
chmod 755 /data/adb/firewall/v6 2>/dev/null || true
exit 0
