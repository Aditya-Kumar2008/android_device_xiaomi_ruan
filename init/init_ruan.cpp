/*
 * Copyright (C) 2024-2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

#include <android-base/logging.h>
#include <android-base/properties.h>

#include <algorithm>
#include <cctype>
#include <string>

#include "property_service.h"
#include "vendor_init.h"

using android::base::GetProperty;

namespace {

struct VariantInfo {
    const char* region;
    const char* hardware_sku;
    const char* product_name;
    const char* odm_name;
    const char* brand;
    const char* model;
    const char* market_name;
};

constexpr VariantInfo kDefaultVariant {
    "GL",
    "ruanp",
    "ruan_global",
    "ruan_global",
    "POCO",
    "POCO Pad 5G",
    "POCO Pad 5G",
};

constexpr VariantInfo kPocoVariant {
    "GL",
    "ruanp",
    "ruan_global",
    "ruan_global",
    "POCO",
    "POCO Pad 5G",
    "POCO Pad 5G",
};

constexpr VariantInfo kVariants[] = {
    {
        "CN",
        "ruan",
        "ruan",
        "ruan_cn",
        "Redmi",
        "Redmi Pad Pro",
        "Redmi Pad Pro",
    },
    {
        "GL",
        "ruan",
        "ruan_global",
        "ruan_global",
        "Redmi",
        "Redmi Pad Pro 5G",
        "Redmi Pad Pro 5G",
    },
    {
        "IN",
        "ruan",
        "ruan_in",
        "ruan_india",
        "Redmi",
        "Redmi Pad Pro 5G",
        "Redmi Pad Pro 5G",
    },
    {
        "CN",
        "ruanp",
        "ruan_global",
        "ruan_global",
        "POCO",
        "POCO Pad 5G",
        "POCO Pad 5G",
    },
    {
        "GL",
        "ruanp",
        "ruan_global",
        "ruan_global",
        "POCO",
        "POCO Pad 5G",
        "POCO Pad 5G",
    },
    {
        "IN",
        "ruanp",
        "ruan_global",
        "ruan_global",
        "POCO",
        "POCO Pad 5G",
        "POCO Pad 5G",
    },
};

void PropertyOverride(const std::string& prop, const std::string& value, bool add = true) {
    auto* pi = reinterpret_cast<prop_info*>(__system_property_find(prop.c_str()));

    if (pi != nullptr) {
        __system_property_update(pi, value.c_str(), value.size());
    } else if (add) {
        __system_property_add(prop.c_str(), prop.size(), value.c_str(), value.size());
    }
}

std::string NormalizeValue(std::string value) {
    std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c) {
        return static_cast<char>(std::toupper(c));
    });
    return value;
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
    }

    if (hardware_sku == "RUANP") {
        return kPocoVariant;
    }

    if (hardware_sku == "RUAN") {
        return kVariants[1];
    }

    if (region == "CN") {
        return kVariants[0];
    }

    if (region == "IN") {
        return kVariants[2];
    }

    return kDefaultVariant;
}

}  // namespace

void vendor_load_properties() {
    const auto& variant = GetVariant();

    PropertyOverride("bluetooth.device.default_name", variant.market_name);
    PropertyOverride("ro.board.platform", "parrot");
    PropertyOverride("ro.build.characteristics", "tablet");
    PropertyOverride("ro.hardware", "qcom");
    PropertyOverride("ro.product.board", "parrot");
    PropertyOverride("ro.product.brand", variant.brand);
    PropertyOverride("ro.product.device", "ruan");
    PropertyOverride("ro.product.manufacturer", "Xiaomi");
    PropertyOverride("ro.product.marketname", variant.market_name);
    PropertyOverride("ro.product.model", variant.model);
    PropertyOverride("ro.product.name", variant.product_name);
    PropertyOverride("ro.product.odm.brand", variant.brand);
    PropertyOverride("ro.product.odm.device", "ruan");
    PropertyOverride("ro.product.odm.manufacturer", "Xiaomi");
    PropertyOverride("ro.product.odm.model", variant.model);
    PropertyOverride("ro.product.odm.name", variant.odm_name);
    PropertyOverride("ro.product.vendor.brand", variant.brand);
    PropertyOverride("ro.product.vendor.device", "ruan");
    PropertyOverride("ro.product.vendor.manufacturer", "Xiaomi");
    PropertyOverride("ro.product.vendor.model", variant.model);
    PropertyOverride("ro.product.vendor.name", variant.product_name);
    PropertyOverride("ro.radio.noril", "false");
    PropertyOverride("ro.soc.manufacturer", "Qualcomm");
    PropertyOverride("ro.soc.model", "SM7435");
    PropertyOverride("ro.telephony.sim.count", "2");
    PropertyOverride("vendor.usb.product_string", variant.market_name);

    LOG(INFO) << "Loaded variant properties for ruan region " << variant.region
              << " sku " << variant.hardware_sku;
}
