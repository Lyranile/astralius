#!/usr/bin/env bash
# Chunkah layer annotations for Astralius (GNOME)
echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

HOMEBREW_TARBALL=/usr/share/homebrew.tar.zst
if [[ -f "${HOMEBREW_TARBALL}" ]]; then
	setfattr -n user.component -v "homebrew" "${HOMEBREW_TARBALL}" || true
fi

# rpm-ostree tmpfiles
RPM_OSTREE_TMPFILES=/usr/lib/rpm-ostree/tmpfiles.d
if [[ -d "${RPM_OSTREE_TMPFILES}" ]]; then
	setfattr -n user.component -v "rpm-ostree-tmpfiles.d" "${RPM_OSTREE_TMPFILES}" || true
	setfattr -n user.update-interval -v "quarterly" "${RPM_OSTREE_TMPFILES}" || true
fi

# fontconfig cache
FONTCONFIG_CACHE=/usr/lib/fontconfig/cache
if [[ -d "${FONTCONFIG_CACHE}" ]]; then
	setfattr -n user.component -v "fontconfig-cache" "${FONTCONFIG_CACHE}" || true
	setfattr -n user.update-interval -v "daily" "${FONTCONFIG_CACHE}" || true
fi

# normalize timestamps
find /usr /etc /opt -newermt '1970-01-01T00:00:00Z' -exec touch -h -a -m -d '1970-01-01T00:00:01Z' {} + 2>/dev/null || true

echo "::endgroup::"
