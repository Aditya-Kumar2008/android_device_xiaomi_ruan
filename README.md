# Device tree for the Redmi Pad Pro (ruan), Evolution X bka (Android 16)

Redmi Pad Pro Wi-Fi, codename `ruan`, SM7435 ("parrot"). Not for the 5G model (`ruan`).
This tree started as a fork of the Evolution X garnet (Redmi Note 13 Pro 5G) tree, which uses the same SoC.

## Building

1. `repo init -u https://github.com/Evolution-X/manifest -b bka --git-lfs`
2. Copy [`ruan.xml`](https://github.com/g8row/ruan-bringup/blob/main/release/manifest/ruan.xml) to
   `.repo/local_manifests/`.
3. `repo sync`
4. Apply the platform patches in `patches/<project path>/` with `git am` in each project.
5. Build:
   ```
   source build/envsetup.sh && lunch lineage_ruan-bp4a-user && m evolution
   ```

## Platform patches

| Project | Patch |
|---|---|
| `system/core` | init: keep `/data/resource-cache` on upgrade |
| `vendor/gms` | CrossDeviceAccessServicePrimary uses-library match |
| `vendor/lineage` | kernel out dir prefix for any relative `OUT_DIR` (release builds) |
| `frameworks/native` | RenderEngine: realtime Vulkan queue priority |
| `build/make` | releasetools: `PartitionMapFromTargetFiles` accepts a ZipFile (signing) |

## Kernel

`device/xiaomi/ruan-kernel` holds the kernel artefacts:
- the GKI Image built from LineageOS `android_kernel_xiaomi_sm7435` (5.10.269);
- the stock OS3.0.303.0 dtb, dtbo and modules, which are CRC-compatible with that Image;
- `msm_drm.ko` built from Xiaomi's `ruan-u-oss` display-driver source, plus a fix for the bootloader's
  60 Hz splash handover.

The switches are in `BoardConfig.mk`:
- `RUAN_SOURCE_KERNEL` (default `true`);
- `RUAN_SOURCE_DISPLAY` (default `splashfix`).

## Build switches

- `RUAN_SELINUX_PERMISSIVE=true`: permissive, on debuggable builds only. The default is enforcing.
- `RUAN_ADB_KEYS=<adb_keys>`: debuggable builds trust this adb key file (a path relative to the source root).
- `WITH_ADB_INSECURE=true`: adb without authorization on debuggable builds.

## Firmware

The tablet must run HyperOS OS3.0.303.0 or newer. The ROM does not flash firmware partitions.

Bring-up notes, tooling and install instructions are in [ruan-bringup](https://github.com/g8row/ruan-bringup).
