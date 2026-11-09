#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

dnf makecache --refresh

# GNOME/Silverblue base already ships GNOME; install a small set of extras.
FEDORA_PACKAGES=(
    fastfetch
    fish
    fzf
    git-credential-libsecret
    gum
    htop
    just
    lm_sensors
    nvtop
    pam-u2f
    powertop
    rclone
    restic
    symlinks
    tcpdump
    tmux
    traceroute
    vim
    zsh
)

dnf -y install \
  --setopt=install_weak_deps=False \
  "${FEDORA_PACKAGES[@]}"

# Keep DX hook point (no-op here unless dx flavor)
if [[ "${IMAGE_FLAVOR:-}" == "dx" ]]; then
  /ctx/build_scripts/dx/00-dx.sh 2>/dev/null || true
fi

echo "::endgroup::"
