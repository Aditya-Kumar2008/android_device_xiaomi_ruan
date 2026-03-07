# Prebuilt Kernel for POCO Pad 5G (ruan)

## Overview

Since Xiaomi has not released the kernel source code, this device tree uses a **prebuilt kernel** approach.

## Required Files

Place these files in this directory:

1. **kernel** - Kernel image (from `boot.img`)
2. **dtb.img** - Device Tree Blob (from `boot.img`)
3. **dtbo.img** - Device Tree Blob Overlay (from `dtbo.img` partition)

## Extraction Instructions

### From Stock Firmware

```bash
# Extract kernel from boot.img using magiskboot
magiskboot unpack boot.img
mv kernel device/xiaomi/ruan/prebuilt/kernel
mv dtb device/xiaomi/ruan/prebuilt/dtb.img

# Copy dtbo
cp dtbo.img device/xiaomi/ruan/prebuilt/dtbo.img
```

### From Device (ADB - Requires Root)

```bash
# Pull partitions
adb shell su -c "dd if=/dev/block/by-name/boot of=/sdcard/boot.img"
adb shell su -c "dd if=/dev/block/by-name/dtbo of=/sdcard/dtbo.img"
adb pull /sdcard/boot.img
adb pull /sdcard/dtbo.img

# Extract
magiskboot unpack boot.img
mv kernel device/xiaomi/ruan/prebuilt/kernel
mv dtb device/xiaomi/ruan/prebuilt/dtb.img
cp dtbo.img device/xiaomi/ruan/prebuilt/dtbo.img
```

## File Structure

```
prebuilt/
├── kernel          # Required
├── dtb.img         # Required
├── dtbo.img        # Required
└── README.md       # This file
```

## Troubleshooting

- **Bootloop**: Flash stock boot.img to recover
- **Kernel panic**: Verify kernel matches device variant (5G/WiFi)

## Legal Notice

Kernel files are extracted from Xiaomi's stock firmware and subject to their licenses.
