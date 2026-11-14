#!/usr/bin/env bash
set -eoux pipefail

systemctl disable tailscaled.service 2>/dev/null || true
systemctl disable brew-upgrade.timer 2>/dev/null || true
systemctl disable brew-update.timer 2>/dev/null || true
systemctl disable brew-setup.service 2>/dev/null || true
systemctl disable uupd.timer 2>/dev/null || true
systemctl disable ublue-system-setup.service 2>/dev/null || true
systemctl disable flatpak-preinstall.service 2>/dev/null || true
systemctl --global disable podman-auto-update.timer 2>/dev/null || true
systemctl --global disable ublue-user-setup.service 2>/dev/null || true

rm -f /usr/share/applications/dev.getaurora.system-update.desktop
