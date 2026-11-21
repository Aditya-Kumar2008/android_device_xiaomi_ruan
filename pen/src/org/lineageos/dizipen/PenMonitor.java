/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.dizipen;

import android.content.Context;
import android.hardware.input.InputManager;
import android.os.SystemProperties;
import android.util.Log;
import android.view.InputDevice;

import java.util.Set;

/**
 * Tracks whether a Redmi / POCO Smart Pen is connected over Bluetooth and reports
 * transitions to the touch IC through vendor.pen.state (see init.dizi.rc).
 * The kernel counts connects, so only real transitions are reported.
 */
public final class PenMonitor implements InputManager.InputDeviceListener {

    private static final String TAG = "DiziPen";

    // Bluetooth HID identifiers (PnP ID): Redmi Smart Pen (M80P) 0x4e83,
    // POCO Smart Pen (N83C) 0x3283. Keep in sync with KeyHandler.
    private static final int PEN_VENDOR_ID = 0x0022;
    private static final Set<Integer> PEN_PRODUCT_IDS = Set.of(0x4e83, 0x3283);

    private static final String PROP_STATE = "vendor.pen.state";
    private static final String PROP_FORCE = "persist.vendor.pen.force";

    private final InputManager mInputManager;
    private final PenPairer mPairer;
    private final RefreshRateBoost mBoost;
    private boolean mConnected;     // reported to the touch IC: a pen, or forced on
    private boolean mPenConnected;  // a pen really is connected

    PenMonitor(Context context, PenPairer pairer) {
        mInputManager = context.getSystemService(InputManager.class);
        mPairer = pairer;
        mBoost = new RefreshRateBoost(context);
    }

    void start() {
        mInputManager.registerInputDeviceListener(this, null);
        // Re-evaluate when persist.vendor.pen.force is toggled (e.g. via adb), and follow
        // vendor.pen.active from xiaomi-pen-pressure.
        SystemProperties.addChangeCallback(this::refresh);
        refresh();
        mPairer.setPenConnected(mPenConnected);
    }

    private boolean isPen(int deviceId) {
        InputDevice device = mInputManager.getInputDevice(deviceId);
        return device != null && device.isExternal()
                && device.getVendorId() == PEN_VENDOR_ID
                && PEN_PRODUCT_IDS.contains(device.getProductId());
    }

    private synchronized void refresh() {
        boolean pen = false;
        for (int id : mInputManager.getInputDeviceIds()) {
            if (isPen(id)) {
                pen = true;
                enableIfSuppressed(id);
            }
        }
        // Forcing pen input on must not stop the pairer: a forgotten pen
        // could never be paired again.
        if (pen != mPenConnected) {
            mPenConnected = pen;
            Log.i(TAG, "pen " + (pen ? "connected" : "disconnected"));
            mPairer.setPenConnected(pen);
        }
        boolean connected = pen || SystemProperties.getBoolean(PROP_FORCE, false);
        mBoost.refresh(connected);
        if (connected == mConnected) {
            return;
        }
        mConnected = connected;
        SystemProperties.set(PROP_STATE, connected ? "connected" : "disconnected");
    }

    /**
     * The pen's Mouse input device shows up a moment before its Keyboard (the
     * buttons) joins it. Some ROMs (Axion, Lunaris) disable Bluetooth mice whose
     * Bluetooth class isn't a pointing device right then, which disables the
     * whole pen and drops its button presses. They do that once per device, so
     * turning it back on sticks.
     */
    private void enableIfSuppressed(int deviceId) {
        InputDevice device = mInputManager.getInputDevice(deviceId);
        if (device != null && !device.isEnabled()) {
            Log.i(TAG, "re-enabling pen input device " + deviceId);
            mInputManager.enableInputDevice(deviceId);
        }
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
