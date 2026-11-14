#!/usr/bin/bash

set -exo pipefail

{ export PS4='+( ${BASH_SOURCE}:${LINENO} ): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'; } 2>/dev/null

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$(realpath /root)"

mount -o remount,rw /proc/sys

if [[ -f "$SCRIPT_DIR/flatpaks.list" ]]; then
	echo "Installing flatpaks..."
	curl --retry 3 -Lo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo
	xargs -r flatpak install -y --noninteractive <"$SCRIPT_DIR/flatpaks.list" || true
	rm -rf /flatpak-list
	flatpak list --columns=runtime,app
fi

if [[ -n "${BASE_IMAGE:-}" ]]; then
	podman pull "${BASE_IMAGE}"
else
	IMAGE_INFO="$(cat /usr/share/ublue-os/image-info.json)"
	IMAGE_TAG="$(jq -c -r '."image-tag"' <<<"$IMAGE_INFO")"
	IMAGE_REF="$(jq -c -r '."image-ref"' <<<"$IMAGE_INFO")"
	IMAGE_REF="${IMAGE_REF##*://}"
	podman pull "${IMAGE_REF}:${IMAGE_TAG}"
fi

ANACONDA=(
	anaconda-live
	anaconda-webui
	pykickstart
)

dnf install -y \
	dracut-live \
	livesys-scripts \
	git \
	jq \
	rsync \
	desktop-file-utils \
	libblockdev-btrfs \
	libblockdev-lvm \
	libblockdev-dm \
	"${ANACONDA[@]}"

kernel=$(find /usr/lib/modules -maxdepth 1 -type d -printf '%P\n' | grep . | head -1)
DRACUT_NO_XATTR=1 dracut -v --force --zstd --reproducible --no-hostonly \
	--add "dmsquash-live dmsquash-live-autooverlay" \
	"/usr/lib/modules/${kernel}/initramfs.img" "${kernel}"

# GNOME live session
sed -i "s/^livesys_session=.*/livesys_session=gnome/" /etc/sysconfig/livesys
systemctl enable livesys.service livesys-late.service

export BASE_IMAGE="${BASE_IMAGE:-}"
bash \
	"$SCRIPT_DIR/undo-image.sh" &&
	"$SCRIPT_DIR/flatpak-mount-workaround.sh" &&
	"$SCRIPT_DIR/gnome-tweaks.sh" &&
	"$SCRIPT_DIR/workarounds.sh" &&
	"$SCRIPT_DIR/configure_iso_anaconda.sh" &&
	"$SCRIPT_DIR/smoke-tests.sh"

_arch=$(uname -m)
if [[ $_arch == "x86_64" ]]; then
	dnf install -y grub2-efi-x64-cdboot
elif [[ $_arch == "aarch64" ]]; then
	dnf install -y grub2-efi-aa64-modules
fi

mkdir -p /boot/efi
cp -av /usr/lib/efi/*/*/EFI /boot/efi/ 2>/dev/null || true

_arch=$(uname -m)
if [[ $_arch == "x86_64" ]]; then
	cp -v /boot/efi/EFI/fedora/grubx64.efi /boot/efi/EFI/BOOT/fbx64.efi 2>/dev/null || true
elif [[ $_arch == "aarch64" ]]; then
	cp -v /boot/efi/EFI/fedora/grubaa64.efi /boot/efi/EFI/BOOT/fbaa64.efi 2>/dev/null || true
fi

rm -f /etc/localtime
systemd-firstboot --timezone UTC

mkdir -p /var/tmp
cat >/etc/systemd/system/var-tmp.mount <<'EOF'
[Unit]
Description=Larger tmpfs for /var/tmp on live system

[Mount]
What=tmpfs
Where=/var/tmp
Type=tmpfs
Options=size=50%,nr_inodes=1m,x-systemd.graceful-option=usrquota

[Install]
WantedBy=local-fs.target
EOF
systemctl enable var-tmp.mount

mkdir -p /usr/lib/bootc-image-builder
cp "$SCRIPT_DIR/iso.yaml" /usr/lib/bootc-image-builder/iso.yaml

dnf clean all
