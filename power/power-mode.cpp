/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

// Double-tap to wake for the NT36532 touchscreen. The stock nt36532_spi driver takes
// gesture mode as an input event written to its own input device (EV_SYN/SYN_CONFIG,
// 5 = on, 4 = off; HyperOS's input flinger does the same) and reports a double tap in
// suspend as KEY_WAKEUP. The mode survives suspend/resume. Don't write it while the panel
// is off: the driver defers such a write and toggles on the next resume. The framework
// only sets this mode from the Tap to wake setting, i.e. with the screen on.

#include <cstring>
#include <dirent.h>
#include <fcntl.h>
#include <linux/input.h>
#include <memory>
#include <string>
#include <sys/ioctl.h>
#include <unistd.h>

#include <aidl/android/hardware/power/BnPower.h>
#include <android-base/logging.h>
#include <android-base/unique_fd.h>

namespace aidl {
namespace google {
namespace hardware {
namespace power {
namespace impl {
namespace pixel {

using ::aidl::android::hardware::power::Mode;

namespace {

constexpr const char* kTouchName = "NVTCapacitiveTouchScreen";
constexpr int kGestureOn = 5;
constexpr int kGestureOff = 4;

// The event number isn't stable across builds, so look the device up by name.
::android::base::unique_fd openTouchscreen() {
    std::unique_ptr<DIR, decltype(&closedir)> dir(opendir("/dev/input"), closedir);
    if (!dir) {
        PLOG(ERROR) << "opendir /dev/input";
        return {};
    }
    while (struct dirent* e = readdir(dir.get())) {
        if (strncmp(e->d_name, "event", 5) != 0) continue;
        std::string path = std::string("/dev/input/") + e->d_name;
        ::android::base::unique_fd fd(open(path.c_str(), O_RDWR | O_CLOEXEC));
        if (fd < 0) continue;
        char name[64] = {};
        if (ioctl(fd.get(), EVIOCGNAME(sizeof(name) - 1), name) >= 0 &&
            strcmp(name, kTouchName) == 0) {
            return fd;
        }
    }
    LOG(ERROR) << "No " << kTouchName << " input device";
    return {};
}

void writeGestureMode(bool enabled) {
    ::android::base::unique_fd fd = openTouchscreen();
    if (fd < 0) return;
    struct input_event ev = {};
    ev.type = EV_SYN;
    ev.code = SYN_CONFIG;
    ev.value = enabled ? kGestureOn : kGestureOff;
    if (write(fd.get(), &ev, sizeof(ev)) != sizeof(ev)) {
        PLOG(ERROR) << "Failed to set touch gesture mode " << ev.value;
    }
}

}  // namespace

bool isDeviceSpecificModeSupported(Mode type, bool* _aidl_return) {
    if (type == Mode::DOUBLE_TAP_TO_WAKE) {
        *_aidl_return = true;
        return true;
    }
    return false;
}

bool setDeviceSpecificMode(Mode type, bool enabled) {
    if (type != Mode::DOUBLE_TAP_TO_WAKE) return false;
    writeGestureMode(enabled);
    return true;
}

}  // namespace pixel
}  // namespace impl
}  // namespace power
}  // namespace hardware
}  // namespace google
}  // namespace aidl
