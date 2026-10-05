/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.settings.launcher;

import android.os.SystemProperties;

/**
 * Blur effects (Display > Blur effects). The notification shade and quick settings blur puts the
 * shade and everything under it on SurfaceFlinger GPU composition for every frame of the pull-down.
 */
public final class LauncherEffects {

    public static final String KEY_SHADE_BLUR = "shade_blur";
    /** Read by SystemUI's BlurUtils on each blur, so no restart is needed. */
    private static final String PROP_DISABLE_SHADE_BLUR = "persist.sysui.disableBlur";

    private LauncherEffects() { }

    public static boolean isShadeBlurEnabled() {
        return !SystemProperties.getBoolean(PROP_DISABLE_SHADE_BLUR, false);
    }

    public static void setShadeBlur(boolean blur) {
        SystemProperties.set(PROP_DISABLE_SHADE_BLUR, blur ? "false" : "true");
    }
}
