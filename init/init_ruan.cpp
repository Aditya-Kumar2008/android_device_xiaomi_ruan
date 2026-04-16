/*
 * Copyright (C) 2024 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

#include <android-base/properties.h>
#include <android-base/logging.h>
#include <sys/sysinfo.h>

#include "property_service.h"
#include "vendor_init.h"

using android::base::GetProperty;
using android::base::SetProperty;
using android::init::property_set;

static const char *DEVICE_NAME = "ruan";
static const char *DEVICE_MODEL = "POCO Pad 5G";
static const char *DEVICE_BRAND = "POCO";
static const char *DEVICE_MANUFACTURER = "Xiaomi";

void property_override(char const prop[], char const value[], bool add = true) {
    auto pi = (prop_info *) __system_property_find(prop);

    if (pi != nullptr) {
        __system_property_update(pi, value, strlen(value));
    } else if (add) {
        __system_property_add(prop, strlen(prop), value, strlen(value));
    }
}

void set_ro_build_prop(const std::string &prop, const std::string &value) {
    property_override(("ro.build." + prop).c_str(), value.c_str());
    property_override(("ro.product.build." + prop).c_str(), value.c_str());
    property_override(("ro.system.build." + prop).c_str(), value.c_str());
    property_override(("ro.system_ext.build." + prop).c_str(), value.c_str());
    property_override(("ro.vendor.build." + prop).c_str(), value.c_str());
    property_override(("ro.odm.build." + prop).c_str(), value.c_str());
}

void vendor_load_properties() {
    std::string variant = GetProperty("ro.boot.hardware.variant", "");

    // Set device properties
    property_override("ro.product.device", DEVICE_NAME);
    property_override("ro.product.name", "ruan_global");
    property_override("ro.product.model", DEVICE_MODEL);
    property_override("ro.product.brand", DEVICE_BRAND);
    property_override("ro.product.manufacturer", DEVICE_MANUFACTURER);

    // Build fingerprint
    property_override("ro.build.fingerprint", 
        "POCO/ruan_global/ruan:15/AP3A.240905.015.A2/OS2.0.208.0.VFSMIXM:user/release-keys");
    property_override("ro.build.description", 
        "ruan_global-user 15 AP3A.240905.015.A2 OS2.0.208.0.VFSMIXM release-keys");

    // Market name
    property_override("ro.product.marketname", "POCO Pad 5G");

    // Board
    property_override("ro.product.board", "parrot");
    property_override("ro.board.platform", "parrot");

    // Hardware
    property_override("ro.hardware", "qcom");
    property_override("ro.hardware.keystore", "parrot");
    property_override("ro.hardware.gatekeeper", "parrot");
    property_override("ro.hardware.keymaster", "parrot");

    // SoC
    property_override("ro.soc.manufacturer", "QTI");
    property_override("ro.soc.model", "SM7435");

    // Display
    property_override("ro.display.type", "LCD");
    property_override("ro.display.resolution", "2560x1600");
    property_override("ro.display.density", "320");
    property_override("ro.display.refresh_rate", "120");

    // Tablet
    property_override("ro.build.characteristics", "tablet");
    property_override("ro.sf.lcd_density", "320");

    // First API level
    property_override("ro.product.first_api_level", "34");

    // Security patch
    property_override("ro.build.version.security_patch", "2025-02-01");
    property_override("ro.vendor.build.security_patch", "2025-02-01");

    // Version
    property_override("ro.build.version.release", "15");
    property_override("ro.build.version.sdk", "35");

    // Variant specific
    if (!variant.empty()) {
        if (variant == "wifi" || variant == "WIFI") {
            property_override("ro.radio.noril", "true");
            property_override("ro.telephony.sim.count", "0");
        } else {
            property_override("ro.radio.noril", "false");
            property_override("ro.telephony.sim.count", "2");
        }
    } else {
        property_override("ro.radio.noril", "false");
        property_override("ro.telephony.sim.count", "2");
    }

    LOG(INFO) << "Loaded vendor properties for " << DEVICE_MODEL << " (" << DEVICE_NAME << ")";
}
