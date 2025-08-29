# Android iptables Firewall Profiles

This folder implements the layout and scripts from `../instructions.md` to manage multiple iptables profiles on a rooted Android device (Magisk), with boot‑time restore and an easy on‑device profile switcher.

Structure

- profiles/v4 and profiles/v6: Edit `FW_HOME.rules`, `FW_AI.rules`, `FW_LOCKED.rules`.
- scripts/push_profiles.sh: Sync profiles to `/data/adb/firewall/{v4,v6}` (Magisk‑owned).
- scripts/test_apply.sh: Dry‑run validate rules on device.
- scripts/aio_setup.sh: One‑command build+push+install (Magisk module) workflow.
- extras (optional): On‑device switcher moved to `iptables/_extras`.

Quickstart

- AIO (recommended): `bash iptables/scripts/aio_setup.sh --default FW_LOCKED --reboot`
- Manual:
  - Edit: `iptables/profiles/{v4,v6}/*.rules` (adjust UIDs)
  - Validate: `bash iptables/scripts/test_apply.sh`
  - Push: `bash iptables/scripts/push_profiles.sh`
  - Build module: `bash magisk/build_firewall_module_zip.sh`
  - Install zip in Magisk app → reboot
  - Set default for next boot: `bash iptables/scripts/set_default_profile.sh FW_HOME`

Notes

- Requires: adb, rooted device (Magisk), busybox/toybox iptables.
- Kill switch: create `/data/adb/service.d/.fw-disable` to skip boot restore.
- Profiles are stored under Magisk: `/data/adb/firewall/{v4,v6}`. The Magisk module loads them at boot.
