// SPDX-License-Identifier: Apache-2.0
#ifndef RECOVERY_UFS_BSG_H
#define RECOVERY_UFS_BSG_H
// Real implementation issues a UFS RTT ioctl (scsi/ufs/ioctl.h), which this
// platform tree does not provide yet. Stamped as no-op so the caller proceeds.
int set_boot_lun(char* dev_path, unsigned char lun);
#endif
