#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
TARGET_SUPPORTS_OMX_SERVICE := false
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Tablet characteristics (also set in device.mk; kept here for aapt).
PRODUCT_CHARACTERISTICS := tablet

# Inherit some common LineageOS stuff.
$(call inherit-product, vendor/lineage/config/common_full_tablet.mk)

# Inherit from ruan device
$(call inherit-product, device/xiaomi/ruan/device.mk)

# vendor/pixel-style sets ro.setupwizard.rotation_locked from
# PRODUCT_CHARACTERISTICS inside its own makefile. That conditional never sees
# PRODUCT_CHARACTERISTICS=tablet in this tree, so it emits rotation_locked=true,
# which locks the Set-Up Wizard to portrait and strands it (no scroll/Continue)
# on this landscape tablet. Drop whatever pixel-style emitted and pin the
# landscape-friendly value so exactly one assignment reaches build.prop.
PRODUCT_PRODUCT_PROPERTIES += ro.setupwizard.rotation_locked=false

TARGET_BOOT_ANIMATION_RES := 1600
TARGET_BUILD_APERTURE_CAMERA := true
TARGET_DISABLE_EPPE := true

PRODUCT_NAME := lineage_ruan
PRODUCT_DEVICE := ruan
PRODUCT_MANUFACTURER := Xiaomi
PRODUCT_BRAND := Redmi
PRODUCT_MODEL := 24074RPD2G

PRODUCT_SYSTEM_NAME := ruan_global
PRODUCT_SYSTEM_DEVICE := ruan

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="ruan_global-user 16 BP2A.250605.031.A3 OS3.0.303.0.WFSMIXM release-keys" \
    BuildFingerprint=Redmi/ruan_global/ruan:16/BP2A.250605.031.A3/OS3.0.303.0.WFSMIXM:user/release-keys \
    DeviceName=$(PRODUCT_SYSTEM_DEVICE) \
    DeviceProduct=$(PRODUCT_SYSTEM_NAME)

PRODUCT_GMS_CLIENTID_BASE := android-xiaomi
