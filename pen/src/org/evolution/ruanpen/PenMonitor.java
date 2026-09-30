/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.evolution.ruanpen;

import android.content.Context;
import android.hardware.input.InputManager;
import android.os.SystemProperties;
import android.util.Log;
import android.view.InputDevice;

/**
 * Tracks whether the Redmi Smart Pen is connected over Bluetooth and reports
 * transitions to the touch IC through vendor.pen.state (see init.ruan.rc).
 * The kernel counts connects, so only real transitions are reported.
 */
public final class PenMonitor implements InputManager.InputDeviceListener {

    private static final String TAG = "RuanPen";

    // Redmi Smart Pen (M80P) Bluetooth HID identifiers.
    private static final int PEN_VENDOR_ID = 0x0022;
    private static final int PEN_PRODUCT_ID = 0x4e83;

    private static final String PROP_STATE = "vendor.pen.state";
    private static final String PROP_FORCE = "persist.vendor.pen.force";

    private final InputManager mInputManager;
    private final PenPairer mPairer;
    private boolean mConnected;

    PenMonitor(Context context, PenPairer pairer) {
        mInputManager = context.getSystemService(InputManager.class);
        mPairer = pairer;
    }

    void start() {
        mInputManager.registerInputDeviceListener(this, null);
        // Re-evaluate when persist.vendor.pen.force is toggled (e.g. via adb).
        SystemProperties.addChangeCallback(this::refresh);
        refresh();
        mPairer.setPenConnected(mConnected);
    }

    private boolean isPen(int deviceId) {
        InputDevice device = mInputManager.getInputDevice(deviceId);
        return device != null && device.isExternal()
                && device.getVendorId() == PEN_VENDOR_ID
                && device.getProductId() == PEN_PRODUCT_ID;
    }

    private synchronized void refresh() {
        boolean connected = SystemProperties.getBoolean(PROP_FORCE, false);
        for (int id : mInputManager.getInputDeviceIds()) {
            if (isPen(id)) {
                connected = true;
                break;
            }
        }
        if (connected == mConnected) {
            return;
        }
        mConnected = connected;
        Log.i(TAG, "pen " + (connected ? "connected" : "disconnected"));
        SystemProperties.set(PROP_STATE, connected ? "connected" : "disconnected");
        mPairer.setPenConnected(connected);
    }

    @Override
    public void onInputDeviceAdded(int deviceId) {
        refresh();
    }

    @Override
    public void onInputDeviceRemoved(int deviceId) {
        refresh();
    }

    @Override
    public void onInputDeviceChanged(int deviceId) {
        refresh();
    }
}
