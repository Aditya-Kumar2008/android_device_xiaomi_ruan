#!/usr/bin/env python3
#
# Copyright (C) 2024-2026 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

from __future__ import annotations

import argparse
import re
import shutil
from dataclasses import dataclass
from pathlib import Path

PARTITION_PRIORITY = {
    "system_ext": 0,
    "product": 1,
    "system": 2,
    "vendor": 3,
    "odm": 4,
}

KNOWN_PARTITIONS = {
    "odm",
    "product",
    "system",
    "system_ext",
    "vendor",
    "vendor_dlkm",
}

EXCLUDED_NORMALIZED_DESTS = {
    "vendor/etc/audio/sku_parrot/audio_effects.conf",
    "vendor/etc/audio/sku_parrot/audio_policy_configuration.xml",
    "vendor/etc/audio/sku_parrot/mixer_paths_parrot_qrd.xml",
    "vendor/etc/audio/sku_parrot/resourcemanager_parrot_qrd.xml",
    "vendor/etc/audio/sku_parrot_qssi/audio_policy_configuration.xml",
    "vendor/etc/a2dp_audio_policy_configuration.xml",
    "vendor/etc/audio_effects.xml",
    "vendor/etc/audio_policy_configuration.xml",
    "vendor/etc/audio_policy_volumes.xml",
    "vendor/etc/backend_conf.xml",
    "vendor/etc/bluetooth_qti_audio_policy_configuration.xml",
    "vendor/etc/card-defs.xml",
    "vendor/etc/default_volume_tables.xml",
    "vendor/etc/kvh2xml.xml",
    "vendor/etc/libnfc-nci.conf",
    "vendor/etc/media_codecs.xml",
    "vendor/etc/media_codecs_c2_audio.xml",
    "vendor/etc/media_codecs_performance.xml",
    "vendor/etc/media_profiles.xml",
    "vendor/etc/microphone_characteristics.xml",
    "vendor/etc/mixer_paths_overlay_dynamic.xml",
    "vendor/etc/mixer_paths_tavil.xml",
    "vendor/etc/r_submix_audio_policy_configuration.xml",
    "vendor/etc/seccomp_policy/c2audio.vendor.base-arm.policy",
    "vendor/etc/seccomp_policy/c2audio.vendor.base-arm64.policy",
    "vendor/etc/seccomp_policy/c2audio.vendor.ext-arm.policy",
    "vendor/etc/seccomp_policy/c2audio.vendor.ext-arm64.policy",
    "vendor/etc/seccomp_policy/mediacodec.policy",
    "vendor/etc/sensors/hals.conf",
    "vendor/etc/snapdragon_color_libs_config.xml",
    "vendor/etc/usb_audio_policy_configuration.xml",
    "vendor/etc/usecaseKvManager.xml",
    "vendor/etc/wifi/p2p_supplicant_overlay.conf",
    "vendor/etc/wifi/qca6750/WCNSS_qcom_cfg.ini",
    "vendor/etc/wifi/wpa_supplicant_overlay.conf",
}

TEXT_LIKE_SUFFIXES = {
    ".apk",
    ".arsc",
    ".bin",
    ".conf",
    ".csv",
    ".dat",
    ".db",
    ".dlc",
    ".elf",
    ".idl",
    ".ini",
    ".jar",
    ".json",
    ".kl",
    ".mbn",
    ".md",
    ".pb",
    ".pmd",
    ".policy",
    ".prop",
    ".qc",
    ".qwsp",
    ".rc",
    ".soong",
    ".sql",
    ".txt",
    ".xml",
}

ELF_LIB_RE = re.compile(r"^lib(?P<arch>64)?/(?P<subdir>.*?)(?P<name>[^/]+)\.so$")
ELF_BIN_RE = re.compile(r"^bin(?P<arch>64)?/(?P<subdir>.*?)(?P<name>[^/]+)$")


@dataclass(frozen=True)
class BlobEntry:
    src: str
    dest: str
    optional: bool
    args: tuple[str, ...]
    original_line: str

    @property
    def partition(self) -> str:
        partition, _ = split_partition_path(self.dest)
        return partition

    @property
    def partition_dest(self) -> str:
        _, relative_dest = split_partition_path(self.dest)
        return relative_dest

    @property
    def normalized_dest(self) -> str:
        return f"{self.partition}/{self.partition_dest}"

    @property
    def filtered_line(self) -> str:
        line = f"{self.src}:{self.dest}" if self.src != self.dest else self.src
        if self.args:
            line = f"{line};{';'.join(self.args)}"
        if self.optional:
            line = f"-{line}"
        return line


@dataclass
class PrebuiltModule:
    name: str
    kind: str
    partition: str
    stem: str
    relative_install_path: str
    compile_multilib: str
    src32: str | None = None
    src64: str | None = None
    src: str | None = None


def parse_blob_line(line: str) -> BlobEntry | None:
    stripped = line.strip()
    if not stripped or stripped.startswith("#"):
        return None

    optional = stripped.startswith("-")
    payload = stripped[1:] if optional else stripped
    pieces = payload.split(";")
    location = pieces[0]
    args = tuple(piece for piece in pieces[1:] if piece)

    if ":" in location:
        src, dest = location.split(":", 1)
    else:
        src = location
        dest = location

    return BlobEntry(
        src=src.strip().replace("\\", "/"),
        dest=dest.strip().replace("\\", "/"),
        optional=optional,
        args=args,
        original_line=line.rstrip("\n"),
    )


def module_name(*parts: str) -> str:
    sanitized = "_".join(part for part in parts if part)
    sanitized = re.sub(r"[^A-Za-z0-9_]", "_", sanitized)
    sanitized = re.sub(r"_+", "_", sanitized).strip("_")
    return sanitized.lower()


def split_partition_path(path: str) -> tuple[str, str]:
    head, sep, tail = path.partition("/")
    if sep and head in KNOWN_PARTITIONS:
        return head, tail
    return "vendor", path


def priority(entry: BlobEntry) -> int:
    return PARTITION_PRIORITY.get(entry.partition, 99)


def classify(entry: BlobEntry) -> tuple[str, str | None, str]:
    relative_dest = entry.partition_dest
    if relative_dest.startswith(("lib/rfsa/", "lib64/rfsa/")):
        return "copy_file", None, entry.dest

    if relative_dest.startswith(("etc/vintf/manifest", "etc/vintf/manifest/")) and relative_dest.endswith(".xml"):
        return "vintf_manifest", None, entry.dest

    lib_match = ELF_LIB_RE.match(relative_dest)
    if lib_match:
        arch = "64" if lib_match.group("arch") else "32"
        stem = lib_match.group("name")
        return "shared_lib", arch, f"{stem}"

    bin_match = ELF_BIN_RE.match(relative_dest)
    if bin_match and Path(relative_dest).suffix.lower() not in TEXT_LIKE_SUFFIXES:
        arch = "64" if bin_match.group("arch") else "64"
        stem = bin_match.group("name")
        return "binary", arch, stem

    return "copy_file", None, entry.dest


def filtered_entries(entries: list[BlobEntry]) -> tuple[list[BlobEntry], list[str]]:
    unique_dests: dict[str, BlobEntry] = {}
    dropped: list[str] = []
    for entry in entries:
        if entry.normalized_dest in EXCLUDED_NORMALIZED_DESTS:
            dropped.append(f"dropped device-owned config {entry.dest}")
            continue
        unique_dests.setdefault(entry.normalized_dest, entry)

    kept = list(unique_dests.values())
    shared_winners: dict[str, BlobEntry] = {}
    binary_winners: dict[str, BlobEntry] = {}

    for entry in kept:
        kind, _, collision_key = classify(entry)
        if kind not in {"shared_lib", "binary"}:
            continue

        table = shared_winners if kind == "shared_lib" else binary_winners
        winner = table.get(collision_key)
        if winner is None or priority(entry) < priority(winner):
            table[collision_key] = entry

    final_entries: list[BlobEntry] = []
    for entry in kept:
        kind, _, collision_key = classify(entry)
        if kind == "shared_lib":
            winner = shared_winners[collision_key]
            if priority(entry) > priority(winner):
                dropped.append(f"dropped duplicate library {entry.dest} in favor of {winner.dest}")
                continue
        elif kind == "binary":
            winner = binary_winners[collision_key]
            if priority(entry) > priority(winner):
                dropped.append(f"dropped duplicate binary {entry.dest} in favor of {winner.dest}")
                continue
        final_entries.append(entry)

    final_entries.sort(key=lambda item: item.dest)
    return final_entries, dropped


def make_prebuilt_modules(
    entries: list[BlobEntry],
) -> tuple[list[PrebuiltModule], list[BlobEntry], list[BlobEntry]]:
    grouped: dict[str, PrebuiltModule] = {}
    copy_files: list[BlobEntry] = []
    vintf_manifests: list[BlobEntry] = []

    for entry in entries:
        kind, arch, stem = classify(entry)
        if kind == "vintf_manifest":
            vintf_manifests.append(entry)
            continue
        if kind == "copy_file":
            copy_files.append(entry)
            continue

        if kind == "shared_lib":
            match = ELF_LIB_RE.match(entry.partition_dest)
            assert match is not None
            relpath = match.group("subdir").rstrip("/")
            name = module_name(entry.partition, "lib", relpath, stem)
            module = grouped.setdefault(
                name,
                PrebuiltModule(
                    name=name,
                    kind=kind,
                    partition=entry.partition,
                    stem=stem,
                    relative_install_path=relpath,
                    compile_multilib="32",
                ),
            )
            if arch == "64":
                module.src64 = f"proprietary/{entry.src}"
            else:
                module.src32 = f"proprietary/{entry.src}"
            module.compile_multilib = (
                "both"
                if module.src32 and module.src64
                else "64"
                if module.src64
                else "32"
            )
            continue

        match = ELF_BIN_RE.match(entry.partition_dest)
        assert match is not None
        relpath = match.group("subdir").rstrip("/")
        name = module_name(entry.partition, "bin", relpath, stem)
        module = grouped.setdefault(
            name,
            PrebuiltModule(
                name=name,
                kind=kind,
                partition=entry.partition,
                stem=stem,
                relative_install_path=relpath,
                compile_multilib="64",
            ),
        )
        if arch == "32":
            module.src32 = f"proprietary/{entry.src}"
        else:
            module.src64 = f"proprietary/{entry.src}"
        module.compile_multilib = (
            "both"
            if module.src32 and module.src64
            else "64"
            if module.src64
            else "32"
        )

    return sorted(grouped.values(), key=lambda item: item.name), copy_files, vintf_manifests


def partition_specific_property(partition: str) -> str | None:
    if partition in {"vendor", "vendor_dlkm"}:
        return "soc_specific: true,"
    if partition == "odm":
        return "device_specific: true,"
    if partition == "product":
        return "product_specific: true,"
    if partition == "system_ext":
        return "system_ext_specific: true,"
    return None


def emit_android_bp(modules: list[PrebuiltModule]) -> str:
    lines = [
        "// Auto-generated by device/xiaomi/ruan/extract-files.py",
        "",
        "soong_namespace {}",
        "",
    ]

    for module in modules:
        lines.append(f'{module.kind_to_bp()} {{')
        lines.append(f'    name: "{module.name}",')
        lines.append('    owner: "xiaomi",')
        lines.append('    prefer: true,')
        lines.append('    strip: {')
        lines.append('        none: true,')
        lines.append('    },')
        lines.append('    check_elf_files: false,')
        lines.append(f'    compile_multilib: "{module.compile_multilib}",')
        lines.append(f'    stem: "{module.stem}",')
        specific = partition_specific_property(module.partition)
        if specific:
            lines.append(f"    {specific}")
        if module.relative_install_path:
            lines.append(f'    relative_install_path: "{module.relative_install_path}",')
        if module.kind == "shared_lib":
            lines.extend(multilib_block(module, library=True))
        else:
            lines.extend(multilib_block(module, library=False))
        lines.append("}")
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def multilib_block(module: PrebuiltModule, library: bool) -> list[str]:
    lines = ["    multilib: {"]
    if module.src32:
        lines.append("        lib32: {")
        lines.append(f'            srcs: ["{module.src32}"],')
        lines.append("        },")
    if module.src64:
        lines.append("        lib64: {")
        lines.append(f'            srcs: ["{module.src64}"],')
        lines.append("        },")
    lines.append("    },")
    return lines


def emit_vendor_mk(
    modules: list[PrebuiltModule],
    copy_files: list[BlobEntry],
    vintf_manifests: list[BlobEntry],
) -> str:
    lines = [
        "# Auto-generated by device/xiaomi/ruan/extract-files.py",
        "",
        "PRODUCT_SOONG_NAMESPACES += vendor/xiaomi/ruan",
        "",
    ]

    if modules:
        lines.append("PRODUCT_PACKAGES += \\")
        for index, module in enumerate(modules):
            suffix = " \\" if index < len(modules) - 1 else ""
            lines.append(f"    {module.name}{suffix}")
        lines.append("")

    if copy_files:
        lines.append("PRODUCT_COPY_FILES += \\")
        for index, entry in enumerate(copy_files):
            suffix = " \\" if index < len(copy_files) - 1 else ""
            lines.append(
                "    "
                f"vendor/xiaomi/ruan/proprietary/{entry.src}:"
                f"{copy_file_destination(entry)}{suffix}"
            )
        lines.append("")

    vintf_by_partition: dict[str, list[BlobEntry]] = {}
    for entry in vintf_manifests:
        vintf_by_partition.setdefault(entry.partition, []).append(entry)

    manifest_var = {
        "odm": "ODM_MANIFEST_FILES",
        "product": "PRODUCT_MANIFEST_FILES",
        "system_ext": "SYSTEM_EXT_MANIFEST_FILES",
        "vendor": "VENDOR_MANIFEST_FILES",
        "system": "SYSTEM_MANIFEST_FILES",
    }
    for partition, entries in sorted(vintf_by_partition.items()):
        var = manifest_var.get(partition)
        if not var:
            continue
        lines.append(f"{var} += \\")
        for index, entry in enumerate(sorted(entries, key=lambda e: e.dest)):
            suffix = " \\" if index < len(entries) - 1 else ""
            lines.append(f"    vendor/xiaomi/ruan/proprietary/{entry.src}{suffix}")
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def emit_android_mk() -> str:
    return "\n".join(
        [
            "# Auto-generated by device/xiaomi/ruan/extract-files.py",
            "",
            "LOCAL_PATH := $(call my-dir)",
            "",
        ]
    )


def emit_boardconfig_vendor_mk() -> str:
    return "\n".join(
        [
            "# Auto-generated by device/xiaomi/ruan/extract-files.py",
            "# Additional vendor board flags are not required for ruan prebuilts.",
            "",
        ]
    )


def read_entries(path: Path) -> list[BlobEntry]:
    entries: list[BlobEntry] = []
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        entry = parse_blob_line(raw_line)
        if entry is not None:
            entries.append(entry)
    return entries


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8", newline="\n")


def write_filtered_list(path: Path, entries: list[BlobEntry]) -> None:
    content = "\n".join(entry.filtered_line for entry in entries) + "\n"
    write_text(path, content)


def stage_from_dump(entries: list[BlobEntry], dump_root: Path, proprietary_root: Path) -> None:
    missing: list[str] = []

    def partition_dir_variants(partition: str) -> list[Path]:
        base = dump_root / partition
        # Some extracted roots nest the partition payload under an extra directory
        # with the same name (e.g. system/system/lib64/...).
        return [base, base / partition]

    for entry in entries:
        candidates: list[Path] = []
        src_path = Path(entry.src)
        if src_path.parts and src_path.parts[0] in KNOWN_PARTITIONS:
            candidates.append(dump_root / src_path)
        else:
            candidates.append(dump_root / src_path)
            for base in partition_dir_variants(entry.partition):
                candidates.append(base / src_path)
                candidates.append(base / Path(entry.partition_dest))
            for partition in KNOWN_PARTITIONS:
                for base in partition_dir_variants(partition):
                    candidates.append(base / src_path)

        source = next((path for path in candidates if path.exists()), None)
        if source is None:
            if entry.optional:
                continue
            missing.append(entry.src)
            continue

        destination = proprietary_root / src_path
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)

    if missing:
        missing_text = "\n".join(missing)
        raise SystemExit(f"missing blobs in dump root:\n{missing_text}")


def copy_file_destination(entry: BlobEntry) -> str:
    partition_out = {
        "odm": "$(TARGET_COPY_OUT_ODM)",
        "product": "$(TARGET_COPY_OUT_PRODUCT)",
        "system": "$(TARGET_COPY_OUT_SYSTEM)",
        "system_ext": "$(TARGET_COPY_OUT_SYSTEM_EXT)",
        "vendor": "$(TARGET_COPY_OUT_VENDOR)",
        "vendor_dlkm": "$(TARGET_COPY_OUT_VENDOR_DLKM)",
    }
    return f"{partition_out[entry.partition]}/{entry.partition_dest}"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dump-root", type=Path)
    parser.add_argument("--allow-missing", action="store_true")
    parser.add_argument("--proprietary-list", type=Path, required=True)
    parser.add_argument("--vendor-root", type=Path)
    parser.add_argument("--write-filtered-list", type=Path)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    raw_entries = read_entries(args.proprietary_list)
    filtered, dropped = filtered_entries(raw_entries)

    if args.write_filtered_list:
        write_filtered_list(args.write_filtered_list, filtered)

    if args.vendor_root:
        modules, copy_files, vintf_manifests = make_prebuilt_modules(filtered)
        write_text(args.vendor_root / "Android.bp", emit_android_bp(modules))
        write_text(args.vendor_root / "Android.mk", emit_android_mk())
        write_text(args.vendor_root / "BoardConfigVendor.mk", emit_boardconfig_vendor_mk())
        write_text(
            args.vendor_root / "ruan-vendor.mk",
            emit_vendor_mk(modules, copy_files, vintf_manifests),
        )
        proprietary_root = args.vendor_root / "proprietary"
        proprietary_root.mkdir(parents=True, exist_ok=True)
        if args.dump_root:
            try:
                stage_from_dump(filtered, args.dump_root, proprietary_root)
            except SystemExit as exc:
                if args.allow_missing:
                    print(exc)
                else:
                    raise
    elif args.dump_root:
        raise SystemExit("--dump-root requires --vendor-root")

    for line in dropped:
        print(line)


def _kind_to_bp(kind: str) -> str:
    if kind == "shared_lib":
        return "cc_prebuilt_library_shared"
    if kind == "binary":
        return "cc_prebuilt_binary"
    raise ValueError(f"unsupported kind: {kind}")


PrebuiltModule.kind_to_bp = lambda self: _kind_to_bp(self.kind)


if __name__ == "__main__":
    main()
