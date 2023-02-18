package com.actduck.videogame.savesync

import android.content.Context
import android.os.Bundle
import androidx.preference.Preference
import androidx.preference.PreferenceFragmentCompat
import com.swordfish.lemuroid.R
import com.swordfish.lemuroid.app.shared.library.PendingOperationsMonitor
import com.swordfish.lemuroid.app.shared.settings.SaveSyncPreferences
import com.swordfish.lemuroid.lib.preferences.SharedPreferencesHelper
import com.swordfish.lemuroid.lib.savesync.SaveSyncManager

import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

@AndroidEntryPoint
class MySaveSyncFragment : PreferenceFragmentCompat() {

    @Inject lateinit var saveSyncManager: SaveSyncManager
    private lateinit var saveSyncPreferences: SaveSyncPreferences

    override fun onCreatePreferences(savedInstanceState: Bundle?, rootKey: String?) {
        preferenceManager.preferenceDataStore =
            SharedPreferencesHelper.getSharedPreferencesDataStore(requireContext())

        saveSyncPreferences = SaveSyncPreferences(saveSyncManager)
        setPreferencesFromResource(R.xml.empty_preference_screen, rootKey)
        saveSyncPreferences.addSaveSyncPreferences(preferenceScreen)
    }

    override fun onPreferenceTreeClick(preference: Preference): Boolean {
        if (saveSyncPreferences.onPreferenceTreeClick(activity, preference))
            return true

        return super.onPreferenceTreeClick(preference)
    }

    override fun onResume() {
        super.onResume()
        saveSyncPreferences.updatePreferences(preferenceScreen, false)
        PendingOperationsMonitor(requireContext()).anySaveOperationInProgress().observe(this) {
            saveSyncPreferences.updatePreferences(preferenceScreen, it)
        }
    }
}
