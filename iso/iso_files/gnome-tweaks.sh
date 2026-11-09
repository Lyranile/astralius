#!/usr/bin/env bash
set -eoux pipefail

# GNOME live environment tweaks
. /etc/os-release
echo "Astralius release $VERSION_ID ($VERSION_CODENAME)" >/etc/system-release

# disable screen lock on live session
mkdir -p /etc/dconf/db/local.d
cat >/etc/dconf/db/local.d/00-live <<'EOF'
[org/gnome/desktop/screensaver]
lock-enabled=false

[org/gnome/desktop/session]
idle-delay=0
EOF
dconf update 2>/dev/null || true

# systemd-tmpfiles --create --boot --root=/mnt/sysroot --prefix=/var/home fails
rm -rf /mnt
mkdir -p -m 0755 /mnt
