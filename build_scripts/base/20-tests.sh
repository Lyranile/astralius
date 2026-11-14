#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Basic sanity checks
test -f /usr/share/ublue-os/image-info.json
test -f /usr/lib/os-release

echo "::endgroup::"
