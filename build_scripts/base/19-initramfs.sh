#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Rebuild initramfs for all kernels
dracut --regenerate-all -f

echo "::endgroup::"
