#!/system/bin/sh
# Minimal Magisk module installer

SKIPMOUNT=true
PROPFILE=false
POSTFSDATA=true
LATESTARTSERVICE=true

print_modname() {
  ui_print "Firewall Profiles (iptables)"
}

on_install() {
  ui_print "- Extracting module files"
  # Extract everything except META-INF to the module path
  unzip -o "$ZIPFILE" -x 'META-INF/*' -d "$MODPATH" >/dev/null
}

set_permissions() {
  set_perm_recursive "$MODPATH" 0 0 0755 0644
  [ -f "$MODPATH/service.sh" ] && set_perm "$MODPATH/service.sh" 0 0 0755
  [ -f "$MODPATH/post-fs-data.sh" ] && set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
}
