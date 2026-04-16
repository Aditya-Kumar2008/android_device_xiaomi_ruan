#!/bin/bash
#
# Copyright (C) 2024-2026 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

set -e

MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then
    MY_DIR="${PWD}"
fi

ANDROID_ROOT="${MY_DIR}/../../.."
VENDOR_ROOT="${ANDROID_ROOT}/vendor/xiaomi/ruan"

python3 "${MY_DIR}/extract-files.py" \
    --proprietary-list "${MY_DIR}/proprietary-files.txt" \
    --write-filtered-list "${VENDOR_ROOT}/proprietary-files.filtered.txt" \
    --vendor-root "${VENDOR_ROOT}"
