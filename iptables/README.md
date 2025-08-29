# Android iptables Firewall Profiles

This folder implements the layout and scripts from `../instructions.md` to manage multiple iptables profiles on a rooted Android device (Magisk), with boot‑time restore and an easy on‑device profile switcher.

Structure

- profiles/v4 and profiles/v6: Edit `FW_HOME.rules`, `FW_AI.rules`, `FW_LOCKED.rules`.
- scripts/push_profiles.sh: Sync profiles to `/data/adb/firewall/{v4,v6}` (validates first).
- scripts/test_apply.sh: Dry‑run validate rules on device.
- scripts/aio_setup.sh: One command to push + install Magisk module + set default.
- scripts/set_default_profile.sh: Set default profile for next boot.
- scripts/build_magisk_module_zip.sh: Build module zip artifact (optional).
- magisk-module/: Magisk module contents (service.sh, post-fs-data.sh, switcher).

Quickstart

- AIO (recommended): `bash iptables/scripts/aio_setup.sh --default FW_LOCKED --reboot`
  - Validates (via push), syncs profiles, installs/updates the module directly, sets default, and reboots.
- Manual:
  - Edit: `iptables/profiles/{v4,v6}/*.rules` (adjust UIDs)
  - Push (validates): `bash iptables/scripts/push_profiles.sh`
  - Direct-install module: `bash iptables/scripts/aio_setup.sh --no-install` (skips) then `bash iptables/scripts/build_magisk_module_zip.sh` if you just need the zip
  - Set default: `bash iptables/scripts/set_default_profile.sh FW_HOME` then reboot

Notes

- Requires: adb, rooted device (Magisk), busybox/toybox iptables.
- Kill switch: create `/data/adb/service.d/.fw-disable` to skip boot restore.
- Profiles live at `/data/adb/firewall/{v4,v6}`; module loads them at boot.
- Switcher: module installs `/data/local/bin/fw_switch_active.sh` for on-device switching.
