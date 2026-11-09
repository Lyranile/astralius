# Allow build scripts to be referenced without being copied into the final image
FROM ghcr.io/ublue-os/brew:latest AS brew

FROM scratch AS ctx
COPY build_scripts /build_scripts
COPY system_files /system_files

# Base Image (GNOME / Silverblue)
ARG BASE_IMAGE=ghcr.io/ublue-os/silverblue-main:latest
FROM ${BASE_IMAGE} AS base

ARG IMAGE_NAME=astralius
ARG IMAGE_VENDOR=Lyranile
ARG FEDORA_MAJOR_VERSION=
ARG UBLUE_IMAGE_TAG=latest
ARG VERSION=00.00000000
ARG SHA_HEAD_SHORT=
ARG NVIDIA=false

ENV IMAGE_NAME=${IMAGE_NAME}
ENV IMAGE_VENDOR=${IMAGE_VENDOR}
ENV FEDORA_MAJOR_VERSION=${FEDORA_MAJOR_VERSION}
ENV UBLUE_IMAGE_TAG=${UBLUE_IMAGE_TAG}
ENV VERSION=${VERSION}
ENV SHA_HEAD_SHORT=${SHA_HEAD_SHORT}
ENV NVIDIA=${NVIDIA}
ENV BASE_IMAGE_NAME=silverblue-main

# Make helper scripts available
ENV PATH="/tmp/scripts/helpers:${PATH}"

### MODIFICATIONS - networked stage
RUN --mount=type=tmpfs,dst=/boot \
    --mount=type=tmpfs,dst=/var \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    /ctx/build_scripts/shared/build-prep.sh && \
    /ctx/build_scripts/base/01-packages.sh

# Bring in Homebrew (ublue-os/brew)
COPY --from=brew /system_files /system_files

# NVIDIA (conditional)
RUN --mount=type=tmpfs,dst=/boot \
    --mount=type=tmpfs,dst=/var \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    bash -c 'if [[ "${NVIDIA}" == "true" ]]; then /ctx/build_scripts/base/04-nvidia.sh; else echo "Skipping NVIDIA"; fi'

### Offline stage
RUN --network=none \
    --mount=type=tmpfs,dst=/boot \
    --mount=type=tmpfs,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/build_scripts/base/16-override-install.sh && \
    /ctx/build_scripts/base/17-services.sh && \
    /ctx/build_scripts/base/18-image-info.sh && \
    /ctx/build_scripts/base/19-initramfs.sh && \
    /ctx/build_scripts/shared/clean-stage.sh && \
    /ctx/build_scripts/shared/unpackaged.sh && \
    /ctx/build_scripts/base/20-tests.sh

CMD ["/sbin/init"]

RUN bootc container lint
