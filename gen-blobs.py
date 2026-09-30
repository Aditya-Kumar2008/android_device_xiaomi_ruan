#!/usr/bin/env python3
"""Generate proprietary-files.txt for ruan.

Starts from the garnet list, keeps entries that exist in the ruan stock dump
(dropping sha1 pins, since ruan's copies differ), adds ruan-only groups, then
closes the set over ELF DT_NEEDED so nothing a listed blob links against is
left out. Libraries that the ROM builds from source are skipped.

Usage: gen-blobs.py [--telephony] [--source=<rom>] <garnet-list> <dump-dir> <source-tree> > proprietary-files.txt

--telephony keeps garnet's modem, IMS, eMBMS and secure element blobs (ruan,
the 5G model); by default they are dropped for the Wi-Fi-only ruan.
--source names the stock ROM in the header comment.
"""

import re
import subprocess
import sys
from pathlib import Path

BLOB_PARTS = ('vendor', 'odm', 'system', 'system_ext', 'product')

# Garnet sections that make no sense on the Wi-Fi-only tablet. Note that
# garnet's 'RIL' section also carries platform daemons ruan needs (pd-mapper,
# rmt_storage, tftp_server, qti, ...), so only its modem/IMS daemons go.
SKIP_SECTIONS = ('EMBMS', 'IMS', 'Fingerprint', 'NFC', 'Secure element', 'ESE powermanager')
SKIP_SECTIONS_TELEPHONY = ('Fingerprint', 'NFC', 'ESE powermanager')
SKIP_ENTRIES = re.compile(r'(qcrilNrd|imsdaemon|ims_rtp_daemon|ATFWD-daemon)(\.rc)?$'
                          # Telephony apps crash-loop without a modem (build-13).
                          r'|QtiTelephony(Service)?\.apk|priv-app/ims/|qcrilmsgtunnel|AtFwd2|libims(camera|media)_jni'
                          # Modem data daemons: stock ruan never runs them (build-21).
                          r'|etc/init/(dataadpl|dataqti|modemManager|netmgrd|port-bridge)\.rc')

# Globs (relative to the dump) for ruan-specific groups.
EXTRA: dict[str, list[str]] = {
    'Camera': [
        'vendor/bin/hw/vendor.qti.camera.provider@2.7-service_64',
        'vendor/etc/init/vendor.qti.camera.provider@2.7-service_64.rc',
        'vendor/lib64/hw/camera.qcom.so',
        'vendor/lib64/hw/com.qti.chi.override.so',
        'vendor/lib64/camera/**',
        'vendor/etc/camera/**',
    ],
    # Stock (Xiaomi-patched) SDM core under the source composer: the source
    # core reports dpi 24.95 (panel size is in 0.1 mm) and its scaler input
    # fails for rotated video (research/display-composer.md). The prefer:true
    # prebuilt replaces the source libsdmcore module. Its new dependency
    # vendor.xiaomi.hardware.displayfeature@1.0 is built from hardware/xiaomi.
    # vendor/lib too: PRODUCT_PACKAGES installs every arch of the name, so a
    # 64-bit-only prebuilt would drag in the 32-bit source core and its deps.
    'Display (stock SDM core)': [
        'vendor/lib/libsdmcore.so',
        'vendor/lib64/libsdmcore.so',
    ],
    'Display panel configs': [
        'odm/etc/disp0/**',
        'odm/etc/display/**',
        'vendor/etc/display/**',
    ],
    'Sensors configs': [
        'vendor/etc/sensors/**',
    ],
    'Touchscreen': [
        'vendor/firmware/novatek_ts_*.bin',
    ],
    'Audio configs': [
        'vendor/etc/acdbdata/**',
    ],
    # Without it the speaker amps never power up: no sound at all (build-16).
    # garnet's list has the binary but not the rc, so it never started (build-21).
    'Batterysecret': [
        'vendor/etc/init/init.batterysecret.rc',
    ],
    'Speaker amplifier firmware': [
        'vendor/firmware/sipa.bin',
        'vendor/firmware/fs1815.fsm',
    ],
    # garnet's list has c2_manifest_vendor.xml; ruan names it after the SoC.
    # Without it the QTI video codec store cannot register (build-15).
    'Media': [
        'vendor/etc/vintf/manifest/c2_manifest_vendor_parrot.xml',
    ],
    'Thermal': [
        'vendor/bin/mi_thermald',
        'vendor/bin/thermal-engine-v2',
        'vendor/etc/init/init_thermal-engine-v2.rc',
        'vendor/etc/init/init.mi_thermald.rc',
        'vendor/etc/thermal-*.conf',
    ],
}

# Extra groups for --telephony (ruan) that garnet's list lacks.
EXTRA_TELEPHONY: dict[str, list[str]] = {
    'RIL database': [
        'vendor/etc/qcril_database/**',
    ],
    'RIL (ruan)': [
        'vendor/bin/ccid_daemon_nr',
        'vendor/etc/vintf/manifest/vendor.qti.hardware.radio.qtiradioconfig.xml',
    ],
}


def dump_path(src: str) -> str:
    """Map a list entry source to its path relative to the dump."""
    return src if src.split('/')[0] in BLOB_PARTS else f'system/{src}'


def glob_dump(dump: Path, pattern: str) -> list[str]:
    """Glob relative to the dump; '**' matches across directories."""
    return sorted(str(p.relative_to(dump)) for p in dump.glob(pattern)
                  if p.is_file() or p.is_symlink())


def source_built_names(src_tree: Path) -> set[str]:
    """Module names the source tree can build (Android.bp / Android.mk)."""
    names: set[str] = set()
    dirs = [src_tree / d for d in ('hardware', 'prebuilts/misc', 'vendor/qcom/opensource', 'vendor/lineage',
                                   'frameworks', 'system', 'external', 'device/qcom')]
    res = subprocess.run(
        ['grep', '-rhoE', '--include=Android.bp', '--include=Android.mk',
         r'((name|stem):\s*"[^"]+"|LOCAL_MODULE(_STEM)?\s*:=\s*\S+)', *map(str, filter(Path.is_dir, dirs))],
        capture_output=True, text=True)
    for match in res.stdout.splitlines():
        names.add(re.split(r'[":= ]+', match.strip().rstrip('"'))[-1])
    return names


# '-ndk_platform' libraries are relinked to the source-built '-ndk' variant
# by the lib_fixups in extract-files.py, so they count as built when the
# source tree has the AIDL interface. Otherwise (ruan's radio and gnss
# interfaces) the blob itself is needed.
def source_built_ndk_platform(lib: str, built: set[str]) -> bool:
    m = re.fullmatch(r'(.+)-V\d+-ndk_platform\.so', lib)
    return m is not None and m.group(1) in built


def needed(path: Path) -> list[str]:
    res = subprocess.run(['readelf', '-dW', str(path)], capture_output=True, text=True)
    return re.findall(r'\(NEEDED\).*\[(.+?)\]', res.stdout)


def elf_class(path: Path) -> int | None:
    try:
        with path.open('rb') as f:
            head = f.read(5)
    except OSError:
        return None
    if head[:4] != b'\x7fELF':
        return None
    return 64 if head[4] == 2 else 32


def main() -> None:
    args = sys.argv[1:]
    telephony = '--telephony' in args
    if telephony:
        args.remove('--telephony')
    source = 'ruan_global OS3.0.303.0.WNSEUXM'
    for arg in [a for a in args if a.startswith('--source=')]:
        source = arg.removeprefix('--source=')
        args.remove(arg)
    garnet_list, dump, src_tree = map(Path, args)
    skip_sections = SKIP_SECTIONS_TELEPHONY if telephony else SKIP_SECTIONS
    exists = lambda rel: (dump / rel).exists() or (dump / rel).is_symlink()

    sections: dict[str, list[str]] = {}
    listed: set[str] = set()

    # 1. Garnet entries that exist on ruan.
    section = 'Misc'
    for line in garnet_list.read_text().splitlines():
        if line.startswith('#'):
            section = line.lstrip('# ').strip()
            continue
        if not line.strip() or section.startswith(skip_sections):
            continue
        entry = line.split('|')[0]
        body = entry.lstrip('-')
        prefix = entry[:len(entry) - len(body)]
        spec, _, flags = body.partition(';')
        src, _, dst = spec.partition(':')
        if not telephony and SKIP_ENTRIES.search(src):
            continue
        if not exists(dump_path(src)):
            # Pinned blob imported from another device: use ruan's own copy.
            if dst and exists(dump_path(dst)):
                src, dst = dst, ''
            else:
                continue
        if telephony:
            # garnet rebuilds qcrilNr.db from these; ruan ships the stock database and sql as is.
            flags = ';'.join(f for f in flags.split(';') if f and not f.startswith('FILEGROUP='))
        new = prefix + src + (f':{dst}' if dst else '') + (f';{flags}' if flags else '')
        sections.setdefault(section, []).append(new)
        listed.add(dump_path(src))

    # 2. Ruan-only groups.
    for section, patterns in (EXTRA | EXTRA_TELEPHONY if telephony else EXTRA).items():
        for pattern in patterns:
            for rel in glob_dump(dump, pattern):
                if rel not in listed:
                    sections.setdefault(section, []).append(rel)
                    listed.add(rel)

    # 3. Close over DT_NEEDED, using only the default library search dirs.
    built = source_built_names(src_tree)
    lib_index: dict[tuple[str, int], str] = {}
    for part in ('vendor', 'odm'):
        for sub, cls in (('lib', 32), ('lib64', 64)):
            base = dump / part / sub
            if base.is_dir():
                for p in base.iterdir():
                    if p.is_file():
                        lib_index.setdefault((p.name, cls), str(p.relative_to(dump)))

    # extract-utils names modules by basename, so a library already listed in
    # another directory (e.g. lib64/egl/) must not be added a second time.
    def lib_key(rel: str) -> tuple[str, int | None]:
        return Path(rel).name, elf_class(dump / rel)

    listed_libs = {lib_key(p) for p in listed if p.endswith('.so')}
    queue = [p for p in listed if p.split('/')[0] in ('vendor', 'odm')]
    added: list[str] = []
    while queue:
        rel = queue.pop()
        cls = elf_class(dump / rel)
        if cls is None:
            continue
        for lib in needed(dump / rel):
            hit = lib_index.get((lib, cls))
            if (hit is None or hit in listed or (lib, cls) in listed_libs
                    or source_built_ndk_platform(lib, built) or lib.removesuffix('.so') in built):
                continue
            listed.add(hit)
            listed_libs.add((lib, cls))
            added.append(hit)
            queue.append(hit)
    if added:
        sections.setdefault('Dependencies (DT_NEEDED closure)', []).extend(added)

    out = [f'# All unpinned blobs are extracted from {source}']
    for section, entries in sections.items():
        out.append(f'\n# {section}')
        out.extend(sorted(set(entries), key=lambda e: e.lstrip('-').lower()))
    print('\n'.join(out))


if __name__ == '__main__':
    main()
