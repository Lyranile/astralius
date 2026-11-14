#!/usr/bin/bash
set -eoux pipefail

dnf makecache --refresh

FEDORA_PACKAGES=(
  adw-gtk3-theme
  bibata-cursor-theme
  fastfetch
  file-roller-nautilus
  git
  git-credential-libsecret
  nautilus
  nautilus-extensions
  papirus-icon-theme
  plymouth
  polkit
  qt6ct
  sushi
  zsh
)

dnf -y install \
  --setopt=install_weak_deps=False \
  "${FEDORA_PACKAGES[@]}"

# Remove unwanted preinstalled apps/sessions from base image
dnf -y remove firefox gnome-classic-session 2>/dev/null || true

if [[ "${IMAGE_FLAVOR:-}" == "dx" ]]; then
  /ctx/build_scripts/dx/00-dx.sh 2>/dev/null || true
fi
