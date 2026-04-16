#!/bin/bash
#
# Extracts kernel prebuilt assets for ruan from a ROM zip:
# - images/kernel
# - dtb/dtbo.img
# - dtb/dtb.img
# - dtb/dtbs/*
# - modules/dlkm/*
# - modules/ramdisk/*
#

set -euo pipefail

MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then
    MY_DIR="${PWD}"
fi

ANDROID_ROOT="${MY_DIR}/../../.."
EXTRACT_OTA="${ANDROID_ROOT}/prebuilts/extract-tools/linux-x86/bin/ota_extractor"
MKDTBOIMG="${ANDROID_ROOT}/system/libufdt/utils/src/mkdtboimg.py"
UNPACKBOOTIMG="${ANDROID_ROOT}/system/tools/mkbootimg/unpack_bootimg.py"

ROM_ZIP="${1:-}"

usage() {
    echo "Usage: ./extract-prebuilt-images.sh <rom-zip>"
    exit 1
}

cleanup() {
    if [[ -n "${extract_out:-}" && -d "${extract_out}" ]]; then
        rm -rf "${extract_out}"
    fi
}

trap cleanup EXIT

if [[ -z "${ROM_ZIP}" || ! -f "${ROM_ZIP}" ]]; then
    usage
fi

for tool in "${EXTRACT_OTA}" "${UNPACKBOOTIMG}" "${MKDTBOIMG}"; do
    if [[ ! -f "${tool}" ]]; then
        echo "Missing required tool: ${tool}"
        exit 1
    fi
done

if ! command -v fsck.erofs >/dev/null 2>&1; then
    echo "Missing required host tool: fsck.erofs"
    exit 1
fi

if ! command -v unlz4 >/dev/null 2>&1; then
    echo "Missing required host tool: unlz4"
    exit 1
fi

if ! command -v cpio >/dev/null 2>&1; then
    echo "Missing required host tool: cpio"
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "Missing required host tool: python3"
    exit 1
fi

for dir in "${MY_DIR}/modules/dlkm" "${MY_DIR}/modules/ramdisk" "${MY_DIR}/dtb" "${MY_DIR}/dtb/dtbs" "${MY_DIR}/prebuilts"; do
    rm -rf "${dir}"
    mkdir -p "${dir}"
done

extract_out="$(mktemp -d)"
echo "Using temporary directory: ${extract_out}"

echo "Extracting payload.bin from ${ROM_ZIP}"
unzip -o "${ROM_ZIP}" payload.bin -d "${extract_out}" >/dev/null

echo "Extracting OTA images"
"${EXTRACT_OTA}" \
    -payload "${extract_out}/payload.bin" \
    -output_dir "${extract_out}" \
    -partitions boot,dtbo,vendor_boot,vendor_dlkm

echo "Extracting kernel from boot.img"
boot_out="${extract_out}/boot-out"
mkdir -p "${boot_out}"
"${UNPACKBOOTIMG}" --boot_img "${extract_out}/boot.img" --out "${boot_out}" --format mkbootimg
cp "${boot_out}/kernel" "${MY_DIR}/prebuilts/kernel"

echo "Extracting DTB and ramdisk modules from vendor_boot.img"
vendor_boot_out="${extract_out}/vendor_boot-out"
mkdir -p "${vendor_boot_out}"
"${UNPACKBOOTIMG}" --boot_img "${extract_out}/vendor_boot.img" --out "${vendor_boot_out}" --format mkbootimg

cp "${vendor_boot_out}/dtb" "${MY_DIR}/dtb/dtb.img"

mkdir -p "${vendor_boot_out}/ramdisk"
unlz4 "${vendor_boot_out}/vendor_ramdisk00" "${vendor_boot_out}/vendor_ramdisk"
cpio -i -F "${vendor_boot_out}/vendor_ramdisk" -D "${vendor_boot_out}/ramdisk" >/dev/null 2>&1

find "${vendor_boot_out}/ramdisk" \( -name "*.ko" -o -name "modules.load*" -o -name "modules.blocklist" \) -type f \
    -exec cp {} "${MY_DIR}/modules/ramdisk/" \;

echo "Extracting vendor_dlkm modules"
vendor_dlkm_out="${extract_out}/vendor_dlkm"
mkdir -p "${vendor_dlkm_out}"
fsck.erofs --extract="${vendor_dlkm_out}" "${extract_out}/vendor_dlkm.img" >/dev/null

find "${vendor_dlkm_out}/lib" \( -name "*.ko" -o -name "modules.load*" -o -name "modules.blocklist" \) -type f \
    -exec cp {} "${MY_DIR}/modules/dlkm/" \;

echo "Extracting DTBO and DTBs"
curl -sSL "https://raw.githubusercontent.com/PabloCastellano/extract-dtb/master/extract_dtb/extract_dtb.py" \
    > "${extract_out}/extract_dtb.py"

python3 "${extract_out}/extract_dtb.py" "${vendor_boot_out}/dtb" -o "${extract_out}/dtbs" >/dev/null
find "${extract_out}/dtbs" -type f -name "*.dtb" -exec cp {} "${MY_DIR}/dtb/dtbs/" \;

python3 "${extract_out}/extract_dtb.py" "${extract_out}/dtbo.img" -o "${extract_out}/dtbo" >/dev/null
"${MKDTBOIMG}" create "${MY_DIR}/dtb/dtbo.img" --page_size=4096 "${extract_out}"/dtbo/*.dtb

echo "Done."
echo "Updated:"
echo "  ${MY_DIR}/prebuilts/kernel"
echo "  ${MY_DIR}/dtb/dtb.img"
echo "  ${MY_DIR}/dtb/dtbo.img"
echo "  ${MY_DIR}/dtb/dtbs/*"
echo "  ${MY_DIR}/modules/dlkm/*"
echo "  ${MY_DIR}/modules/ramdisk/*"
