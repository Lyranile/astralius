#!/usr/bin/bash
# Prepare the build environment for Astralius (GNOME/Silverblue based)

set -eoux pipefail

cp /etc/dnf/dnf.conf /etc/dnf/dnf.conf.bak
dnf config-manager setopt keepcache=1 timeout=60

dnf config-manager setopt fedora-multimedia.priority=90
dnf config-manager disable fedora-cisco-openh264
