#
# Copyright (C) 2024 The LineageOS Project
# Copyright (C) 2024 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),ruan)
include $(call all-makefiles-under,$(LOCAL_PATH))
endif
