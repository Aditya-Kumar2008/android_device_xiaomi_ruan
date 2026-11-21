/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

#include "common/CameraProviderExtension.h"

#include <algorithm>
#include <fstream>

// The camera HAL always runs the torch at 120 mA and reports one strength level, so
// set the current on the LED directly. The driver only applies a new current when
// the LED is switched on, so switch it off first.
#define LED_PATH "/sys/devices/platform/soc/c42d000.qcom,spmi/spmi-0/0-05/c42d000.qcom,spmi:qcom,pm6150l@5:qcom,leds@d300/leds/"
static constexpr const char* kTorchNode = LED_PATH "led:torch_0/brightness";
static constexpr const char* kSwitchNode = LED_PATH "led:switch_0/brightness";

// The driver allows 500 mA; stay at twice what the HAL uses, as the LED's limit
// for continuous use is unknown.
static constexpr int32_t kMilliampsPerLevel = 20;
static constexpr int32_t kMaxLevel = 12;      // 240 mA
static constexpr int32_t kDefaultLevel = 6;   // 120 mA

template <typename T>
static void set(const char* path, const T& value) {
    std::ofstream file(path);
    file << value;
}

bool supportsTorchStrengthControlExt() {
    return true;
}

int32_t getTorchDefaultStrengthLevelExt() {
    return kDefaultLevel;
}

int32_t getTorchMaxStrengthLevelExt() {
    return kMaxLevel;
}

int32_t getTorchStrengthLevelExt() {
    std::ifstream file(kTorchNode);
    int32_t milliamps = 0;
    file >> milliamps;
    return std::clamp(milliamps / kMilliampsPerLevel, 1, kMaxLevel);
}

void setTorchStrengthLevelExt(int32_t torchStrength, bool enabled) {
    set(kSwitchNode, 0);
    set(kTorchNode, std::clamp(torchStrength, 1, kMaxLevel) * kMilliampsPerLevel);
    if (enabled) {
        set(kSwitchNode, 1);
    }
}
