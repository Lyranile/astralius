#!/usr/bin/env bash
set -eoux pipefail

rm -f /usr/lib/systemd/system/flatpak-add-fedora-repos.service

VERSION_ID=$(sed -n 's/^VERSION_ID=//p' /etc/os-release | tr -d '"')
VERSION_CODENAME=$(sed -n 's/^VERSION_CODENAME=//p' /etc/os-release | tr -d '"')
echo "Astralius release $VERSION_ID ($VERSION_CODENAME)" >/etc/system-release

find /mnt -mindepth 1 -delete 2>/dev/null || true
install -d -m 0755 /mnt
