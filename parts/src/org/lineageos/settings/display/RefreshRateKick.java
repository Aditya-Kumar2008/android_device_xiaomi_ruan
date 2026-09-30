/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.settings.display;

import android.content.ContentResolver;
import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings;
import android.util.Log;

/**
 * Forces one real display mode change after boot.
 *
 * On about half of the boots the panel keeps the bootloader's ~60 Hz timing while
 * the kernel, the composer and SurfaceFlinger all believe the 120 Hz mode is active:
 * the only mode set the kernel logs is 120 Hz, so the panel is never reprogrammed.
 * SurfaceFlinger then schedules for 8.3 ms vsyncs that arrive every 16.7 ms and
 * every animation runs at ~44 ms per frame. A 60 Hz -> 120 Hz round trip makes the
 * driver program the panel for real (the good boots do the same by passing 30 Hz).
 */
public final class RefreshRateKick {
    private static final String TAG = "XiaomiParts";
    private static final String MIN = "min_refresh_rate";
    private static final String PEAK = "peak_refresh_rate";
    private static final String KICK_RATE = "60.0";
    private static final long HOLD_MS = 1000;
    /** Global setting; 0 skips the round trip (to test a kernel-side fix). */
    private static final String ENABLE = "ruan_refresh_kick";

    private RefreshRateKick() {}

    public static void run(Context context) {
        final ContentResolver resolver = context.getContentResolver();
        if (Settings.Global.getInt(resolver, ENABLE, 1) == 0) {
            Log.i(TAG, "Display mode round trip disabled");
            return;
        }
        final String min = Settings.System.getString(resolver, MIN);
        final String peak = Settings.System.getString(resolver, PEAK);
        Settings.System.putString(resolver, PEAK, KICK_RATE);
        Settings.System.putString(resolver, MIN, KICK_RATE);
        new Handler(Looper.getMainLooper()).postDelayed(() -> {
            Settings.System.putString(resolver, PEAK, peak);
            Settings.System.putString(resolver, MIN, min);
            Log.i(TAG, "Display mode round trip done (min=" + min + ", peak=" + peak + ")");
        }, HOLD_MS);
    }
}
