#!/usr/bin/env bash
# -*- coding: utf-8 -*-
set -eo pipefail

# Image source
IMG_NAME="2022-04-04-raspios-bullseye-arm64-lite.img"
IMG_REPO="https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2022-04-07/"

# -----------------------------------------------------------------------------

MOUNT_PATH=$(mktemp -p "$PWD" -d)
SYSROOT="sysroot.tar.gz"

DOCKER="podman"
command -v podman &> /dev/null || DOCKER="docker"

function cleanup {
    if mountpoint -q -- "${MOUNT_PATH}"; then
        if ! umount ${MOUNT_PATH}; then
            >&2 echo "Error: could not unmount '${IMG_NAME}' from '${MOUNT_PATH}'"
        fi
    fi
  
    for pth in "${MOUNT_PATH}" "${IMG_NAME}" "${IMG_NAME}.xz" "${IMG_NAME}.xz.sig" "${IMG_NAME}.xz.sha256"; do
        if ! rm -rf "${pth}"; then
            >&2 echo "Error: failed to remove '${pth}'"
        fi
    done
}
trap cleanup EXIT

# Sanity check
for cmd in curl sha256sum gpg guestmount unxz tar $DOCKER; do
    command -v $cmd &> /dev/null || (echo "ERROR: $cmd not found - please install it"; exit 5)
done

# Download
for download in ${IMG_NAME}.xz ${IMG_NAME}.xz.sha256 ${IMG_NAME}.xz.sig; do
    if [ ! -f ${download} ]; then
        echo "Downloading ${download}..."
        if ! curl -s -o ${download} ${IMG_REPO}${download}; then
          >&2 echo "Error: failed to download ${IMG_REPO}${download}"
          exit 20
        fi
    fi
done

# Validate image
echo "Validating image..."
if ! echo "$(cat ${IMG_NAME}.xz.sha256)" | sha256sum --check --status; then
    >&2 echo "Error: checksum does not match"
    exit 30
fi

if ! gpg -q --verify ${IMG_NAME}.xz.sig ${IMG_NAME}.xz 2>/dev/null ;then
    >&2 echo "Error: GPG signature is invalid"
    exit 31
fi

# Extract to sysroot file
if [ -f ${IMG_NAME}.xz -a ! -f ${IMG_NAME} ]; then
    echo "Unpacking image..."
    if ! unxz --keep ${IMG_NAME}.xz; then
        >&2 echo "Error: could not unpack image"
        exit 40
    fi
fi

if ! guestmount -a ${IMG_NAME} -i --ro "${MOUNT_PATH}"; then
    >&2 echo "Error: could not mount ${IMG_NAME} to ${MOUNT_PATH}"
    exit 60
fi

echo "Compressing and copying data. This may take a while..."
if ! tar -czf ${SYSROOT} -C "${MOUNT_PATH}" .; then
    >&2 echo "Error: could not tar up ${SYSROOT} from ${MOUNT_PATH}"
    exit 70
fi

echo "${SYSROOT} file created sucessfully"

echo "Building docker image..."
if ! $DOCKER build --no-cache --platform linux/arm64/v8 -t pi64:latest -t pi64:arm64 .; then
    >&2 echo "Error: could build docker image"
    exit 80
fi
