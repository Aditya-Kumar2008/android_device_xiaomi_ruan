# Applied Fixes


- **Blocker**: Non-standard prebuilt variables in BoardConfig
- **Root cause**: `TARGET_PREBUILT_KERNEL` and `TARGET_PREBUILT_DTB` are not recognized standard AOSP/Lineage build system variables.
- **Files changed**: `BoardConfig.mk`
- **Risk**: Very Low
- **Rollback command**: `git revert HEAD`

- **Blocker**: dtb/dtbo path mismatches
- **Root cause**: README instructions stated dtb.img and dtbo.img belonged in `prebuilt/`, but `BoardConfig.mk` looked for them in `dtb/`.
- **Files changed**: `BoardConfig.mk`, moved `dtb/` files to `prebuilt/`
- **Risk**: Low
- **Rollback command**: `git revert HEAD && mv prebuilt/dtb.img dtb/dtb.img && mv prebuilt/dtbo.img dtb/dtbo.img && mv prebuilt/dtbs dtb/dtbs`

- **Blocker**: Invalid `DEVICE_PRODUCT_COMPATIBILITY_MATRIX_FILE` entry
- **Root cause**: Adding `framework_compatibility_matrix.xml` to device matrix generates VINTF errors.
- **Files changed**: `BoardConfig.mk`
- **Risk**: Low
- **Rollback command**: `git revert HEAD`

- **Blocker**: Kernel excluded from recovery image
- **Root cause**: `BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE` was set to true, which breaks recovery on devices that don't exclusively rely on `vendor_boot` for recovery ramdisk and kernel loading. Since stock has a 100MB recovery partition, it needs its own kernel.
- **Files changed**: `BoardConfig.mk`
- **Risk**: Medium
- **Rollback command**: `git revert HEAD`
