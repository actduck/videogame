package com.actduck.videogame.util

import android.app.ProgressDialog
import android.view.View
import android.widget.Toast
import com.actduck.videogame.MyApp
import com.actduck.videogame.data.ModuleInstallEvent
import com.actduck.videogame.emu.MySoLoader
import com.google.android.play.core.splitinstall.SplitInstallManagerFactory
import com.google.android.play.core.splitinstall.SplitInstallRequest
import com.google.android.play.core.splitinstall.SplitInstallSessionState
import com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
import com.google.android.play.core.splitinstall.model.SplitInstallSessionStatus.DOWNLOADING
import com.google.android.play.core.splitinstall.model.SplitInstallSessionStatus.FAILED
import com.google.android.play.core.splitinstall.model.SplitInstallSessionStatus.INSTALLED
import com.google.android.play.core.splitinstall.model.SplitInstallSessionStatus.INSTALLING
import com.google.android.play.core.splitinstall.model.SplitInstallSessionStatus.REQUIRES_USER_CONFIRMATION
import com.google.firebase.analytics.ktx.analytics
import com.google.firebase.analytics.ktx.logEvent
import com.google.firebase.ktx.Firebase
import org.greenrobot.eventbus.EventBus
import timber.log.Timber

object MySplitManager {
  val pluginList = listOf(
    "emu_nes",
    "emu_snes",
    "emu_gba",
    "emu_gbc",
    "emu_md",
    "emu_neo",
    "emu_mame",
    "emu_nds",
    "emu_n64",
    "emu_psx",
    "emu_psp",
    "emu_3ds",
  )

  //Progress dialog for ROM scan
  private var mProgress: ProgressDialog? = null

  /** Listener used to handle changes in state for install requests. */
  private val listener = SplitInstallStateUpdatedListener { state ->
    val multiInstall = state.moduleNames().size > 1
    val names = state.moduleNames().joinToString(" - ")
    when (state.status()) {
      DOWNLOADING -> {
        //  In order to see this, the application has to be uploaded to the Play Store.
        displayLoadingState(state, "Downloading $names")
      }
      REQUIRES_USER_CONFIRMATION -> {
        /*
          This may occur when attempting to download a sufficiently large module.
          In order to see this, the application has to be uploaded to the Play Store.
          Then features can be requested until the confirmation path is triggered.
         */
        MyApp.instance.startIntentSender(state.resolutionIntent()?.intentSender, null, 0, 0, 0)
      }
      INSTALLED -> {
        onSuccessfulLoad(names, launch = !multiInstall)
      }

      INSTALLING -> displayLoadingState(state, "Installing $names")
      FAILED -> {
        toastAndLog("Error: ${state.errorCode()} for module ${state.moduleNames()}")
      }
    }
  }

  /** Display a loading state to the user. */
  private fun displayLoadingState(state: SplitInstallSessionState, message: String) {
//    displayProgress()

    val max = state.totalBytesToDownload().toInt()
    val progress = state.bytesDownloaded().toInt()

//    updateProgressMessage(message)
    if (max != 0) {
      toastAndLog(message + " " + progress * 100 / max + "%")
    }
  }

  /** Display progress bar and text. */
  private fun displayProgress() {
  }

  private fun updateProgressMessage(message: String) {
  }

  fun isModuleAdded(gameType: String): Boolean {
//    if (listOf("PSX", "PSP").contains(gameType)) {
//      return true
//    }
    val manager = SplitInstallManagerFactory.create(MyApp.instance)

    val moduleName = getModuleNameByGameType(gameType)
    val installedModules: Set<String> = manager.installedModules
    Timber.d("已安装的模块 $installedModules")
    return installedModules.contains(moduleName)
  }

  fun addModule(gameType: String) {
    if (isModuleAdded(gameType)) {
      return
    }
    val manager = SplitInstallManagerFactory.create(MyApp.instance)

    val moduleName = getModuleNameByGameType(gameType)
    // Registers the listener.
    manager.registerListener(listener)

    val request = SplitInstallRequest.newBuilder().addModule(moduleName).build()
    manager.startInstall(request).addOnSuccessListener {
      toastAndLog("Loading ${request.moduleNames}, wait a minute")
    }.addOnFailureListener {
      toastAndLog("Failed loading ${request.moduleNames}: $it")
      Firebase.analytics.logEvent("app_error") {
        param("error_name", "addModule")
        param("error_message", it.message.orEmpty())
      }
    }
  }

  fun removeModule(gameType: String) {
    val manager = SplitInstallManagerFactory.create(MyApp.instance)
    val moduleName = getModuleNameByGameType(gameType)
    manager.deferredUninstall(listOf(moduleName))
    toastAndLog("Uninstall (${gameType}) ... the Play Store tries to eventually remove those modules in the background.")
  }

  private fun getModuleNameByGameType(gameType: String): String {
    var moduleName = ""
    when (gameType) {
      "MAME" -> moduleName = "emu_mame"
      "NES" -> moduleName = "emu_nes"
      "SNES" -> moduleName = "emu_snes"
      "GBA" -> moduleName = "emu_gba"
      "GBC" -> moduleName = "emu_gbc"
      "SWAN" -> moduleName = "emu_swan"
      "MD" -> moduleName = "emu_md"
      "NEO" -> moduleName = "emu_neo"
      "GC", "Wii", "GC/Wii" -> moduleName = "emu_dolphin"
      "N64" -> moduleName = "emu_n64"
      "NDS" -> moduleName = "emu_nds"
      "PSX" -> moduleName = "emu_psx"
      "PSP" -> moduleName = "emu_psp"
      "3DS" -> moduleName = "emu_3ds"
    }
    return moduleName
  }

  fun checkForActiveDownloads() {
    val manager = SplitInstallManagerFactory.create(MyApp.instance)
    manager
      // Returns a SplitInstallSessionState object for each active session as a List.
      .sessionStates
      .addOnCompleteListener { task ->
        if (task.isSuccessful) {
          // Check for active sessions.
          for (state in task.result) {
            if (state.status() == DOWNLOADING) {
              // Cancel the request, or request a deferred installation.
            }
          }
        }
      }
  }

  private fun onSuccessfulLoad(moduleName: String, launch: Boolean) {
//    manager.unregisterListener(listener)
    toastAndLog("Successfully installed $moduleName")
    EventBus.getDefault().post(ModuleInstallEvent())
    // dolphin
    if (moduleName == "emu_dolphin") {
      Timber.d("海豚模拟器安装成功，开始配置")
      MySoLoader.loadDolphinSo(MyApp.instance)
    }
    if (moduleName == "emu_nds") {
      Timber.d("NDS模拟器安装成功")
      MySoLoader.loadNDSSo(MyApp.instance)
    }
    if (moduleName == "emu_n64") {
      Timber.d("N64模拟器安装成功")
      MySoLoader.loadN64So()
    }
  }

  var mToast: Toast? = null

  private fun toastAndLog(message: String?) {
    Timber.d(message)

    if (mToast == null) {
      mToast = Toast.makeText(MyApp.instance, message, Toast.LENGTH_SHORT)
    } else {
      val view: View? = mToast?.view
      mToast?.cancel()
      mToast = Toast(MyApp.instance)
      mToast?.view = view
      mToast?.duration = Toast.LENGTH_SHORT
      mToast?.setText(message)
    }
    mToast?.show()
  }

}