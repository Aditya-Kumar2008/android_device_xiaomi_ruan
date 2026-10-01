#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from ruan device
$(call inherit-product, device/xiaomi/ruan/device.mk)

# ROM common config. InfinityX ships vendor/infinity, crDroid ships
# vendor/crdroid plus vendor/lineage (its LineageOS fork). Only the one that
# exists is pulled in, so the same tree builds both.
#
# INFINITY_MAINTAINER is read by vendor/infinity/config/version.mk, which
# common.mk includes, so it has to be set before the inherit below.
INFINITY_MAINTAINER := Aditya

$(call inherit-product-if-exists, vendor/lineage/config/common_full_tablet.mk)
$(call inherit-product-if-exists, vendor/infinity/config/common_full_tablet.mk)
$(call inherit-product-if-exists, vendor/crdroid/config/common_full_tablet.mk)

# Maintainer branding. crDroid has no maintainer variable of its own, so these
# are set directly and read the same on either ROM.
PRODUCT_PRODUCT_PROPERTIES += \
    ro.ruan.maintainer=Aditya \
    ro.ruan.builder=Aditya \
    ro.adityarohilla.build=true \
    ro.adityarohilla.rom=$(PRODUCT_NAME)

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
