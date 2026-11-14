#!/usr/bin/env bash

set -eoux pipefail

if [[ -n "${BASE_IMAGE:-}" ]]; then
	IMAGE_REF="${BASE_IMAGE%%:*}"
	IMAGE_TAG="${BASE_IMAGE##*:}"
else
	IMAGE_INFO="$(cat /usr/share/ublue-os/image-info.json)"
	IMAGE_TAG="$(jq -c -r '."image-tag"' <<<"$IMAGE_INFO")"
	IMAGE_REF="$(jq -c -r '."image-ref"' <<<"$IMAGE_INFO")"
	IMAGE_REF="${IMAGE_REF##*://}"
fi

sed -i 's/ANACONDA_PRODUCTVERSION=.*/ANACONDA_PRODUCTVERSION=""/' /usr/{,s}bin/liveinst || true

mkdir -p /etc/anaconda/profile.d
tee /etc/anaconda/profile.d/astralius.conf <<'EOF'
# Anaconda configuration file for Astralius

[Profile]
profile_id = astralius

[Profile Detection]
os_id = astralius

[Network]
default_on_boot = FIRST_WIRED_WITH_LINK

[Bootloader]
efi_dir = fedora
menu_auto_hide = True

[Storage]
default_scheme = BTRFS
btrfs_compression = zstd:1
default_partitioning =
    /     (min 1 GiB, max 70 GiB)
    /home (min 500 MiB, free 50 GiB)
    /var  (btrfs)

[User Interface]
webui_web_engine = slitherer
hidden_spokes =
    NetworkSpoke
    PasswordSpoke
    UserSpoke
hidden_webui_pages =
    anaconda-screen-date-time
    anaconda-netowrk
    anaconda-screen-accounts
EOF

desktop-file-edit \
	--set-key=Icon --set-value=/usr/share/icons/hicolor/scalable/apps/org.gnome.Settings.svg \
	--set-key=StartupWMClass --set-value=slitherer \
	/usr/share/applications/liveinst.desktop 2>/dev/null || true

tee -a /usr/share/anaconda/interactive-defaults.ks <<EOF
ostreecontainer --url=$IMAGE_REF:$IMAGE_TAG --transport=containers-storage --no-signature-verification
%include /usr/share/anaconda/post-scripts/install-configure-upgrade.ks
%include /usr/share/anaconda/post-scripts/install-flatpaks.ks
%include /usr/share/anaconda/post-scripts/secureboot-enroll-key.ks
EOF

tee /usr/share/anaconda/post-scripts/install-configure-upgrade.ks <<EOF
%post --erroronfail
bootc switch --mutate-in-place --enforce-container-sigpolicy --transport registry $IMAGE_REF:$IMAGE_TAG
%end
EOF

tee /usr/share/anaconda/post-scripts/install-flatpaks.ks <<'EOF'
%post --erroronfail --nochroot
set -oue pipefail
deployment="$(ostree rev-parse --repo=/mnt/sysimage/ostree/repo ostree/0/1/0)"
target="/mnt/sysimage/ostree/deploy/default/deploy/$deployment.0/var/lib/"
mkdir -p "$target"
systemctl stop var-lib-flatpak.mount 2>/dev/null || true
rsync -aAXUHKP /var/lib/flatpak "$target"
sync
%end
EOF

tee /usr/share/anaconda/post-scripts/secureboot-enroll-key.ks <<'EOF'
%post --erroronfail --nochroot
set -oue pipefail

readonly ENROLLMENT_PASSWORD="universalblue"
readonly SECUREBOOT_KEY="/etc/pki/akmods/certs/akmods-ublue.der"

if [[ ! -d "/sys/firmware/efi" ]]; then
    echo "EFI mode not detected. Skipping key enrollment."
    exit 0
fi

if [[ ! -f "$SECUREBOOT_KEY" ]]; then
    echo "Secure boot key not provided: $SECUREBOOT_KEY"
    exit 0
fi

SYS_ID="$(cat /sys/devices/virtual/dmi/id/product_name)"
if [[ ":Jupiter:Galileo:" =~ ":$SYS_ID:" ]]; then
    echo "Steam Deck hardware detected. Skipping key enrollment."
    exit 0
fi

mokutil --timeout -1 || :
echo -e "$ENROLLMENT_PASSWORD\n$ENROLLMENT_PASSWORD" | mokutil --import "$SECUREBOOT_KEY" || :
%end
EOF

ksflatten -c /usr/share/anaconda/interactive-defaults.ks 2>/dev/null || true
ksvalidator /usr/share/anaconda/interactive-defaults.ks 2>/dev/null || true
