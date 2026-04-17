# Device Tree for Poco Pad 5G / Redmi Pad Pro 5G (ruan)

## ⚠️ IMPORTANT: 5G Device Specific Configuration

This device tree is specifically for **ruan** (5G variant) NOT **dizi** (WiFi variant).
- **ruan** = Poco Pad 5G / Redmi Pad Pro 5G (with cellular/5G modem)
- **dizi** = Redmi Pad Pro WiFi (no cellular/5G)

Key differences:
- ruan has 5G modem (md1img partition)
- ruan has RIL (Radio Interface Layer) for telephony
- ruan has different partition sizes
- ruan requires modem firmware

## Device Specifications

| Feature | Specification |
|---------|--------------|
| SoC | Qualcomm SM7435-AB Snapdragon 7s Gen 2 (4 nm) |
| CPU | Octa-core (4x2.40 GHz Cortex-A78 & 4x1.95 GHz Cortex-A55) |
| GPU | Adreno 710 |
| Memory | 6/8 GB RAM (LPDDR4X) |
| Storage | 128/256 GB (UFS 2.2) |
| Display | 12.1 inches, 2560 x 1600 pixels, IPS LCD, 120Hz |
| Battery | 10000 mAh, non-removable, 33W fast charge |
| Rear Camera | 8 MP |
| Front Camera | 8 MP |
| Network | 5G NR, LTE, 3G, 2G |
| OS | Android 15, HyperOS 2.0 |
| Codename | ruan |

## Partition Layout (Accurate for ruan)

| Partition | Size | Notes |
|-----------|------|-------|
| boot | 8 MB | Kernel + ramdisk |
| vendor_boot | 64 MB | Vendor ramdisk |
| dtbo | 8 MB | Device Tree Blob |
| md1img | 128 MB | **5G MODEM - Critical for ruan** |
| super | ~8.5 GB | Dynamic partitions |
| vbmeta | 8 MB | Verified Boot metadata |
| vbmeta_system | 8 MB | System VB metadata |
| vbmeta_vendor | 8 MB | Vendor VB metadata |

## Building Instructions

### Prerequisites

- A Linux-based operating system (Ubuntu 20.04+ LTS recommended)
- `repo` tool installed and configured
- Sufficient disk space (250GB+ recommended)
- AOSP/LineageOS Source

### Initialize Repo

```bash
mkdir -p ~/android/lineage
cd ~/android/lineage
repo init -u https://github.com/LineageOS/android.git -b lineage-22.0 --git-lfs
```

### Create Local Manifest

Create `.repo/local_manifests/ruan.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <!-- Device tree -->
  <project name="your-github/android_device_xiaomi_ruan" 
           path="device/xiaomi/ruan" 
           remote="github" 
           revision="main" />
  
  <!-- Vendor tree -->
  <project name="your-github/android_vendor_xiaomi_ruan" 
           path="vendor/xiaomi/ruan" 
           remote="github" 
           revision="main" />
  
  <!-- Kernel - Using garnet kernel as base (same SM7435 platform) -->
  <project name="MiCode/Xiaomi_Kernel_OpenSource" 
           path="kernel/xiaomi/sm7435" 
           remote="github" 
           revision="garnet-t-oss" />
  
  <!-- Hardware Xiaomi -->
  <project name="LineageOS/android_hardware_xiaomi" 
           path="hardware/xiaomi" 
           remote="github" 
           revision="lineage-22" />
</manifest>
```

### Sync Source

```bash
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
```

### Extract Vendor Blobs

1. Download the stock ROM for your device from [xiaomirom.com](https://xiaomirom.com/rom/redmi-pad-pro-5g-poco-pad-5g-ruan-global-fastboot-recovery-rom/)
2. Extract the payload.bin from the ROM zip
3. Extract vendor.img and system.img
4. Mount the images and extract the blobs:

```bash
cd device/xiaomi/ruan
./extract-files.sh /path/to/extracted/system_and_vendor
```

**IMPORTANT for 5G:** Make sure to extract the modem firmware from md1img partition:
```bash
# Extract md1img from payload
python3 /path/to/lineage/scripts/update-payload-extractor/extract.py payload.bin --output_dir ./images

# The md1img will be in images/md1img.img
# Copy modem firmware to vendor tree
```

### Build

```bash
cd ~/android/lineage
source build/envsetup.sh
breakfast ruan
mka bacon -j$(nproc --all)
```

The resulting ROM zip will be in `out/target/product/ruan/`.

## Kernel Source

**Xiaomi has NOT officially released the kernel source for ruan.** This device tree uses the **garnet kernel source** (same SM7435 platform) as a base.

### Using Prebuilt Kernel (Recommended for Initial Bringup)

Set in your build environment:
```bash
export TARGET_FORCE_PREBUILT_KERNEL=true
```

Place extracted kernel files in:
- `device/xiaomi/ruan/prebuilt/kernel`
- `device/xiaomi/ruan/prebuilt/dtb.img`
- `device/xiaomi/ruan/prebuilt/dtbo.img`

To extract from stock ROM:
```bash
# Extract boot.img
python3 /path/to/lineage/system/tools/mkbootimg/unpack_bootimg.py --boot_img boot.img --out ./boot_extracted

# Copy kernel and dtb
cp boot_extracted/kernel device/xiaomi/ruan/prebuilt/kernel
cp boot_extracted/dtb device/xiaomi/ruan/prebuilt/dtb.img
cp dtbo.img device/xiaomi/ruan/prebuilt/dtbo.img
```

## Hardware Differences from Garnet (Reference Phone)

| Component | Garnet (Phone) | Ruan (Tablet) |
|-----------|---------------|---------------|
| Display | 6.67" AMOLED | 12.1" IPS LCD |
| Resolution | 2712x1220 | 2560x1600 |
| Density | 480 DPI | 320 DPI |
| Battery | 5100mAh | 10000mAh |
| Charging | 67W | 33W |
| Cameras | Triple rear (200MP) | Single 8MP |
| Audio | Stereo speakers | Quad speakers |
| Fingerprint | Yes | No |
| Network | 5G | 5G (same modem) |

## 5G Specific Configurations

This device tree includes:
- md1img partition for modem firmware
- RIL (Radio Interface Layer) configurations
- 5G NR band support (n1, n3, n5, n7, n8, n20, n28, n38, n40, n41, n66, n77, n78)
- VoLTE/VoWiFi support
- IMS (IP Multimedia Subsystem) configurations
- Carrier aggregation support

## Known Issues and TODOs

1. **Kernel Source**: Xiaomi hasn't released ruan kernel source. Using garnet kernel as base.
2. **Display Panel**: 12.1" IPS LCD driver may need adjustment from phone AMOLED.
3. **Touchscreen**: Tablet touchscreen firmware may differ from phone.
4. **Battery/Charging**: 10000mAh battery profile needs tablet-specific tuning. Battery profile tuning requires empirical testing and potentially kernel modifications.
5. **Camera**: Single 8MP camera HAL simplified from triple camera setup.
6. **Audio**: Quad speaker configuration verified and implemented.

## Troubleshooting

### No 5G/Cellular Connection
- Verify md1img partition is flashed correctly
- Check modem firmware in vendor/firmware/
- Verify RIL is loading: `logcat -b radio | grep RIL`

### Bootloop
- Check kernel cmdline parameters in BoardConfig.mk
- Verify dtb/dtbo are correct for your device
- Check fstab.qcom partition mount points

### Display Issues
- Verify panel driver in kernel
- Check display density settings (320 DPI for tablet)
- Verify DSI configuration

### Touch Issues
- Check touchscreen driver
- Verify firmware files are present
- Check touch controller initialization

## Credits

- **Garnet Device Tree**: Base for SM7435 platform support (crdroidandroid)
- **Xiaomi**: For the device
- **LineageOS Team**: For the ROM base
- **TWRP Device Tree Generator**: For initial device tree structure reference

## License

```
Copyright (C) 2024 The LineageOS Project
Copyright (C) 2024 The Android Open Source Project

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

## Support

For support and discussion:
- XDA Forums: [Poco Pad 5G / Redmi Pad Pro 5G](https://xdaforums.com/)
- LineageOS IRC: #lineageos on Libera.Chat
- GitHub Issues: Report issues on your device tree repository

---

**Note**: This device tree is a community effort. Contributions and improvements are welcome!

**WARNING**: This is for the 5G variant (ruan) only. Do NOT use on WiFi variant (dizi)!
