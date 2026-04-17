# Ruan Patch Plan

1. **[Critical] Fstab Rename**: Rename `fstab.qcom` to `fstab.default` in the device tree (`rootdir/etc/`) and update `device.mk` and `BoardConfig.mk` (`TARGET_RECOVERY_FSTAB`) to reference `fstab.default` instead. The stock ROM expects `fstab.default`, and hardcoded `fstab.qcom` paths will fail to mount correctly if init expects `fstab.default`.
2. **[Critical] Recovery Partition Configurations**: Restore the recovery partition configurations (`BOARD_RECOVERYIMAGE_PARTITION_SIZE := 104857600` and `AB_OTA_PARTITIONS += recovery`) because the stock ROM explicitly includes a 100MB `recovery.img`. Remove `launch_with_vendor_ramdisk.mk` if the device boots recovery from the recovery partition instead of `vendor_boot`.
3. **[Recommended] Add `fstab.emmc`**: Include `fstab.emmc` from stock if needed for eMMC variants (though ruan is UFS 2.2 according to README).
4. **[Critical] Init RC Script Packaging**: Ensure `ruan_init.qcom.rc` and `ruan_init.target.rc` are included in `PRODUCT_PACKAGES`.
