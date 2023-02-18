package com.actduck.videogame.emu

import android.app.Application
import android.content.Context
import android.hardware.usb.UsbManager
import com.actduck.videogame.MyApp
import com.google.firebase.analytics.FirebaseAnalytics
import com.google.firebase.analytics.ktx.logEvent
import io.flutter.plugins.firebase.messaging.ContextHolder.getApplicationContext
import me.magnum.melonds.MelonDSAndroidInterface
import me.magnum.melonds.common.UriFileHandler
import org.dolphinemu.dolphinemu.utils.DirectoryInitialization
import org.dolphinemu.dolphinemu.utils.Java_GCAdapter
import org.dolphinemu.dolphinemu.utils.Java_WiimoteAdapter
import org.dolphinemu.dolphinemu.utils.VolleyUtil
import timber.log.Timber

object MySoLoader {

  fun loadDolphinSo(app: Application) {
    Timber.d("加载Dolphin的so")
    try {
      VolleyUtil.init(app)
      System.loadLibrary("main")

      Java_GCAdapter.manager = app.getSystemService(Context.USB_SERVICE) as UsbManager?
      Java_WiimoteAdapter.manager = app.getSystemService(Context.USB_SERVICE) as UsbManager?

      if (DirectoryInitialization.shouldStart(getApplicationContext())) DirectoryInitialization.start(
        getApplicationContext()
      )
    } catch (e: Throwable) {
      FirebaseAnalytics.getInstance(MyApp.instance).logEvent("load_so_error") {
        param("so_name", "Dolphin")
        param("err_msg", e.message!!)
      }
    }
  }

  fun loadN64So() {
    Timber.d("加载N64的so")
    try {
      System.loadLibrary("usb1.0")
      System.loadLibrary("oboe")
      System.loadLibrary("miniupnp-bridge")
      System.loadLibrary("jnidispatch")
      System.loadLibrary("c++_shared")
      System.loadLibrary("ae-bridge")

      System.loadLibrary("mupen64plus-audio-android-fp")
      System.loadLibrary("mupen64plus-audio-android")
      System.loadLibrary("mupen64plus-core")
      System.loadLibrary("mupen64plus-input-android")
      System.loadLibrary("mupen64plus-input-raphnet")
      System.loadLibrary("mupen64plus-rsp-cxd4")
      System.loadLibrary("mupen64plus-rsp-hle")
      System.loadLibrary("mupen64plus-rsp-parallel")
      System.loadLibrary("mupen64plus-video-GLideN64")
      System.loadLibrary("mupen64plus-video-angrylion-plus")
      System.loadLibrary("mupen64plus-video-glide64mk2-egl")
      System.loadLibrary("mupen64plus-video-glide64mk2")
      System.loadLibrary("mupen64plus-video-gln64")
      System.loadLibrary("mupen64plus-video-parallel")
      System.loadLibrary("mupen64plus-video-rice")
    } catch (e: Throwable) {
      FirebaseAnalytics.getInstance(MyApp.instance).logEvent("load_so_error") {
        param("so_name", "N64")
        param("err_msg", e.message!!)
      }
    }
  }

  fun loadNDSSo(app: MyApp) {
    Timber.d("加载NDS的so")
    try {
      System.loadLibrary("melonDS-lib")
      System.loadLibrary("melonDS-android-frontend")
      MelonDSAndroidInterface.setup(UriFileHandler(app, app.uriHandler))
    } catch (e: Throwable) {
      FirebaseAnalytics.getInstance(MyApp.instance).logEvent("load_so_error") {
        param("so_name", "NDS")
        param("err_msg", e.message!!)
      }
    }
  }
}