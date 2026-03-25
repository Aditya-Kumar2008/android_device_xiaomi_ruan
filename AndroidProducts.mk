#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/lineage_ruan.mk
# Newer build systems require lunch combos in the form:
#   <product>-<release>-<variant>
# The common default "release" is trunk_staging.
COMMON_LUNCH_CHOICES += \
    lineage_ruan-trunk_staging-userdebug \
    lineage_ruan-trunk_staging-eng
