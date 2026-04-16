# Tree Mismatch Report

1. **Fstab Name Mismatch**: The current ruan tree assumes the fstab is named `fstab.qcom` (e.g. `TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/rootdir/etc/fstab.qcom` and `ruan_fstab.qcom` in `PRODUCT_PACKAGES`). However, the stock ROM has `fstab.default` and `fstab.emmc` inside both the vendor ramdisk (`first_stage_ramdisk/`) and `vendor/etc/`.
2. **Recovery Partition Mismatch**: The current tree defines `BOARD_RECOVERYIMAGE_PARTITION_SIZE` and includes `recovery` in `AB_OTA_PARTITIONS`. The stock ROM provides a `recovery.img` (104857600 bytes), which contradicts the earlier assumption that ruan uses `vendor_boot` for recovery entirely. This means `recovery` *does* exist, so my previous revert was necessary, but wait: is `launch_with_vendor_ramdisk.mk` correct if there's a recovery partition? Yes, some devices have both.
3. **Init RC Mismatch**: The stock ROM might not have `init.qcom.rc` or `init.target.rc` if they are named `init.default.rc`. Let's check `vendor/etc/init/hw/`.
4. **Bootconfig**: Stock ROM provides a bootconfig inside the vendor_boot image. Lineage tree `BOARD_BOOTCONFIG` adds `androidboot.hardware=qcom`.
