# ruan — Android 17 (InfinityX + crDroid)

Build tooling for the Redmi Pad Pro 5G / Poco Pad 5G (`ruan`, SM7435 "parrot").

Everything below runs on the build server (`34.125.168.122`), not in the agent
sandbox — the sandbox is 4 cores / 72G and is recycled, so nothing built there
survives.

## What is in this repository

| Path | Purpose |
| --- | --- |
| `tools/local_manifests/ruan_infinityx.xml` | `repo` overlay for InfinityX |
| `tools/local_manifests/ruan_crdroid.xml` | `repo` overlay for crDroid |
| `server_bootstrap.sh` | Disk clean, build dependencies, `repo`, ccache |
| `build_rom.sh` | Sync, build and upload one ROM |

Device, kernel and vendor trees live in their own repositories:

- `android_device_xiaomi_ruan` — branch `17.0`
- `device_xiaomi_ruan-kernel` — branch `17.0`
- `android_vendor_xiaomi_ruan` — branch `17.0`

## First run

Copy this repository to the server, then:

```bash
# 1. See what would be freed. Deletes nothing.
tools/server_bootstrap.sh --dry-run

# 2. Clean the disk and install everything.
tools/server_bootstrap.sh --yes

# 3. Build InfinityX.
tools/build_rom.sh infinityx
```

`build_rom.sh` uploads to two independent hosts before it exits. Only start the
second ROM once the first has uploaded successfully:

```bash
tools/build_rom.sh crdroid
```

## Why the device tree was rebuilt

The previous tree (`android_device_xiaomi_ruan`, branch `ruan_device_tree`) was
built for minimum time-to-boot and carries the compromises that implies:
`ALLOW_MISSING_DEPENDENCIES := true`, SELinux permissive, stub audio, and no
telephony, pen or XiaomiParts.

This tree starts from the dizi Android 17 base that is known to boot on this
hardware, and keeps full hardware support. The ruan-specific pieces were carried
across from the stock vendor tree rather than re-derived.

## ruan versus dizi

`ruan` is the 5G model; `dizi` is the Wi-Fi only one. The two share almost all
hardware. The differences this tree handles:

- **Telephony** — `full_base_telephony.mk`, the RIL vendor service
  (`ENABLE_VENDOR_RIL_SERVICE`), `TelephonyOverlayRuan`, `CarrierConfigOverlayRuan`,
  and the `privapp-permissions-ruanpen.xml` system_ext copy.
- **GNSS** — `android.hardware.location.gps.xml`; dizi has no GPS.
- **Device manifest** — `configs/hidl/manifest_ruan.xml` is added alongside the
  shared one, so the RIL and GNSS HALs are declared.
- **Device tree blob** — the ruan stock `dtbo.img` carries entries for both
  boards and is used verbatim. The dizi dtbo has no camera nodes in its ruan
  entry, so using it would leave the camera dead.
- **Sensor configs** — `dizi_hx903x_2_0.json` and `dizi_sar_algo.json` keep their
  original filenames, because the sensor HAL looks them up by that exact name.
  They are not renamed.

## Both ROMs from one tree

`lineage_ruan.mk` inherits the ROM common config conditionally:

```make
$(call inherit-product-if-exists, vendor/lineage/config/common_full_tablet.mk)
$(call inherit-product-if-exists, vendor/infinity/config/common_full_tablet.mk)
$(call inherit-product-if-exists, vendor/crdroid/config/common_full_tablet.mk)
```

InfinityX ships `vendor/infinity`, crDroid ships `vendor/crdroid` plus its
`vendor/lineage` fork. Only the one that exists is pulled in, so the same device
tree serves both builds.

The product is `lineage_ruan` on both ROMs — crDroid names its products
`lineage_<device>` too, so no renaming is needed.

## Updating the trees

After editing any of the three trees locally:

```bash
cd android_device_xiaomi_ruan
git add -A && git commit -m "..." && git push origin HEAD:refs/heads/17.0
```

Then re-run `build_rom.sh`. The local manifest pins the `17.0` branch of each
repository, so a sync picks the change up.

## Notes

- Builds are `userdebug`. Switch to `user` in `build_rom.sh` for a release build.
- `build_rom.sh` refuses to start with less than 250G free.
- `server_bootstrap.sh` only removes build trees and caches. It never touches
  `~/.ssh`.
