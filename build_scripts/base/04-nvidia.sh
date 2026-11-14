#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-$(rpm -E %fedora)}"
KERNEL_VERSION="${KERNEL_VERSION:-$(rpm -q --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' kernel | head -n 1)}"

AKMODS_NV_IMAGE_DIR="/tmp/akmods-nv-image"
AKMODNV_PATH="/tmp/akmods-rpms"
rm -rf "${AKMODS_NV_IMAGE_DIR}" "${AKMODNV_PATH}"
mkdir -p "${AKMODS_NV_IMAGE_DIR}" "${AKMODNV_PATH}"

skopeo copy --retry-times 3 \
	"docker://ghcr.io/ublue-os/akmods-nvidia-open:main-${FEDORA_MAJOR_VERSION}-${KERNEL_VERSION}" \
	"dir:${AKMODS_NV_IMAGE_DIR}"

NV_TARGZ="$(jq -r '.layers[].digest' "${AKMODS_NV_IMAGE_DIR}/manifest.json" | head -n 1 | cut -d : -f 2)"
tar -xzf "${AKMODS_NV_IMAGE_DIR}/${NV_TARGZ}" -C /tmp/
mv /tmp/rpms/* "${AKMODNV_PATH}/"

dnf5 config-manager setopt excludepkgs=golang-github-nvidia-container-toolkit 2>/dev/null || true

export IMAGE_NAME="${BASE_IMAGE_NAME:-silverblue}"
export AKMODNV_PATH
export MULTILIB=0
"${AKMODNV_PATH}/ublue-os/nvidia-install.sh"

rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
ln -sf libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so

tee /usr/lib/bootc/kargs.d/00-nvidia.toml <<EOF
kargs = ["rd.driver.blacklist=nouveau", "modprobe.blacklist=nouveau", "nvidia-drm.modeset=1", "initcall_blacklist=simpledrm_platform_driver_init"]
EOF

if [[ -d /ctx/system_files/nvidia ]]; then
	rsync -rvKl /ctx/system_files/nvidia/ /
fi

systemctl enable ublue-nvidia-flatpak-runtime-sync.service 2>/dev/null || true

echo "::endgroup::"
