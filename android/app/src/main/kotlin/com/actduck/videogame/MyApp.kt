package com.actduck.videogame

import android.app.Activity
import android.app.ActivityManager
import android.app.ActivityManager.RunningAppProcessInfo
import android.content.Context
import android.os.Build.VERSION
import android.os.Build.VERSION_CODES
import android.os.Process
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationManagerCompat
import androidx.hilt.work.HiltWorkerFactory
import androidx.work.Configuration
import com.actduck.videogame.util.MySplitManager
import com.google.android.play.core.splitcompat.SplitCompat
import com.google.firebase.FirebaseApp
import dagger.hilt.android.HiltAndroidApp
import io.flutter.FlutterInjector
import io.reactivex.disposables.Disposable
import me.magnum.melonds.MelonDSApplication
import me.magnum.melonds.R
import me.magnum.melonds.common.uridelegates.UriHandler
import me.magnum.melonds.domain.repositories.SettingsRepository
import me.magnum.melonds.migrations.Migrator
import org.dolphinemu.dolphinemu.DolphinApplication
import timber.log.Timber
import timber.log.Timber.DebugTree
import javax.inject.Inject

@HiltAndroidApp
class MyApp : DolphinApplication(), Configuration.Provider {

  companion object {
    const val NOTIFICATION_CHANNEL_ID_BACKGROUND_TASKS = "channel_cheat_importing"
    lateinit var instance: MyApp
  }

  // ds 初始化
  @Inject lateinit var workerFactory: HiltWorkerFactory
  @Inject lateinit var settingsRepository: SettingsRepository
  @Inject lateinit var migrator: Migrator
  @Inject lateinit var uriHandler: UriHandler

  private var themeObserverDisposable: Disposable? = null
  override fun attachBaseContext(base: Context) {
    super.attachBaseContext(base)
    SplitCompat.install(this)
    if (BuildConfig.DEBUG) Timber.plant(DebugTree())
  }

  private var mCurrentActivity: Activity? = null

  fun getCurrentActivity(): Activity? {
    return mCurrentActivity
  }

  fun setCurrentActivity(mCurrentActivity: Activity?) {
    this.mCurrentActivity = mCurrentActivity
  }

  override fun onCreate() {
    instance = this
    super.onCreate()
    FlutterInjector.instance().flutterLoader().startInitialization(this)

    if (VERSION.SDK_INT >= VERSION_CODES.P && packageName != getProcessName()) {
      Timber.d("onCreate: 进程名字：%s", getProcessName())
      FirebaseApp.initializeApp(applicationContext);
    }

    // ds app的初始化逻辑
    createNotificationChannels()
    applyTheme()
    performMigrations()
//    tryInitNDS()
  }

//  private fun tryInitNDS() {
//    if (shouldInitNDS()){
//      MySoLoader.loadNDSSo(this)
//    }
//  }
  // your package name is the same with your main process name
  private fun isMainProcess(): Boolean {
    return packageName == getMyProcessName()
  }

  // you can use this method to get current process name, you will get
  // name like "com.package.name"(main process name) or "com.package.name:remote"
  private fun getMyProcessName(): String? {
    val myPid = Process.myPid()
    val manager: ActivityManager = getSystemService(ACTIVITY_SERVICE) as ActivityManager
    val infos: List<RunningAppProcessInfo> = manager.runningAppProcesses
    for (info in infos) {
      if (info.pid == myPid) {
        return info.processName
      }
    }
    // may never return null
    return null
  }

  private fun createNotificationChannels() {
    val defaultChannel = NotificationChannelCompat.Builder(
      MelonDSApplication.NOTIFICATION_CHANNEL_ID_BACKGROUND_TASKS,
      NotificationManagerCompat.IMPORTANCE_LOW
    )
      .setName(getString(R.string.notification_channel_background_tasks))
      .build()

    val notificationManager = NotificationManagerCompat.from(this)
    notificationManager.createNotificationChannel(defaultChannel)
  }

  private fun applyTheme() {
//    val theme = settingsRepository.getTheme()

    AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_YES)
//    themeObserverDisposable = settingsRepository.observeTheme()
//      .subscribe { AppCompatDelegate.setDefaultNightMode(it.nightMode) }
  }

  private fun performMigrations() {
    migrator.performMigrations()
  }

  override fun getWorkManagerConfiguration(): Configuration {
    return Configuration.Builder()
      .setWorkerFactory(workerFactory)
      .build()
  }

  override fun onTerminate() {
    super.onTerminate()
    themeObserverDisposable?.dispose()
  }

  override fun shouldInitDolphin(): Boolean {
    val moduleAdded = MySplitManager.isModuleAdded("Wii")
    val mainProcess = isMainProcess()
    Timber.d("海豚模拟器安装了吗？shouldInitDolphin $moduleAdded 是主Process吗 $mainProcess")
    return moduleAdded && mainProcess
  }

  private fun shouldInitNDS(): Boolean {
    val moduleAdded = MySplitManager.isModuleAdded("NDS")
    Timber.d("NDS模拟器安装了吗？shouldInitNDS $moduleAdded")
    return moduleAdded
  }

}
