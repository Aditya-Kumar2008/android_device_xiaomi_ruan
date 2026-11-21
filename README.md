# Device tree for Redmi Pad Pro 5G / POCO Pad 5G (ruan) — PenguinOS 17

| Device       | Redmi Pad Pro 5G / POCO Pad 5G                  |
|-------------:|:------------------------------------------------|
| Codename     | ruan                                            |
| SoC          | Qualcomm Snapdragon 7s Gen 2 (SM7435, parrot)   |
| CPU          | 4x Cortex-A78 @ 2.4 GHz + 4x Cortex-A55 @ 1.95 GHz |
| GPU          | Adreno 710                                      |
| Display      | 12.1" 2560x1600 LCD, 120 Hz                     |
| Battery      | 10000 mAh, 33 W                                 |
| Kernel       | Linux 5.10 GKI (android12-5.10)                 |
| Shipped with | Android 14, HyperOS                             |

Maintained by Aditya (Aditya-Kumar2008).

This branch (`penguinos-17`) targets **PenguinOS 17** (Paranoid Android based,
branch `celerity`). The ROM product (`aospa_ruan`) is registered through the
patch in `patches/vendor/aospa/`, following PenguinOS's central product list.

## Building

Set up the PenguinOS source:

```bash
mkdir -p ~/android/penguinos-17 && cd ~/android/penguinos-17
repo init -u https://github.com/Project-PenguinOS/manifest -b celerity --git-lfs
```

Copy `manifest/ruan.xml` into `.repo/local_manifests/` and sync:

```bash
repo sync -c --no-tags -j8
```

Apply the build patches carried in this tree:

```bash
for d in build/make frameworks/base frameworks/native vendor/aospa; do
    (cd $d && git am -3 $ANDROID_BUILD_TOP/device/xiaomi/ruan/patches/$d/*.patch)
done
```

Then build:

```bash
source build/envsetup.sh
lunch aospa_ruan-userdebug
m bacon
```

The finished ROM zip lands in `out/target/product/ruan/`.

## Credits

- The LineageOS Project and Project PenguinOS for the base
- Xiaomi for publishing the ruan kernel sources (MiCode `ruan-u-oss`)
