#!/usr/bin/env python3
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
"""Pull ruan's saved kernel logs over adb (needs root through su).

ruan keeps nothing in /sys/fs/pstore: the bootloader clears the ramoops
memory on every reboot. The logs are saved to two partitions instead:

  rawdump  After a kernel panic the bootloader writes a Qualcomm minidump
           here, with the ramoops zones (md_KDMESG, md_KCONSOLE), the
           kernel log (md_kmsg) and the boot log (md_KBOOT_LOG). Only the
           last panic is kept.
  oops     Xiaomi's mtdoops saves the kernel log and logcat of the
           previous boot here on every clean reboot. It can't write from
           a panic (block2mtd has no panic_write).

    ruan_lastlog.py [output dir]
"""
import os
import struct
import subprocess
import sys

MINIDUMP_LOGS = ('md_kmsg', 'md_KDMESG.BIN', 'md_KCONSOLE.BIN', 'md_KBOOT_LOG.BIN')
OOPS_RECORD_SIZE = 2 * 1024 * 1024


def pull(partition):
    cmd = f'su -c "dd if=/dev/block/by-name/{partition} bs=4M 2>/dev/null"'
    return subprocess.run(['adb', 'exec-out', cmd], capture_output=True, check=True).stdout


def text(blob):
    return blob.split(b'\0\0\0\0')[0].decode('utf-8', 'replace')


def minidump_sections(d):
    if d[:8] != b'Raw_Dmp!':
        return {}
    sections = {}
    off = 0x58
    while off + 0x40 <= len(d):
        valid, _, _, start, size, _ = struct.unpack_from('<IIIQQQ', d, off)
        name = d[off + 0x2c:off + 0x40].split(b'\0')[0].decode('latin1')
        if valid != 1 or not name:
            break
        sections[name] = d[start:start + size]
        off += 0x40
    return sections


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else 'ruan-lastlog'
    os.makedirs(out, exist_ok=True)

    sections = minidump_sections(pull('rawdump'))
    if not sections:
        print('rawdump: no minidump')
    for name in MINIDUMP_LOGS:
        if name in sections:
            path = os.path.join(out, 'panic-' + name.split('.')[0].removeprefix('md_') + '.txt')
            open(path, 'w').write(text(sections[name]))
            print('rawdump:', path)
    kmsg = text(sections.get('md_kmsg', b''))
    for line in kmsg.splitlines():
        if 'Linux version' in line or 'Kernel panic' in line or ' pc : ' in line:
            print('  ', line.strip()[:160])
            if ' pc : ' in line:
                break

    # mtdoops records: u32 count, 00 5d 00 5d, then the text, newest has
    # the highest count.
    oops = pull('oops')
    records = []
    for i in range(len(oops) // OOPS_RECORD_SIZE):
        record = oops[i * OOPS_RECORD_SIZE:(i + 1) * OOPS_RECORD_SIZE]
        if record[4:8] != b'\x00]\x00]':
            continue
        records.append((struct.unpack_from('<I', record)[0],
                        record[8:].split(b'\xff\xff\xff\xff')[0].split(b'\0\0\0\0')[0]))
    for count, body in sorted(records):
        path = os.path.join(out, f'reboot-{count}.txt')
        open(path, 'w').write(body.decode('utf-8', 'replace'))
        reason = next((l for l in body.decode('latin1').splitlines() if 'REASON' in l), '')
        print('oops:', path, reason.strip('# \t'))


if __name__ == '__main__':
    main()
