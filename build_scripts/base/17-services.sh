#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

systemctl enable podman.socket

# Homebrew (ublue-os/brew) services
systemctl preset brew-setup.service 2>/dev/null || true
systemctl preset brew-update.timer 2>/dev/null || true
systemctl preset brew-upgrade.timer 2>/dev/null || true

# NVIDIA (only if present)
systemctl enable ublue-nvidia-flatpak-runtime-sync.service 2>/dev/null || true

echo "::endgroup::"
