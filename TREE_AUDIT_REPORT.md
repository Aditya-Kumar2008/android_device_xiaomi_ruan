# Device Tree Audit Report

| File | Suspicious Setting | Why Suspicious | Expected Value/Source Proof |
| --- | --- | --- | --- |
| BoardConfig.mk | `BOARD_PREBUILT_DTB := $(DEVICE_PATH)/dtb/dtb.img` and `TARGET_PREBUILT_DTB := $(BOARD_PREBUILT_DTB)` | `TARGET_PREBUILT_DTB` is not a standard AOSP/Lineage variable (AOSP uses `BOARD_PREBUILT_DTB`). Additionally, README.md says it should be `prebuilt/dtb.img` not `dtb/dtb.img`. | Remove `TARGET_PREBUILT_DTB`. Move dtb files to `prebuilt/` to match README, or update README. |
| BoardConfig.mk | `BOARD_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/kernel` and `TARGET_PREBUILT_KERNEL := $(BOARD_PREBUILT_KERNEL)` | `TARGET_PREBUILT_KERNEL` is also non-standard in AOSP build configurations. `BOARD_PREBUILT_KERNEL` is the standard variable. | Remove `TARGET_PREBUILT_KERNEL`. |
| BoardConfig.mk | `TARGET_KERNEL_VERSION := 5.10` | User asked to verify 5.10 vs 5.15. | Verified by running `strings prebuilt/kernel \| grep -o "Linux version 5.1[0-9]"` which outputs `5.10`. Setting is CORRECT. |
| device.mk | `framework_compatibility_matrix.xml` added to `DEVICE_PRODUCT_COMPATIBILITY_MATRIX_FILE` | Framework compatibility matrices belong to the platform/system, not the device matrix. This causes `assemble_vintf` warnings or errors. | Remove `framework_compatibility_matrix.xml` from `DEVICE_PRODUCT_COMPATIBILITY_MATRIX_FILE`. |
| BoardConfig.mk | `BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true` | The device builds `recovery.img` (as per `BOARD_RECOVERYIMAGE_PARTITION_SIZE`). If kernel is excluded, recovery will not boot standalone on Qualcomm devices. | Remove `BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true` unless the device relies on `vendor_boot` for recovery entirely. Stock has 100MB recovery.img. |
