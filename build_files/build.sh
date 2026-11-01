#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
dnf5 install -y tmux

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket

### NVIDIA (open drivers) via akmods-nvidia-open
# Mirrors the ublue-os/main / Bluefin approach: keep silverblue-main as the
# base and install NVIDIA on top of it instead of using a separate nvidia base.
FEDORA_MAJOR_VERSION="$(rpm -E %fedora)"
KERNEL_VERSION="$(rpm -q --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' kernel | head -n 1)"

AKMODS_NV_IMAGE_DIR="/tmp/akmods-nv-image"
AKMODNV_PATH="/tmp/akmods-rpms"
rm -rf "${AKMODS_NV_IMAGE_DIR}" "${AKMODNV_PATH}"
mkdir -p "${AKMODS_NV_IMAGE_DIR}" "${AKMODNV_PATH}"

# Fetch the akmods-nvidia-open payload matching the kernel shipped in silverblue-main
skopeo copy --retry-times 3 \
    "docker://ghcr.io/ublue-os/akmods-nvidia-open:main-${FEDORA_MAJOR_VERSION}-${KERNEL_VERSION}" \
    "dir:${AKMODS_NV_IMAGE_DIR}"

NV_TARGZ="$(jq -r '.layers[].digest' "${AKMODS_NV_IMAGE_DIR}/manifest.json" | head -n 1 | cut -d : -f 2)"
tar -xzf "${AKMODS_NV_IMAGE_DIR}/${NV_TARGZ}" -C /tmp/
mv /tmp/rpms/* "${AKMODNV_PATH}/"

# Not available for Fedora 43 yet (Aurora approach)
dnf5 config-manager setopt excludepkgs=golang-github-nvidia-container-toolkit

# Install NVIDIA drivers + kmod (MULTILIB=0 keeps it minimal)
IMAGE_NAME="silverblue" \
AKMODNV_PATH="${AKMODNV_PATH}" \
MULTILIB=0 \
    "${AKMODNV_PATH}/ublue-os/nvidia-install.sh"

# Blacklist nouveau and set required kernel args for bootc
rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
ln -sf libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so

# Aurora enables this service for flatpak runtime sync
systemctl enable ublue-nvidia-flatpak-runtime-sync.service 2>/dev/null || true

mkdir -p /usr/lib/bootc/kargs.d
tee /usr/lib/bootc/kargs.d/00-nvidia.toml <<EOF
kargs = ["rd.driver.blacklist=nouveau", "modprobe.blacklist=nouveau", "nvidia-drm.modeset=1", "initcall_blacklist=simpledrm_platform_driver_init"]
EOF

# Rebuild initramfs so the forced NVIDIA module load takes effect
dracut --regenerate-all -f