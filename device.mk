#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# MINIMAL BOOT BUILD - Only boot-critical packages
# Goal: Get device to boot to lock screen with minimal features
# Disabled: Audio, Bluetooth, Camera, Euicc, Telephony, Vibrator, WiFi

# Enable virtual A/B OTA
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/launch_with_vendor_ramdisk.mk)

# Enable project quotas and casefolding for emulated storage without sdcardfs
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

# Setup dalvik vm configs
$(call inherit-product, frameworks/native/build/phone-xhdpi-6144-dalvik-heap.mk)

# Qualcomm
$(call inherit-product, hardware/qcom-caf/common/common.mk)

# A/B
AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=ext4 \
    POSTINSTALL_OPTIONAL_system=true

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_vendor=true \
    POSTINSTALL_PATH_vendor=bin/checkpoint_gc \
    FILESYSTEM_TYPE_vendor=erofs \
    POSTINSTALL_OPTIONAL_vendor=true

PRODUCT_PACKAGES += \
    checkpoint_gc \
    otapreopt_script

# API
BOARD_SHIPPING_API_LEVEL := 31
PRODUCT_SHIPPING_API_LEVEL := $(BOARD_SHIPPING_API_LEVEL)

# Enable the AIDL ndk_platform backend so Soong generates the
# <interface>-V<N>-ndk_platform platform variants that the QTI vendor
# blobs link against (android.hardware.common-V2, keymaster, keymint,
# secureclock, light, etc.). The vendor tree prebuilts marked
# `prefer: true` (power, biometrics.common/face, automotive.watchdog)
# still take precedence over the source-generated variants.
NEED_AIDL_NDK_PLATFORM_BACKEND := true

# Boot control (CRITICAL)
PRODUCT_PACKAGES += \
    android.hardware.boot-service.qti \
    android.hardware.boot-service.qti.recovery

# F2FS tools for recovery (fsck needed for the 'check' flag on /data)
PRODUCT_PACKAGES += \
    fsck.f2fs.recovery

# Display (CRITICAL for screen)
PRODUCT_PACKAGES += \
    android.hardware.graphics.mapper@4.0-impl-qti-display \
    vendor.qti.hardware.display.allocator-service \
    vendor.qti.hardware.display.composer-service

PRODUCT_PACKAGES += \
    init.qti.display_boot.rc \
    init.qti.display_boot.sh

PRODUCT_COPY_FILES += \
    hardware/qcom-caf/sm8450/display/config/snapdragon_color_libs_config.xml:$(TARGET_COPY_OUT_VENDOR)/etc/snapdragon_color_libs_config.xml

# DRM (needed for display)
PRODUCT_PACKAGES += \
    android.hardware.drm-service.clearkey

# Dynamic partitions
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# Fastbootd (needed for flashing)
PRODUCT_PACKAGES += \
    fastbootd

# Graphics (CRITICAL for rendering)
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.opengles.aep.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.opengles.aep.xml \
    frameworks/native/data/etc/android.hardware.vulkan.compute-0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.compute.xml \
    frameworks/native/data/etc/android.hardware.vulkan.level-1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.level.xml \
    frameworks/native/data/etc/android.hardware.vulkan.version-1_1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.version.xml

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH) \
    hardware/google/interfaces \
    hardware/google/pixel \
    hardware/lineage/interfaces/power-libperfmgr \
    hardware/qcom-caf/common/libqti-perfd-client \
    hardware/qcom-caf/wlan \
    hardware/xiaomi

# Thermal (CRITICAL for safety)
PRODUCT_PACKAGES += \
    android.hardware.thermal-service.qti

# Touchscreen (needed for input)
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml

# Update engine (needed for OTA)
PRODUCT_PACKAGES += \
    update_engine \
    update_verifier

# USB (CRITICAL for debugging)
PRODUCT_PACKAGES += \
    android.hardware.usb-service.qti \
    android.hardware.usb.gadget-service.qti

PRODUCT_PACKAGES += \
    init.qcom.usb.rc \
    init.qcom.usb.sh \
    usb_compositions.conf

PRODUCT_SOONG_NAMESPACES += \
    vendor/qcom/opensource/usb/etc

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.host.xml

# Vendor service manager
PRODUCT_PACKAGES += \
    vndservice \
    vndservicemanager

# Verified boot
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.software.verified_boot.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.verified_boot.xml

# Vendor
$(call inherit-product, vendor/xiaomi/ruan/ruan-vendor.mk)

# Lineage health soong config
SOONG_CONFIG_NAMESPACES += lineage_health
SOONG_CONFIG_lineage_health += charging_control_supports_bypass
SOONG_CONFIG_TYPE_lineage_health_charging_control_supports_bypass := bool
SOONG_CONFIG_lineage_health_charging_control_supports_bypass := false

# Recovery init RC — root (first-stage init) + system/etc/init (second-stage)
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/init.recovery.qcom.rc:root/init.recovery.qcom.rc \
    $(LOCAL_PATH)/rootdir/init.recovery.hardware.rc:root/init.recovery.hardware.rc \
    $(LOCAL_PATH)/rootdir/etc/init/init.recovery.qcom.rc:system/etc/init/init.recovery.qcom.rc

# Recovery virtualkeys
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/recovery/root/sys/board_properties/virtualkeys.NVTCapacitiveTouchScreen:recovery/root/sys/board_properties/virtualkeys.NVTCapacitiveTouchScreen

# GSI AVB keys for first stage mount
PRODUCT_COPY_FILES += \
    test/vts-testcase/security/avb/data/q-gsi.avbpubkey:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/avb/q-gsi.avbpubkey \
    test/vts-testcase/security/avb/data/r-gsi.avbpubkey:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/avb/r-gsi.avbpubkey \
    test/vts-testcase/security/avb/data/s-gsi.avbpubkey:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/avb/s-gsi.avbpubkey

# Virtual AB / Dynamic partitions - snapuserd required
PRODUCT_PACKAGES += \
    snapuserd \
    snapuserd_ramdisk

# Fstab
PRODUCT_PACKAGES += \
    fstab.qcom \
    fstab.qcom.ramdisk

# OTA
PRODUCT_PACKAGES += \
    update_engine_sideload

# DISABLED FOR MINIMAL BOOT:
# - Audio (lines 48-113 in full device.mk)
# - Bluetooth (lines 115-122)
# - Camera (lines 133-141)
# - Euicc (lines 163-165)
# - Telephony (lines 189-224)
# - Vibrator (lines 265-272)
# - WiFi (lines 274-298)
