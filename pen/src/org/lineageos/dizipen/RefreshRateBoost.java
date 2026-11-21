/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.dizipen;

import android.content.ContentResolver;
import android.content.Context;
import android.content.SharedPreferences;
import android.os.SystemProperties;
import android.provider.Settings;
import android.util.Log;

/**
 * Keeps the display at its peak refresh rate while the pen is in use.
 *
 * The NT36532 only finds the pen while the panel refreshes fast enough: once
 * SurfaceFlinger idles the panel down to 30 Hz, the pen stays dead until a
 * finger touch raises the rate again. HyperOS's SurfaceFlinger has a "smartpen"
 * policy for this. Here xiaomi-pen-pressure sets vendor.pen.active while the
 * pen streams its Bluetooth reports, which it does from the moment it is picked
 * up until shortly after it is put down, and the minimum refresh rate is raised
 * to the peak rate meanwhile (Infinity = the peak rate, as the "force peak
 * refresh rate" developer option uses it). The user's value is put back after.
 */
final class RefreshRateBoost {

    private static final String TAG = "DiziPen";

    private static final String PROP_ACTIVE = "vendor.pen.active";

    private static final String PREFS = "refresh_rate_boost";
    private static final String KEY_BOOSTED = "boosted";
    private static final String KEY_SAVED = "saved_min_refresh_rate";

    private final ContentResolver mResolver;
    private final SharedPreferences mPrefs;
    private boolean mBoosted;

    RefreshRateBoost(Context context) {
        mResolver = context.getContentResolver();
        mPrefs = context.createDeviceProtectedStorageContext()
                .getSharedPreferences(PREFS, Context.MODE_PRIVATE);
        // A boost still applied from before a crash or reboot.
        mBoosted = mPrefs.getBoolean(KEY_BOOSTED, false);
    }

    synchronized void refresh(boolean penConnected) {
        boolean active = penConnected && SystemProperties.getBoolean(PROP_ACTIVE, false);
        if (active == mBoosted) {
            return;
        }
        if (active) {
            mPrefs.edit()
                    .putString(KEY_SAVED,
                            Settings.System.getString(mResolver, Settings.System.MIN_REFRESH_RATE))
                    .putBoolean(KEY_BOOSTED, true)
                    .commit();
            Settings.System.putFloat(mResolver, Settings.System.MIN_REFRESH_RATE,
                    Float.POSITIVE_INFINITY);
        } else {
            // null puts back an unset value, as Parts' RefreshRateKick does at every boot.
            Settings.System.putString(mResolver, Settings.System.MIN_REFRESH_RATE,
                    mPrefs.getString(KEY_SAVED, null));
            mPrefs.edit().remove(KEY_SAVED).putBoolean(KEY_BOOSTED, false).commit();
        }
        mBoosted = active;
        Log.i(TAG, "pen " + (active ? "active, peak refresh rate" : "idle, refresh rate restored"));
    }
}
