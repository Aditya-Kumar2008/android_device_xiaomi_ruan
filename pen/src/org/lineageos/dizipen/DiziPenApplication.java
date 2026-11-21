/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.dizipen;

import android.app.Application;
import android.content.Context;

/**
 * Starts pen pairing and monitoring whenever the process starts, so they
 * come back when the persistent process is restarted after a crash (no boot
 * broadcast is sent then).
 */
public class DiziPenApplication extends Application {

    private static PenMonitor sMonitor;

    @Override
    public void onCreate() {
        super.onCreate();
        start(this);
    }

    static synchronized void start(Context context) {
        if (sMonitor != null) {
            return;
        }
        Context app = context.getApplicationContext();
        PenPairer pairer = new PenPairer(app);
        pairer.start();
        sMonitor = new PenMonitor(app, pairer);
        sMonitor.start();
    }
}
