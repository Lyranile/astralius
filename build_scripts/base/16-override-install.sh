#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Override installed files from system_files (GNOME tweaks, nvidia, etc.)
if [[ -d /ctx/system_files ]]; then
	rsync -rvKl /ctx/system_files/ /
fi

echo "::endgroup::"
