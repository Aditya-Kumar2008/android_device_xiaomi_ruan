# Device tree for Redmi Pad Pro 5G / POCO Pad 5G (`ruan`)

Standalone device tree for the Xiaomi `ruan` (SM7435, Qualcomm "parrot" platform).

| | |
|---|---|
| SoC | Qualcomm Snapdragon 7s Gen 2 (SM7435) |
| Platform | `parrot` |
| Model | 24074RPD2G |
| Vendor base | HyperOS `OS3.0.303.0.WFSMIXM` |

## Credits

This tree is built on the work of others and would not exist without them.

- **[@noble6](https://github.com/noble6)** — original `device_xiaomi_ruan` bring-up tree
  (AxionOS). The device configuration, overlays, `parts`, `pen`, `power` and rootdir work in
  this repository originate from his tree. Thank you.
- **[Evolution-X-Devices](https://github.com/Evolution-X-Devices)** — `hardware_xiaomi`
  (`bka-no-dolby`), the `kernel_xiaomi_garnet` / `kernel_xiaomi_garnet-modules` header trees
  (`bka`), and `packages_apps_GameBar`.
- **[nekoshirro](https://github.com/nekoshirro)** — `android_hardware_dolby` (`lunaris`).

## Branch layout

One branch per ROM, all sharing the same device configuration:

| Branch | ROM | Android |
|---|---|---|
| `infinityx` | InfinityX | 16 |
| `axion` | AxionOS (upstream reference) | 16 |

## Manifest

`manifest/ruan.xml` is a self-contained local manifest — the device tree, kernel artefacts
and vendor blobs are all declared there. After `repo init`:

```bash
mkdir -p .repo/local_manifests
cp device/xiaomi/ruan/manifest/ruan.xml .repo/local_manifests/
repo sync -c --force-sync --no-clone-bundle
```

## Platform patches

The platform repos need three patches to build and run correctly on `ruan`. They live under
`patches/` and are applied by `apply-patches.sh` after `repo sync`:

| Patch | Repo | Purpose |
|---|---|---|
| `0001-renderengine-Force-realtime-Vulkan-queue-priority-wh.patch` | `frameworks/native` | Adreno driver exposes `VK_EXT_global_priority` but not the query extension, leaving the Vulkan RenderEngine queue at MEDIUM behind app GPU work. Retries device creation at REALTIME/HIGH/MEDIUM. |
| `0001-releasetools-accept-target-files-zips-in-PartitionMa.patch` | `build/make` | `PartitionMapFromTargetFiles` assumed an extracted directory, so signing/OTA on a target-files zip crashed. Looks the subdirs up in the zip name list. |
| `0001-config-Prefix-the-kernel-out-dir-for-any-relative-OU.patch` | `vendor/infinity` | `KERNEL_BUILD_OUT_PREFIX` was only set for `OUT_DIR=out`; any other relative out dir made the kernel write headers into its own checkout. |

```bash
./device/xiaomi/ruan/apply-patches.sh
```

The patches are authored by Alexander Gurov (`aliogu23@gmail.com`) and are redistributed here
unchanged.

## Building (InfinityX)

```bash
source build/envsetup.sh
lunch infinity_ruan cp2a user      # stable build
mka bacon -j$(nproc)
```
