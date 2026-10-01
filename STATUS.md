# Status

## Blocked

SSH to the build server is not working.

```
ssh adityarohilla2023@34.125.168.122
-> Permission denied (publickey)
```

The server is up (`OpenSSH 9.6p1 Ubuntu-3ubuntu13.19`) and offers publickey
authentication only. The key below is rejected for the account
`adityarohilla2023` and for every other name tried (`ubuntu`, `openhands`,
`aditya`, `root`, `admin`, `gcpuser`, `user`, `openhands_build`).

The key was working earlier. The agent sandbox is recycled between sessions and
the GCP instance metadata entry did not survive it. Re-adding the key to the
instance metadata is the only way to restore access — it cannot be done from the
sandbox, which has no GCP credentials and is not the build host.

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICwQkqqHD2pfkIX2vdBEqeusn0NQ5pNG5hfayXXfmr4J openhands-build-agent
```

Add it under Compute Engine -> VM instance -> Edit -> SSH Keys, or:

```bash
gcloud compute instances add-metadata INSTANCE \
  --metadata ssh-keys="adityarohilla2023:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICwQkqqHD2pfkIX2vdBEqeusn0NQ5pNG5hfayXXfmr4J openhands-build-agent"
```

Once it is in, everything else is ready to run:

```bash
git clone https://github.com/Aditya-Kumar2008/android_device_xiaomi_ruan -b 17.0
cd android_device_xiaomi_ruan

tools/server_bootstrap.sh --dry-run    # see what would be freed, deletes nothing
tools/server_bootstrap.sh --yes        # clean the disk, install deps

tools/build_rom.sh space               # check free space
tools/build_rom.sh infinityx           # free space, sync, build, upload

tools/build_rom.sh clean               # reclaim space
tools/build_rom.sh crdroid             # free space, sync, build, upload
```

## Done

Three trees are published on branch `17.0`:

| Repository | Contents |
| --- | --- |
| `android_device_xiaomi_ruan` | Device tree and build tooling |
| `device_xiaomi_ruan-kernel` | GKI `Image`, `dtb`, `dtbo.img`, vendor modules |
| `android_vendor_xiaomi_ruan` | Blobs from `OS3.0.303.0.WFSMIXM` |

Local manifests for both ROMs are in `tools/local_manifests/`. Both were checked
against the full InfinityX and crDroid manifests — no path collisions.

## Not started

Nothing has been built yet. The disk clean, the InfinityX build, the crDroid
build and the uploads all require the build host, so none of them could begin.

## Branch audit

No branch is a duplicate of another; every tree hash is distinct. Details:

**`android_device_xiaomi_ruan`**

| Branch | Last commit | Verdict |
| --- | --- | --- |
| `17.0` | 2026-09-30 | Current. Keep. |
| `ruan_device_tree` | 2026-08-29 | Superseded by `17.0`. Delete once the new build boots. |
| `main` | 2026-06-29 | Keep. |
| `lineage-22.1` | 2026-04-17 | Keep for history. |
| `lineage-22` | 2026-04-17 | Keep for history. |
| `lineage-21` | 2026-04-17 | Keep for history. |

**`device_xiaomi_ruan-kernel`** — `main` (`kernel-ruan-artefacts-base`) and
`17.0` are different trees. Both keep.

**`android_vendor_xiaomi_ruan`** — `lineage-22.1` and `17.0` are different trees.
Both keep.

**`Ruan_device_tree`** — a separate repository duplicating the device tree, with
six branches: `LineageOS-22.1` (default), `lineage-23`, `main`, `vendor`,
`merge/opus-ruan`, `merge/vendor-ruan`. This is where the real duplication is.
It was not touched, because deciding which of those branches is the canonical
one needs your call.

## Also worth deciding

`android_hardware_xiaomi`, `android_kernel_xiaomi_ruan`,
`android_kernel_xiaomi_sm7435-devicetrees` and
`android_kernel_xiaomi_sm7435-modules` are forks of upstream projects. The
device tree pulls `hardware/xiaomi` from `LineageOS` (`lineage-24.0`) and
`crdroidandroid` (`17.0`) rather than from these forks, since the upstream
branches track Android 17. Point the local manifest at your forks instead if you
would rather keep the changes local.
