#
# Copyright (C) 2024 The LineageOS Project
# Copyright (C) 2024 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from the device configuration.
$(call inherit-product, device/xiaomi/ruan/device.mk)

# Inherit some common LineageOS stuff.
$(call inherit-product, vendor/lineage/config/common_full_tablet.mk)

# Device identifier. This must come after all inclusions.
PRODUCT_NAME := lineage_ruan
PRODUCT_DEVICE := ruan
PRODUCT_BRAND := POCO
PRODUCT_MODEL := POCO Pad 5G
PRODUCT_MANUFACTURER := Xiaomi
PRODUCT_SHIPPING_API_LEVEL := 33

PRODUCT_GMS_CLIENTID_BASE := android-xiaomi

# Device characteristics - single definition here (removed from device.mk)
PRODUCT_CHARACTERISTICS := tablet,telephony

# Build fingerprint - India (IN) variant HyperOS
PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="ruan_in-user 15 AP3A.240905.015.A2 OS2.0.208.0.VFSINXM release-keys"

BUILD_FINGERPRINT := POCO/ruan_in/ruan:15/AP3A.240905.015.A2/OS2.0.208.0.VFSINXM:user/release-keys

# Device characteristics
PRODUCT_CHARACTERISTICS := tablet,telephony
