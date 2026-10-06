#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# InfinityX builds from an infinity_<device> product: build/envsetup.sh strips
# the prefix into INFINITY_BUILD, and only then does build/make/core/config.mk
# include vendor/infinity/config/BoardConfigLineage.mk, which is what exports
# the kernel variables (KERNEL_BUILD_OUT_PREFIX and friends) to soong. Without
# this product, those variables never reach soong and the build fails on
# vendor/infinity/build/soong/Android.bp.

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
TARGET_SUPPORTS_OMX_SERVICE := false
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from ruan device
$(call inherit-product, device/xiaomi/ruan/device.mk)

# INFINITY_MAINTAINER is read by vendor/infinity/config/version.mk, so it has
# to be set before the common config is inherited.
INFINITY_MAINTAINER := Aditya

# Inherit some common InfinityX stuff.
$(call inherit-product, vendor/infinity/config/common_full_tablet.mk)

TARGET_BOOT_ANIMATION_RES := 1600
TARGET_BUILD_APERTURE_CAMERA := true
TARGET_DISABLE_EPPE := true

PRODUCT_NAME := infinity_ruan
PRODUCT_DEVICE := ruan
PRODUCT_MANUFACTURER := Xiaomi
PRODUCT_BRAND := Redmi
PRODUCT_MODEL := 24074RPD2G

PRODUCT_SYSTEM_NAME := ruan_global
PRODUCT_SYSTEM_DEVICE := ruan

# Spoof the stock ruan fingerprint so Play Integrity sees a certified device.
PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="ruan_global-user 16 BP2A.250605.031.A3 OS3.0.303.0.WFSMIXM release-keys" \
    BuildFingerprint=Redmi/ruan_global/ruan:16/BP2A.250605.031.A3/OS3.0.303.0.WFSMIXM:user/release-keys \
    DeviceName=$(PRODUCT_SYSTEM_DEVICE) \
    DeviceProduct=$(PRODUCT_SYSTEM_NAME)

PRODUCT_GMS_CLIENTID_BASE := android-xiaomi
