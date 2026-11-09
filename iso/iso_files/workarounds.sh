#!/usr/bin/env bash
set -eoux pipefail

rm -f /usr/lib/systemd/system/flatpak-add-fedora-repos.service

. /etc/os-release
echo "Astralius release $VERSION_ID ($VERSION_CODENAME)" >/etc/system-release

rm -rf /mnt
mkdir -p -m 0755 /mnt
