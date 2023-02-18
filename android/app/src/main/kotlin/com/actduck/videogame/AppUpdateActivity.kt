package com.actduck.videogame

import android.content.SharedPreferences
import android.graphics.Color
import android.os.Handler
import android.os.Looper
import androidx.core.content.edit
import androidx.preference.PreferenceManager
import com.google.android.material.snackbar.Snackbar
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.InstallStatus
import com.google.android.play.core.install.model.UpdateAvailability
import com.google.firebase.analytics.ktx.analytics
import com.google.firebase.analytics.ktx.logEvent
import com.google.firebase.ktx.Firebase
import io.flutter.embedding.android.FlutterActivity
import timber.log.Timber

open class AppUpdateActivity : FlutterActivity() {
  companion object {
    const val RQ_APP_UPDATE: Int = 101
  }

  /**==============================APP 检查更新 START=================================*/
  private var appUpdateManager: AppUpdateManager? = null
  private val updatedListener = InstallStateUpdatedListener { state ->
    // (Optional) Provide a download progress bar.
    if (state.installStatus() == InstallStatus.DOWNLOADING) {
      val bytesDownloaded = state.bytesDownloaded()
      val totalBytesToDownload = state.totalBytesToDownload()
      // Show update progress bar.
    }
    // Log state or install the update.
    if (state.installStatus() == InstallStatus.DOWNLOADED) {
      // After the update is downloaded, show a notification
      // and request user confirmation to restart the app.
      popupSnackbarForCompleteUpdate()
    }
  }

  protected fun tryUpdateApp() {
    Handler(Looper.getMainLooper()).postDelayed({
      val prefs: SharedPreferences = PreferenceManager.getDefaultSharedPreferences(this)
      val lastCheckTime = prefs.getLong("last_check_update_time", 0)
      // 1 小时 3600000毫秒
      if (System.currentTimeMillis() - lastCheckTime > 2 * 3600000) {
        checkAppUpdate()
      } else {
        Timber.d("无需检查更新，上次检查时间: $lastCheckTime")
      }
    }, 5000)
  }

  private fun checkAppUpdate() {
    try {
      Timber.d("checkAppUpdate: 检查app新版本")
      val prefs: SharedPreferences = PreferenceManager.getDefaultSharedPreferences(this)
      prefs.edit { putLong("last_check_update_time", System.currentTimeMillis()) }

      Firebase.analytics.logEvent("app_update_check") {
        param("current_version", BuildConfig.VERSION_NAME)
      }
      appUpdateManager = AppUpdateManagerFactory.create(context)

      // Returns an intent object that you use to check for an update.
      val appUpdateInfoTask = appUpdateManager?.appUpdateInfo

      // Checks that the platform will allow the specified type of update.
      appUpdateInfoTask?.addOnSuccessListener { appUpdateInfo ->
        if (appUpdateInfo.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE
          // This example applies an immediate update. To apply a flexible update
          // instead, pass in AppUpdateType.FLEXIBLE
          && appUpdateInfo.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)
        ) {
          // Request the update.
          Timber.d("checkAppUpdate: app有新版本，开始升级")
          Firebase.analytics.logEvent("app_update_start") {
            param("current_version", BuildConfig.VERSION_CODE.toLong())
            param("new_version", appUpdateInfo.availableVersionCode().toLong())
          }

          appUpdateManager?.startUpdateFlowForResult(
            // Pass the intent that is returned by 'getAppUpdateInfo()'.
            appUpdateInfo,
            // Or 'AppUpdateType.FLEXIBLE' for flexible updates.
            AppUpdateType.FLEXIBLE,
            // The current activity making the update request.
            this,
            // Include a request code to later monitor this update request.
            RQ_APP_UPDATE
          )
        }
      }

      // Create a listener to track request state updates.

      // Before starting an update, register a listener for updates.
      appUpdateManager?.registerListener(updatedListener)

      // Start an update.

    } catch (e: Exception) {
      e.printStackTrace()
    }
  }

  // Displays the snackbar notification and call to action.
  fun popupSnackbarForCompleteUpdate() {
    // When status updates are no longer needed, unregister the listener.
    appUpdateManager?.unregisterListener(updatedListener)

    Snackbar.make(
      findViewById(android.R.id.content),
      "An update has just been downloaded.",
      Snackbar.LENGTH_INDEFINITE
    ).apply {
      setAction("RESTART") { appUpdateManager?.completeUpdate() }
      setActionTextColor(Color.RED)
      show()
    }
  }

  /**===================================APP 检查更新 END=====================================*/
}
