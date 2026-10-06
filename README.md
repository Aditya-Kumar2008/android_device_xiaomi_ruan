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

## Building (InfinityX)

```bash
source build/envsetup.sh
lunch infinity_ruan cp2a user      # stable build
mka bacon -j$(nproc)
```
