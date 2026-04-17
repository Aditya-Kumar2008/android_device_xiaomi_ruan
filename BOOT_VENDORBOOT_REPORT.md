# Boot and Vendor Boot Report

## Boot Image
- **Format**: boot image header version 4
- **Kernel Size**: 46854828 bytes
- **Ramdisk Size**: 1380092 bytes
- **OS Version**: 12.0.0, Patch Level: 2025-09
- **Command Line**: (empty)
- **Extracted Ramdisk**: Contains generic first stage init

## Vendor Boot Image
- **Format**: vendor boot image header version 4
- **Page Size**: 4096
- **DTB Size**: 4886932 bytes
- **Vendor Command Line**: `video=vfb:640x400,bpp=32,memsize=3072000 mtdoops.fingerprint=ruan_in:12/OS2.0.207.0.VFSINXM:user swinfo.fingerprint=ruan_in:12/OS2.0.207.0.VFSINXM:user bootconfig`
- **Vendor Ramdisk Size**: 13823203 bytes
- **Vendor Bootconfig Size**: 85 bytes
- **Contents**: Contains `avb`, `first_stage_ramdisk`, and `lib` directories.
