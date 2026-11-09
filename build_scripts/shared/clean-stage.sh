#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

mv /etc/dnf/dnf.conf.bak /etc/dnf/dnf.conf
dnf versionlock clear

rm -rf /usr/lib/sysimage/libdnf5/*

systemctl mask flatpak-add-fedora-repos.service
rm -f /usr/lib/systemd/system/flatpak-add-fedora-repos.service

for file in rpmdb.sqlite rpmdb.sqlite-shm rpmdb.sqlite-wal; do
    target="/usr/share/rpm/${file}"
    link_path="/usr/lib/sysimage/rpm-ostree-base-db/${file}"
    if [[ -f "${target}" && -f "${link_path}" ]]; then
        ln -f "${target}" "${link_path}"
    fi
done

find /var/* -maxdepth 0 -type d \! -name cache -exec rm -fr {} \;

find /run -mindepth 1 \
  ! -path '/run/systemd' \
  ! -path '/run/systemd/resolve' \
  ! -path '/run/systemd/resolve/stub-resolv.conf' \
  ! -path '/run/secrets' \
  ! -path '/run/secrets/*' \
  ! -path '/run/.containerenv' \
  -delete

rm -rf /tmp/* /tmp/.*
mkdir -p /var/tmp

rm -rf /opt && ln -s /var/opt /opt

echo "::endgroup::"
