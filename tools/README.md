# ruan build tooling

For the Redmi Pad Pro 5G / Poco Pad 5G (`ruan`, SM7435 "parrot").
Runs on the build host, not in the agent sandbox.

## Flow

```bash
./server_bootstrap.sh --dry-run     # see what would be freed, deletes nothing
./server_bootstrap.sh --yes         # clean the disk, install build deps

./build_rom.sh space                # check free space
./build_rom.sh infinityx            # free space, sync, build, upload

./build_rom.sh clean                # reclaim space
./build_rom.sh crdroid              # free space, sync, build, upload
```

One ROM at a time. `build_rom.sh <rom>` removes the other ROM's tree before it
starts, so the two builds never compete for disk. A build only counts as
finished once the zip has uploaded to two independent hosts; if fewer than two
uploads succeed the script exits non-zero and tells you to upload by hand before
starting the next ROM.

`clean` deletes build trees and repo/bazel caches. It keeps `~/.ccache`,
because rebuilding that from scratch costs hours. It never touches `~/.ssh`.

## Commands

| Command | Effect |
| --- | --- |
| `build_rom.sh space` | Free space, size of each tree, ccache size |
| `build_rom.sh clean` | Delete all build trees and caches, keep ccache |
| `build_rom.sh infinityx` | InfinityX Android 17 |
| `build_rom.sh crdroid` | crDroid Android 17 |

Environment: `ANDROID_ROOT` (default `$HOME/android`), `JOBS` (default `nproc`).

Artifacts are copied to `$ANDROID_ROOT/artifacts/<rom>/` before upload, so a
later clean cannot lose them. Build logs land in `$ANDROID_ROOT/artifacts/`.

## Requirements

250G free before a build starts; the script refuses below that. `repo` must be
on `PATH` (`server_bootstrap.sh` installs it to `~/bin`).

## Repositories

| Path in tree | Repository | Branch |
| --- | --- | --- |
| `device/xiaomi/ruan` | `Aditya-Kumar2008/android_device_xiaomi_ruan` | `17.0` |
| `device/xiaomi/ruan-kernel` | `Aditya-Kumar2008/device_xiaomi_ruan-kernel` | `17.0` |
| `vendor/xiaomi/ruan` | `Aditya-Kumar2008/android_vendor_xiaomi_ruan` | `17.0` |
| `hardware/xiaomi` | `LineageOS/android_hardware_xiaomi` | `lineage-24.0` |
| `hardware/xiaomi` (crDroid) | `crdroidandroid/android_hardware_xiaomi` | `17.0` |

Local manifests are in `local_manifests/`. Both were checked against the full
InfinityX and crDroid manifests - no path collisions.
