/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.settings.launcher;

import android.os.Bundle;

import androidx.preference.PreferenceFragment;
import androidx.preference.SwitchPreferenceCompat;

import org.lineageos.settings.R;

public class LauncherEffectsFragment extends PreferenceFragment {

    @Override
    public void onCreatePreferences(Bundle savedInstanceState, String rootKey) {
        setPreferencesFromResource(R.xml.launcher_effects_settings, rootKey);

        // Not persisted: the property is the state.
        SwitchPreferenceCompat shade = findPreference(LauncherEffects.KEY_SHADE_BLUR);
        shade.setChecked(LauncherEffects.isShadeBlurEnabled());
        shade.setOnPreferenceChangeListener((pref, newValue) -> {
            LauncherEffects.setShadeBlur((Boolean) newValue);
            return true;
        });
    }
}
