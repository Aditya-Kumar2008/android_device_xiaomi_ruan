/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

// Tell the NT36532 touch IC whether a Redmi Smart Pen is paired, mirroring
// what HyperOS's touchfeature HAL does. The driver keeps a connect counter,
// so connect/disconnect must be balanced; "reset" clears it.

#include <cstring>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <unistd.h>

#include <android-base/logging.h>
#include <android-base/unique_fd.h>

namespace {

constexpr const char* kTouchDev = "/dev/xiaomi-touch";
constexpr int kSetCurValue = _IO('t', 0);
constexpr int kTouchPenEnable = 20;

// xiaomi_touch_dev_ioctl() copies MAX_BUF_SIZE ints from userspace and reads
// buf[1] as the mode and buf[2] as the value (buf[0] is the touch id).
constexpr size_t kMaxBufSize = 256;

// Low nibble: pen generation. The Redmi Smart Pen reports 4 (see
// nvt_set_cur_value() in the ruan-u-oss nt36532_spi driver); bit 4 = connected.
constexpr int kPenGeneration = 4;
constexpr int kConnected = 0x10 | kPenGeneration;
constexpr int kDisconnected = kPenGeneration;
constexpr int kReset = -1;

}  // namespace

int main(int argc, char** argv) {
    android::base::InitLogging(argv, android::base::KernelLogger);

    if (argc != 2) {
        LOG(ERROR) << "usage: xiaomi-pen connected|disconnected|reset";
        return 1;
    }

    int value;
    if (!strcmp(argv[1], "connected")) {
        value = kConnected;
    } else if (!strcmp(argv[1], "disconnected")) {
        value = kDisconnected;
    } else if (!strcmp(argv[1], "reset")) {
        value = kReset;
    } else {
        LOG(ERROR) << "unknown pen state " << argv[1];
        return 1;
    }

    android::base::unique_fd fd(open(kTouchDev, O_RDWR | O_CLOEXEC));
    if (fd < 0) {
        PLOG(ERROR) << "open " << kTouchDev;
        return 1;
    }

    int buf[kMaxBufSize] = {0, kTouchPenEnable, value};
    if (ioctl(fd, kSetCurValue, buf) < 0) {
        PLOG(ERROR) << "set pen mode " << value;
        return 1;
    }

    LOG(INFO) << "pen state " << argv[1] << " (mode " << kTouchPenEnable << " = " << value << ")";
    return 0;
}
