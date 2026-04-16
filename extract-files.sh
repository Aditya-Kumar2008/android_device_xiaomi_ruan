#!/bin/bash
#
# Copyright (C) 2024-2026 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=ruan
VENDOR=xiaomi

MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then
    MY_DIR="${PWD}"
fi

ANDROID_ROOT="${MY_DIR}/../../.."
HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"

if [[ ! -f "${HELPER}" ]]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi

source "${HELPER}"

CLEAN_VENDOR=true
KANG=
SECTION=
SRC=

while [[ "${#}" -gt 0 ]]; do
    case "${1}" in
        -n|--no-cleanup)
            CLEAN_VENDOR=false
            ;;
        -k|--kang)
            KANG="--kang"
            ;;
        -s|--section)
            SECTION="${2}"
            shift
            CLEAN_VENDOR=false
            ;;
        *)
            SRC="${1}"
            ;;
    esac
    shift
done

if [[ -z "${SRC}" ]]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
        vendor/etc/init/hw/init.qcom.rc)
            sed -i '/^import \/vendor\/etc\/init\/hw\/init\.qcom\.test\.rc$/d' "${2}"
            ;;
        vendor/etc/init/hw/init.target.rc)
            sed -i '/^on property:vendor.post_boot.parsed=1$/,+2d' "${2}"
            ;;
        vendor/etc/camera/pureShot_parameter.xml|vendor/etc/camera/pureView_parameter.xml)
            sed -i 's/="100"/="0"/g' "${2}"
            ;;
        vendor/lib64/hw/camera.qcom.so)
            sed -i 's/camera.xiaomi/camera.qcom/g' "${2}"
            ;;
        vendor/lib64/libwrapper_dlengine.so|vendor/lib64/libwrapper_dlengine_v2.so)
            "${PATCHELF}" --replace-needed "libdlengine.so" "libdlengine_v2.so" "${2}"
            ;;
        vendor/lib64/libwrapper_dlengine_v3.so)
            "${PATCHELF}" --replace-needed "libdlengine.so" "libdlengine_v3.so" "${2}"
            ;;
    esac
}

FILTERED_LIST="$(mktemp)"
trap 'rm -f "${FILTERED_LIST}"' EXIT

python3 "${MY_DIR}/extract-files.py" \
    --proprietary-list "${MY_DIR}/proprietary-files.txt" \
    --write-filtered-list "${FILTERED_LIST}"

setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

extract_args=()
if [[ -n "${KANG}" ]]; then
    extract_args+=("${KANG}")
fi
if [[ -n "${SECTION}" ]]; then
    extract_args+=(--section "${SECTION}")
fi

extract "${FILTERED_LIST}" "${SRC}" "${extract_args[@]}"

bash "${MY_DIR}/setup-makefiles.sh"
