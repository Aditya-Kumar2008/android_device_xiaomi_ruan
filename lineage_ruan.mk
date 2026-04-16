#
# Copyright (C) 2024-2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, vendor/lineage/config/common_full_tablet.mk)
$(call inherit-product, device/xiaomi/ruan/device.mk)

TARGET_SUPPORTS_OMX_SERVICE := false

PRODUCT_NAME := lineage_ruan
PRODUCT_DEVICE := ruan
PRODUCT_MANUFACTURER := Xiaomi
PRODUCT_BRAND := POCO
PRODUCT_MODEL := POCO Pad 5G
PRODUCT_SYSTEM_DEVICE := ruan
PRODUCT_SYSTEM_NAME := ruan_global

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="ruan_global-user 15 AP3A.240905.015.A2 OS2.0.208.0.VFSMIXM release-keys" \
    BuildFingerprint=POCO/ruan_global/ruan:15/AP3A.240905.015.A2/OS2.0.208.0.VFSMIXM:user/release-keys \
    DeviceName=$(PRODUCT_SYSTEM_DEVICE) \
    DeviceProduct=$(PRODUCT_SYSTEM_NAME)

PRODUCT_GMS_CLIENTID_BASE := android-xiaomi
