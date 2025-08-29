# Magisk Module: Firewall Profiles (iptables)

This module loads iptables profiles at boot from `/data/adb/firewall/{v4,v6}` and selects the active chain via `FW_ACTIVE`. It pairs with the scripts under `iptables/` for authoring and pushing profiles.

Contents

- module.prop: Module metadata
- post-fs-data.sh: Creates `/data/adb/firewall/{v4,v6}`
- service.sh: Boot-time loader; creates chains, sets OUTPUT->FW_ACTIVE, policy DROP, loads profiles, selects default
- install.sh: Minimal installer to set permissions

Build & Install

- Build zip:
  - `bash magisk/build_firewall_module_zip.sh`
- Install:
  - In Magisk app → Modules → Install from storage → select `firewall-magisk.zip`
  - Reboot

All-in-One (host)

- `bash iptables/scripts/aio_setup.sh --default FW_LOCKED --reboot`
  - Validates profiles, pushes them, builds the module zip, attempts CLI install, sets default, and reboots.

Usage

- Default profile: creates `FW_ACTIVE -> FW_LOCKED` at boot.
- Override default: create file `/data/adb/firewall/default_profile` with one of `FW_HOME`, `FW_AI`, or `FW_LOCKED`.
- Manage profiles from host:
  - `bash iptables/scripts/push_profiles.sh` (syncs to `/data/adb/firewall/{v4,v6}`)
  - `bash iptables/scripts/test_apply.sh` (dry-run validate)

Notes

- Kill switch: create `/data/adb/service.d/.fw-disable` or `/data/adb/modules/iptables-firewall/.fw-disable` to skip the loader.
- If your ROM still blocks iptables at boot, we can add a `sepolicy.rule` to the module; tell me and I’ll tailor rules for your device.
