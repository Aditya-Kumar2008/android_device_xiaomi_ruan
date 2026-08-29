#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/xiaomi/ruan
KERNEL_PATH := $(DEVICE_PATH)-kernel

BUILD_BROKEN_DUP_RULES := true

# A/B
AB_OTA_PARTITIONS := \
    boot \
    vendor_boot \
    recovery \
    dtbo \
    system \
    system_ext \
    product \
    vendor \
    vendor_dlkm \
    odm \
    vbmeta \
    vbmeta_system
   

#Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a-branchprot
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := cortex-a78
TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-2a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a55


# Audio
AUDIO_FEATURE_ENABLED_DLKM := true
AUDIO_FEATURE_ENABLED_DTS_EAGLE := false
AUDIO_FEATURE_ENABLED_GEF_SUPPORT := true
AUDIO_FEATURE_ENABLED_HW_ACCELERATED_EFFECTS := false
AUDIO_FEATURE_ENABLED_INSTANCE_ID := true
AUDIO_FEATURE_ENABLED_PAL_HIDL := false
AUDIO_FEATURE_ENABLED_PROXY_DEVICE := true

TARGET_USES_QCOM_MM_AUDIO := false
TARGET_PROVIDES_AUDIO_HAL = true

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME := parrot
TARGET_NO_BOOTLOADER := true

# Display
TARGET_SCREEN_DENSITY := 280

# Filesystem
TARGET_FS_CONFIG_GEN := $(DEVICE_PATH)/configs/config.fs

# Hardware
BOARD_USES_QCOM_HARDWARE := true

# HIDL
DEVICE_MATRIX_FILE := hardware/qcom-caf/common/compatibility_matrix.xml
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE += \
    hardware/qcom-caf/common/vendor_framework_compatibility_matrix.xml \
    hardware/xiaomi/vintf/xiaomi_framework_compatibility_matrix.xml

DEVICE_MANIFEST_FILE := \
    $(DEVICE_PATH)/configs/hidl/manifest.xml \
    hardware/qcom-caf/sm8450/audio/primary-hal/configs/common/manifest_non_qmaa.xml \
    hardware/qcom-caf/sm8450/audio/primary-hal/configs/common/manifest_non_qmaa_extn.xml

ODM_MANIFEST_SKUS += IN
ODM_MANIFEST_IN_FILES := $(DEVICE_PATH)/configs/hidl/manifest_nonfc.xml

$(foreach sku, CN GL JP, \
    $(eval ODM_MANIFEST_SKUS += $(sku)) \
    $(eval ODM_MANIFEST_$(sku)_FILES += \
        $(DEVICE_PATH)/configs/hidl/manifest_nfc.xml))

DEVICE_FRAMEWORK_MANIFEST_FILE += $(DEVICE_PATH)/configs/hidl/framework_manifest.xml

# Kernel
# TARGET_KERNEL_ADDITIONAL_FLAGS := TARGET_PRODUCT=ruan
# TARGET_KERNEL_SOURCE := kernel/xiaomi/sm7435
# TARGET_KERNEL_CONFIG := \
#   gki_defconfig \
#    vendor/parrot_GKI.config \
#    vendor/ruan_GKI.config \
#    vendor/debugfs.config

BOARD_VENDOR_KERNEL_MODULES_BLOCKLIST_FILE := $(KERNEL_PATH)/modules/vendor_dlkm.stock/modules.blocklist
BOARD_VENDOR_KERNEL_MODULES_LOAD := $(strip $(shell cat $(KERNEL_PATH)/modules/vendor_dlkm.stock/modules.load))
BOARD_VENDOR_RAMDISK_KERNEL_MODULES_BLOCKLIST_FILE := $(KERNEL_PATH)/modules/vendor_ramdisk.stock/modules.blocklist
BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD := $(strip $(shell cat $(KERNEL_PATH)/modules/vendor_ramdisk.stock/modules.load))
BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD := $(strip $(shell cat $(KERNEL_PATH)/modules/vendor_ramdisk.stock/modules.load.recovery))

# Kernel prebuilt
BOARD_USES_DT := true
BOARD_PREBUILT_DTBIMAGE_DIR := $(KERNEL_PATH)/dtbs
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
BOARD_PREBUILT_DTBOIMAGE := $(KERNEL_PATH)/dtbo.img
TARGET_FORCE_PREBUILT_KERNEL := true
TARGET_KERNEL_SOURCE := $(KERNEL_PATH)/kernel-headers
TARGET_NO_KERNEL_OVERRIDE := true
TARGET_PREBUILT_KERNEL := $(KERNEL_PATH)/kernel.stock
PRODUCT_COPY_FILES += $(TARGET_PREBUILT_KERNEL):kernel

TARGET_BOARD_INFO_FILE := device/xiaomi/ruan/board-info.txt

BOARD_BOOT_HEADER_VERSION := 4
BOARD_MKBOOTIMG_ARGS := --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_USES_GENERIC_KERNEL_IMAGE := true
# Match stock vendor_boot load addresses (stock uses base 0x0):
# kernel_addr=0x8000, ramdisk_addr=0x1000000, tags_addr=0x100, dtb_addr=0x1f00000
BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_RAMDISK_OFFSET := 0x01000000
BOARD_TAGS_OFFSET := 0x00000100
BOARD_DTB_OFFSET := 0x01f00000

BOARD_KERNEL_CMDLINE := \
    video=vfb:640x400,bpp=32,memsize=3072000 \
    disable_dma32=on \
    bootinfo.fingerprint=$(LINEAGE_VERSION) \
    swinfo.fingerprint=$(LINEAGE_VERSION) 

BOARD_BOOTCONFIG := \
    androidboot.hardware=qcom \
    androidboot.memcg=1 \
    androidboot.usbcontroller=a600000.dwc3 \
    androidboot.selinux=permissive 

# Kernel modules
# Using prebuilt modules from device/xiaomi/ruan-kernel/modules/
# TARGET_KERNEL_EXT_MODULE_ROOT := kernel/xiaomi/sm7435-modules
# TARGET_KERNEL_EXT_MODULES := \
# 	qcom/opensource/mmrm-driver \
# 	qcom/opensource/audio-kernel \
# 	qcom/opensource/camera-kernel \
# 	qcom/opensource/cvp-kernel \
# 	qcom/opensource/dataipa/drivers/platform/msm \
# 	qcom/opensource/datarmnet/core \
# 	qcom/opensource/datarmnet-ext/aps \
# 	qcom/opensource/datarmnet-ext/offload \
# 	qcom/opensource/datarmnet-ext/shs \
# 	qcom/opensource/datarmnet-ext/perf \
# 	qcom/opensource/datarmnet-ext/perf_tether \
# 	qcom/opensource/datarmnet-ext/sch \
# 	qcom/opensource/datarmnet-ext/wlan \
# 	qcom/opensource/display-drivers/msm \
# 	qcom/opensource/eva-kernel \
# 	qcom/opensource/video-driver \
# 	qcom/opensource/wlan/qcacld-3.0/.qca6750

# Partitions
-include vendor/lineage/config/BoardConfigReservedSize.mk

BOARD_BOOTIMAGE_PARTITION_SIZE := 100663296   
BOARD_DTBOIMG_PARTITION_SIZE := 24117248   
BOARD_SUPER_PARTITION_SIZE := 8589934592        # 8912896 KB from partition_ext.xml
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 100663296 # 96MB

BOARD_KERNEL_PAGESIZE := 4096
BOARD_FLASH_BLOCK_SIZE := 262144 # (BOARD_KERNEL_PAGESIZE * 64)

BOARD_USES_METADATA_PARTITION := true

BOARD_QTI_DYNAMIC_PARTITIONS_SIZE := 8585740288 # (BOARD_SUPER_PARTITION_SIZE - 4 MiB)
BOARD_SUPER_PARTITION_GROUPS := qti_dynamic_partitions

BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs

TARGET_COPY_OUT_ODM := odm
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_SYSTEM := system
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm

# Platform
TARGET_BOARD_PLATFORM := parrot

# Recovery
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/rootdir/etc/fstab.qcom
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888

# RIL
ENABLE_VENDOR_RIL_SERVICE := true

# Sepolicy
include device/lineage/sepolicy/libperfmgr/sepolicy.mk
include device/qcom/sepolicy_vndr/SEPolicy.mk

BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor

# System properties
TARGET_ODM_PROP += $(DEVICE_PATH)/props/odm.prop
TARGET_PRODUCT_PROP += $(DEVICE_PATH)/props/product.prop
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/props/system.prop
TARGET_SYSTEM_EXT_PROP += $(DEVICE_PATH)/props/system_ext.prop
TARGET_VENDOR_PROP += $(DEVICE_PATH)/props/vendor.prop

# Vendor security patch
VENDOR_SECURITY_PATCH := 2025-09-01

# Verified Boot
BOARD_AVB_ENABLE := true
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3
BOARD_MOVE_GSI_AVB_KEYS_TO_VENDOR_BOOT := false

# Spoof vbmeta os_version props to Android 12 (VNDK-32 vendor era).
# Stock vbmeta carries com.android.build.{boot,vendor,odm,vendor_dlkm}.os_version='12'
# while the framework (system/product) stays '16'. ABL reads these props on normal
# boot and drops to fastboot if they don't match the vendor's expected 12.
BOOT_OS_VERSION := 12
VENDOR_OS_VERSION := 12
ODM_OS_VERSION := 12
VENDOR_DLKM_OS_VERSION := 12

BOARD_AVB_RECOVERY_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_RECOVERY_ALGORITHM := SHA256_RSA4096
BOARD_AVB_RECOVERY_ROLLBACK_INDEX := 0xFFFFFFFFFFFFFFFF
BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION := 1

BOARD_AVB_VBMETA_SYSTEM := system system_ext product
BOARD_AVB_VBMETA_SYSTEM_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_VBMETA_SYSTEM_ALGORITHM := SHA256_RSA4096
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX := 0xFFFFFFFFFFFFFFFF
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX_LOCATION := 2
BOARD_AVB_MAKE_VBMETA_SYSTEM_IMAGE_ARGS += --flags 3

# WiFi
BOARD_WLAN_DEVICE := qcwcn
BOARD_HOSTAPD_DRIVER := NL80211
BOARD_HOSTAPD_PRIVATE_LIB := lib_driver_cmd_$(BOARD_WLAN_DEVICE)
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := lib_driver_cmd_$(BOARD_WLAN_DEVICE)
# (1 STA + 1 AP) or (1 STA + 1 of (P2P or NAN)) or (2 AP) or (2 STA)
WIFI_HAL_INTERFACE_COMBINATIONS := {{{STA}, 1}, {{AP}, 1}}, {{{STA}, 1}, {{P2P, NAN}, 1}}, {{{AP}, 2}}, {{{STA}, 2}}
WIFI_DRIVER_DEFAULT := qca_cld3
WIFI_DRIVER_STATE_CTRL_PARAM := "/dev/wlan"
WIFI_DRIVER_STATE_OFF := "OFF"
WIFI_DRIVER_STATE_ON := "ON"
WIFI_FEATURE_HOSTAPD_11AX := true
WIFI_HIDL_UNIFIED_SUPPLICANT_SERVICE_RC_ENTRY := true
WPA_SUPPLICANT_VERSION := VER_0_8_X

# Vendor
include vendor/xiaomi/ruan/BoardConfigVendor.mk

# Kernel headers

# Kernel headers
TARGET_PREBUILT_KERNEL_HEADERS := device/xiaomi/ruan-kernel/kernel_headers.tar

# No separate recovery - uses AB/virtual AB
# BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true

# Recovery — separate partition
BOARD_USES_RECOVERY_AS_BOOT := false
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 104857600

# Disable AVB enforcement on recovery for custom recovery support
BOARD_AVB_RECOVERY_ADD_HASH_FOOTER_ARGS += --prop com.android.build.recovery.fingerprint:$(BUILD_FINGERPRINT_FROM_FILE)

# Recovery uses v2 header, not v4 (GKI boot header)
BOARD_RECOVERY_HEADER_VERSION := 4
BOARD_MKRECOVERYIMG_ARGS := --header_version $(BOARD_RECOVERY_HEADER_VERSION)
BOARD_RAMDISK_USE_LZ4 := true

# Recovery touch
TARGET_RECOVERY_UI_MARGIN_HEIGHT := 0
TARGET_RECOVERY_UI_TOUCH_HIGH_DENSITY := true

# OS version spoof for Snapdragon bootloader compatibility
BOARD_MKBOOTIMG_ARGS += --os_version 12.0.0 --os_patch_level 2025-09
BOARD_MKRECOVERYIMG_ARGS += --os_version 12.0.0 --os_patch_level 2025-09

# Strip kernel from recovery (stock recovery is ramdisk-only)
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true

# Kernel modules path
BOARD_VENDOR_RAMDISK_KERNEL_MODULES := $(wildcard $(KERNEL_PATH)/modules/vendor_ramdisk.stock/*.ko)
BOARD_VENDOR_KERNEL_MODULES := $(wildcard $(KERNEL_PATH)/modules/vendor_dlkm.stock/*.ko)

# Kernel offsets (matching stock OS2.0.207.0)
BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST := product system system_ext odm vendor vendor_dlkm

# Disable host cross-compilation to avoid CRT variant issues with AIDL NDK backends
ALLOW_MISSING_DEPENDENCIES := true

# Vendor prebuilt blobs are installed via PRODUCT_COPY_FILES (generated from
# the proprietary tree). Allow ELF prebuilts in copy files.
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true

# Disable Qualcomm audio HAL completely to avoid PAL compilation errors
AUDIO_USE_STUB_HAL := true
TARGET_USES_AOSP_FOR_AUDIO := true
