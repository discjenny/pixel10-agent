# Magisk Modules on This Device — Practical Notes

These are distilled lessons from building and deploying a simple iptables firewall Magisk module on this device. They should help future module work “just work” without trial-and-error.

## Context & Constraints

- SELinux domains matter: `adb shell su -c ...` often runs in a domain that lacks `CAP_NET_ADMIN`/netfilter permissions. Commands like `iptables` can fail with EPERM even as UID 0.
- Boot-time context via Magisk: Scripts executed by Magisk (`post-fs-data.sh`, `service.sh`) run in a friendlier context and typically have the needed kernel permissions.
- Paths under `/data/adb` are Magisk-owned and safer. Avoid writing configs under `/data/local/...` when possible due to SELinux.

## Module Layout That Works

- `module.prop`: Must include stable `id` (folder name under `/data/adb/modules/<id>`), `name`, `version`, and `versionCode`.
- `service.sh`: Runs late at boot; do the main work here. Make it idempotent and tolerant of partial state.
- `post-fs-data.sh`: Prepare directories early and install tiny helpers (e.g., copy switcher to `/data/local/bin` and `chmod 755`).
- `install.sh`: Ensure the installer actually extracts payload files:
  - Use `unzip -o "$ZIPFILE" -x 'META-INF/*' -d "$MODPATH"`.
  - Set permissions with `set_perm`/`set_perm_recursive` for `service.sh` and `post-fs-data.sh`.
- `SKIPMOUNT=true`: We didn’t need overlay mounts for this module.
- Keep all module sources in-repo under a single folder (we used `iptables/magisk-module`) for clarity.

## Installing Reliably

- Preferred: Magisk GUI or CLI with a zip staged on-device.
  - Build zip on host, push to a safe temp path: `/data/local/tmp/module.zip`.
  - Install via CLI: `su -c 'magisk --install-module /data/local/tmp/module.zip'`.
  - Magisk stages under `/data/adb/modules_update/<id>` and finalizes to `/data/adb/modules/<id>` on reboot.
- Avoid direct writes to `/data/adb/modules/...` from `adb shell su` — commonly blocked by SELinux (chmod/mkdir/cp can fail).

## Storing Module Data

- Use `/data/adb/<module-data>` for persistent data/config managed by your module (e.g., `/data/adb/firewall/{v4,v6}` for profile files).

## Script Practices (service.sh)

- Be idempotent:
  - Create chains with `-N ... || true` and flush before replaying rules.
  - Insert jumps with `-C` checks, e.g., `iptables -C OUTPUT -j FW_ACTIVE || iptables -I OUTPUT 1 -j FW_ACTIVE`.
- Handle IPv6 conditionally: gate all `ip6tables` calls behind `command -v ip6tables`.
- Default drop policy: set `-P OUTPUT DROP` for both families if applicable.
- Robust parsing: avoid `\b` in busybox/toybox grep; use `([[:space:]]|$)` when matching line starts like `^-A <CHAIN>`.
- Kill-switch: honor a file like `/data/adb/service.d/.fw-disable` to skip on boot.

## Helper Installation (post-fs-data.sh)

- Install a small utility to `/data/local/bin` (e.g., `fw_switch_active.sh`) and `chmod 755` it there.
- Keep helpers self-contained and tolerant of missing chains (create as needed).

## Validation & Push (host-side)

- Dry-run validator: push rule files to a temp dir and attempt to apply into temporary chains (e.g., `FW_TEST_*`), then clean up. This catches syntax/compat issues safely.
- Push flow: validate → push profiles to `/sdcard` → move as root to `/data/adb/<data-dir>`.

## Troubleshooting Checklist

- Module presence: `ls -l /data/adb/modules/<id>`; confirm `service.sh` and `post-fs-data.sh` exist and are executable.
- First-run apply: If unsure, run `sh /data/adb/modules/<id>/service.sh` manually and check for errors.
- Expected iptables state:
  - `iptables -C OUTPUT -j FW_ACTIVE` succeeds.
  - `iptables -S FW_ACTIVE` shows a jump to your default profile (e.g., `FW_LOCKED`).
  - `iptables -S | grep '^-P OUTPUT DROP'` matches for IPv4 (and IPv6 if available).
- If still blocked at boot: your ROM’s SELinux may restrict netfilter even in Magisk’s context. Consider a `sepolicy.rule` tailored to netfilter (as a last resort).

## Patterns That Didn’t Work Well Here

- Interactive `adb shell su -c iptables ...`: often fails even as root due to SELinux domain restrictions.
- Direct chmod/mkdir/cp under `/data/adb/modules` from `adb shell su`: commonly denied by policy.
- Writing configs under `/data/local/...`: sporadic SELinux denies; prefer `/data/adb`.

## Suggested Workflow (Host)

- Edit profiles under the repo, then run one command:
  - `bash iptables/scripts/aio_setup.sh --default FW_LOCKED --reboot`
  - This validates, pushes profiles, builds the module zip, installs via Magisk CLI, sets default, and reboots.
- On-device, use the switcher anytime:
  - `su -c /data/local/bin/fw_switch_active.sh FW_HOME`

---

These conventions have made modules reproducible on this device without fighting SELinux. If a future ROM changes policy, prefer adjusting the module (e.g., add `sepolicy.rule`) over reintroducing interactive shell steps.

