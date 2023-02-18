package com.actduck.videogame

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.database.sqlite.SQLiteDatabase
import android.graphics.Color
import android.net.Uri
import android.os.Bundle
import android.os.IBinder
import android.text.TextUtils
import android.util.Log
import android.view.WindowManager.LayoutParams
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.documentfile.provider.DocumentFile
import androidx.preference.PreferenceManager
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequest
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import com.actduck.videogame.R.string
import com.actduck.videogame.data.DownloadEvent
import com.actduck.videogame.data.Game
import com.actduck.videogame.data.GameType
import com.actduck.videogame.data.source.DOWNLOAD_STATE_ERROR
import com.actduck.videogame.data.source.DOWNLOAD_STATE_FINISH
import com.actduck.videogame.data.source.DOWNLOAD_STATE_PAUSE
import com.actduck.videogame.data.source.DOWNLOAD_STATE_PROGRESS
import com.actduck.videogame.data.source.DownloadWorker
import com.actduck.videogame.emu.CloudSavesActivity
import com.actduck.videogame.emu.DolphinActivity
import com.actduck.videogame.emu.GBAActivity
import com.actduck.videogame.emu.GBCActivity
import com.actduck.videogame.emu.LemuActivity
import com.actduck.videogame.emu.MAMEActivity
import com.actduck.videogame.emu.MDActivity
import com.actduck.videogame.emu.N64Activity
import com.actduck.videogame.emu.N64SettingActivity
import com.actduck.videogame.emu.NDSActivity
import com.actduck.videogame.emu.NEOActivity
import com.actduck.videogame.emu.NESActivity
import com.actduck.videogame.emu.SNESActivity
import com.actduck.videogame.emu.SWANActivity
import com.actduck.videogame.ui.MyScanRomsActivity
import com.actduck.videogame.ui.PluginSettingActivity
import com.actduck.videogame.ui.ads.HomeTileNativeAdFactory
import com.actduck.videogame.ui.ads.ListTileNativeAdFactory
import com.actduck.videogame.util.MySplitManager.addModule
import com.actduck.videogame.util.MySplitManager.isModuleAdded
import com.actduck.videogame.util.MySplitManager.removeModule
import com.actduck.videogame.util.ToastUtil
import com.actduck.videogame.util.covertToJson
import com.actduck.videogame.util.toDataClass
import com.anggrayudi.storage.file.getAbsolutePath
import com.applovin.sdk.AppLovinPrivacySettings
import com.google.android.play.core.splitcompat.SplitCompat
import com.google.android.ump.ConsentForm
import com.google.android.ump.ConsentInformation
import com.google.android.ump.ConsentRequestParameters
import com.google.android.ump.UserMessagingPlatform
import com.google.firebase.analytics.ktx.analytics
import com.google.firebase.analytics.ktx.logEvent
import com.google.firebase.ktx.Firebase
import com.google.gson.Gson
import com.google.gson.GsonBuilder
import com.swordfish.lemuroid.app.shared.library.CoreUpdateWork
import com.swordfish.lemuroid.app.shared.library.LibraryIndexScheduler
import com.unity3d.ads.metadata.MetaData
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin
import kotlinx.coroutines.CoroutineExceptionHandler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import me.magnum.melonds.ui.emulator.EmulatorActivity
import okhttp3.internal.toHexString
import org.apache.commons.compress.utils.FileNameUtils
import org.apache.commons.io.FilenameUtils
import org.apache.commons.io.IOUtils
import org.apache.commons.io.output.NullOutputStream
import org.dolphinemu.dolphinemu.features.settings.ui.MenuTag
import org.dolphinemu.dolphinemu.features.settings.ui.SettingsActivity
import org.greenrobot.eventbus.EventBus
import org.greenrobot.eventbus.Subscribe
import org.greenrobot.eventbus.ThreadMode.MAIN
import paulscode.android.mupen64plusae.ActivityHelper.Keys
import paulscode.android.mupen64plusae.dialog.ProgressDialog
import paulscode.android.mupen64plusae.util.FileUtil
import timber.log.Timber
import java.io.BufferedInputStream
import java.io.File
import java.io.FileInputStream
import java.io.InputStream
import java.util.Date
import java.util.zip.CRC32
import java.util.zip.CheckedInputStream
import java.util.zip.ZipEntry
import java.util.zip.ZipInputStream
import kotlin.coroutines.CoroutineContext
import com.swordfish.lemuroid.lib.library.db.entity.Game as LemGame

class MainActivity : AppUpdateActivity(), CoroutineScope {
  companion object {
    private const val RQ_PLAY: Int = 100
    private const val RQ_SCAN_ROMS: Int = 102

    var gson: Gson = GsonBuilder().setDateFormat("yyyy-MM-dd HH:mm:ss").create()
  }

  private var mResult: Result? = null
  private val TAG = "MainActivity"

  private val CHANNEL_METHOD = "com.actduck.videogame/playgame_method"
  private val CHANNEL_EVENT = "com.actduck.videogame/playgame_event"
  var eventSink: EventSink? = null

  var flutterChannel: MethodChannel? = null // 原生调用flutter的channel

  private lateinit var job: Job
  override val coroutineContext: CoroutineContext
    get() = Dispatchers.Main + job

  override fun attachBaseContext(base: Context) {
    super.attachBaseContext(base)
    // Emulates installation of on demand modules using SplitCompat.
    SplitCompat.installActivity(this)
  }

  private var mService: MainGameService? = null
  private var mBound: Boolean = false

  /** Defines callbacks for service binding, passed to bindService()  */
  private val connection = object : ServiceConnection {

    override fun onServiceConnected(className: ComponentName, service: IBinder) {
      // We've bound to LocalService, cast the IBinder and get LocalService instance
      val binder = service as MainGameService.LocalBinder
      mService = binder.getService()
      mBound = true
    }

    override fun onServiceDisconnected(arg0: ComponentName) {
      mBound = false
    }
  }

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    job = Job()
    window.statusBarColor = Color.TRANSPARENT
    val appInfo: ApplicationInfo =
      packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
    Timber.w(
      "ADMOB_APP_ID=%s",
      appInfo.metaData.getString("com.google.android.gms.ads.APPLICATION_ID")
    )

    MethodChannel(
      flutterEngine!!.dartExecutor,
      CHANNEL_METHOD
    ).setMethodCallHandler { call, result ->
      mResult = result
      try {
        when (call.method) {
          "playGame" -> {
            val arguments = call.arguments as Map<*, *>
            val gameType = arguments["gameType"] as Map<*, *>
            openGame(
              gameType["name"].toString(),
              arguments["romLocalPath"].toString(),
              arguments["localGame"].toString().toBoolean(),
              arguments["netplay"].toString().toBoolean(),
              arguments["server"].toString().toBoolean()
            )
            result.success("Play game success")
          }
          "openDolphinSetting" -> {
            SettingsActivity.launch(this, MenuTag.SETTINGS)
            result.success("Open dolphin setting success")
          }
          "openN64Setting" -> {
            startActivity(Intent(this, N64SettingActivity::class.java))
            result.success("Open n64 setting success")
          }
          "openCloudSaves" -> {
            startActivity(Intent(this, CloudSavesActivity::class.java))
            result.success("Open cloud saves success")
          }
          "openNDSSetting" -> {
            startActivity(Intent(this, me.magnum.melonds.ui.settings.SettingsActivity::class.java))
            result.success("Open nds setting success")
          }
          "openPluginSetting" -> {
            val gameTypeString = call.arguments as String
            val intent = Intent(this, PluginSettingActivity::class.java)
            intent.putExtra("gameTypeStr", gameTypeString)
            startActivity(intent)
          }
          "installPlugin" -> {
            val arguments = call.arguments as Map<*, *>
            result.success(addModule(arguments["name"].toString()))
          }
          "removePlugin" -> {
            val arguments = call.arguments as Map<*, *>
            result.success(removeModule(arguments["name"].toString()))
          }
          "isPluginInstalled" -> {
            val arguments = call.arguments as Map<*, *>
            result.success(isModuleAdded(arguments["name"].toString()))
          }
          "scanRoms" -> {
            val isFolder = call.arguments as Boolean

            val intent = Intent(this, MyScanRomsActivity::class.java)
            intent.putExtra("isFolder", isFolder)
            startActivityForResult(intent, RQ_SCAN_ROMS)
//            result.success("add local games success")
          }
          "setGameType" -> {
            val arguments = call.arguments as Map<*, *>
            val romLocalPath = arguments["romLocalPath"] as String
            val newGameType = arguments["newGameType"] as String

            val dest = File(
              getExternalFilesDir("local-rom/$newGameType"),
              FilenameUtils.getName(romLocalPath)
            )
            if (!dest.exists()) {
              val success = FileUtil.copyFile(File(romLocalPath), dest, true)
              if (success) {
                Timber.d("setGameType 成功：${dest.absolutePath}")
                result.success(dest.absolutePath)
              } else {
                result.error("Copy rom failed", "Copy rom failed", null)
              }
            } else {
              result.success(dest.absolutePath)
            }
          }
          "downloadBios" -> {
            if (mBound) {
              // Call a method from the LocalService.
              // However, if this call were something that might hang, then this request should
              // occur in a separate thread to avoid slowing down the activity performance.
              mService?.downloadBios(this)
              mService?.downloadGameDb(this)
              result.success("downloadBios success")
            } else {
              result.error("downloadBios error", "Service is Unbound", null)
            }
          }
          "downloadGameDB" -> {
            if (mBound) {
              mService?.downloadGameDb(this)
              result.success("downloadGameDB success")
            } else {
              result.error("downloadGameDB error", "Service is Unbound", null)
            }
          }
          "downloadRoms" -> {
            val gameMap = call.arguments as Map<String, Any>
            onDownloadRom(gameMap)
          }
          "pauseDownloadRoms" -> {
            val gameMap = call.arguments as Map<String, Any>
            onPauseDownloadRom(gameMap)
          }
          "prepareNDS" -> {
            if (mBound) {
              mService?.prepareNDSDir()
              result.success("prepareNDS success")
            } else {
              result.error("prepareNDS error", "Service is Unbound", null)
            }
          }
          // "onDownloadComplete" -> {
          //   if (mBound) {
          //     val arguments = call.arguments as Map<*, *>
          //     val gameTypeName = arguments["gameTypeName"] as String?
          //     val link = arguments["link"] as String?
          //     if (gameTypeName == "NDS") {
          //       mService?.refreshNDSROMs()
          //     }
          //
          //     mService?.addLemGame(link, gameTypeName)
          //     mService?.updateCore(gameTypeName = gameTypeName)
          //
          //     result.success("onDownloadComplete success")
          //   }
          // }
          else -> {
            result.notImplemented()
          }
        }
      } catch (ex: Exception) {
        result.error("Name not found", ex.message, null)
      }
    }

    EventChannel(flutterEngine?.dartExecutor?.binaryMessenger, CHANNEL_EVENT).setStreamHandler(
      object :
        EventChannel.StreamHandler {
        override fun onListen(
          args: Any?,
          events: EventSink?
        ) {
          Log.d(TAG, "EventChannel adding listener 添加listener")
          eventSink = events
        }

        override fun onCancel(args: Any?) {
          Log.d(TAG, "cancelling listener")
        }
      })


    tryUpdateApp()

    initConsentForm()
  }

  private fun onDownloadRom(gameMap: Map<String, Any>) {
    val game = gameMap.toDataClass<Game>()
    val downloadReq: OneTimeWorkRequest = OneTimeWorkRequestBuilder<DownloadWorker>().setInputData(
      Data.Builder()
        .putString("game_json", game.covertToJson())
        .build()
    ).build()

    WorkManager.getInstance(context).enqueueUniqueWork(
      game.id.toString(), ExistingWorkPolicy.REPLACE, downloadReq
    )
  }

  private fun onPauseDownloadRom(gameMap: Map<String, Any>) {
    val game = gameMap.toDataClass<Game>()
    WorkManager.getInstance(context).cancelUniqueWork(
      game.id.toString(),
    )
  }

  private fun addLemuAssets(gameType: String) {
    if (gameType == "PSP") {
      WorkManager.getInstance(applicationContext)
        .beginUniqueWork(
          LibraryIndexScheduler.CORE_UPDATE_WORK_ID,
          ExistingWorkPolicy.APPEND_OR_REPLACE,
          OneTimeWorkRequestBuilder<CoreUpdateWork>().build()
        )
        .enqueue()
    }
  }

  override fun onStart() {
    super.onStart()
    // Bind to GameService
    Intent(this, MainGameService::class.java).also { intent ->
      bindService(intent, connection, Context.BIND_AUTO_CREATE)
    }

    if (eventSink != null) {
      eventSink?.success("foreground")
    }
    EventBus.getDefault().register(this)
  }

  override fun onStop() {
    super.onStop()
    unbindService(connection)
    mBound = false
    if (eventSink != null) {
      eventSink?.success("background")
    }
    EventBus.getDefault().unregister(this)
  }

  private fun openGame(
    gameType: String,
    romLocalPath: String,
    isLocalGame: Boolean,
    netplay: Boolean,
    server: Boolean
  ) {
    var file: File? = null
    val uri: Uri = if (isLocalGame) {
      Uri.parse(romLocalPath)
    } else {
      file = File(romLocalPath)
      Uri.parse(file.absolutePath)
    }

    if (file != null && !file.exists()) {
      Timber.e("game not exists%s", file.absolutePath)
      toastAndLog("game not exists")
      return
    }

    val intent = Intent(Intent.ACTION_VIEW)
    when (gameType) {
      "NES" -> {
        intent.setDataAndType(uri, "application/nes")
        intent.setClass(this, NESActivity::class.java)
      }
      "GBA" -> {
        intent.setDataAndType(uri, "application/gba")
        intent.setClass(this, GBAActivity::class.java)
      }
      "SNES" -> {
        intent.setDataAndType(uri, "application/snes")
        intent.setClass(this, SNESActivity::class.java)
      }
      "MD" -> {
        intent.setDataAndType(uri, "application/md")
        intent.setClass(this, MDActivity::class.java)
      }
      "NEO" -> {
        intent.setDataAndType(uri, "application/neo")
        intent.setClass(this, NEOActivity::class.java)
      }
      "GBC" -> {
        intent.setDataAndType(uri, "application/gbc")
        intent.setClass(this, GBCActivity::class.java)
      }
      "SWAN" -> {
        intent.setDataAndType(uri, "application/swan")
        intent.setClass(this, SWANActivity::class.java)
      }
      "GC", "Wii" -> {
        intent.data = uri
        intent.setClass(this, DolphinActivity::class.java)
      }
      "N64" -> {
        intent.data = uri
        intent.putExtra("netplay", netplay)
        intent.putExtra("server", server)
        intent.setClass(this, N64Activity::class.java)
      }
      "MAME" -> {
        intent.data = uri
        intent.putExtra("netplay", netplay)
        intent.putExtra("server", server)
        intent.setClass(this, MAMEActivity::class.java)
      }
      "NDS" -> {
        val u = if (isLocalGame) uri.toString() else Uri.fromFile(file).toString()
        intent.putExtra(EmulatorActivity.KEY_URI, u)
        intent.setClass(this, NDSActivity::class.java)
      }
      "PSX", "PSP", "3DS" -> {
        launch {
          val u = if (isLocalGame) uri.toString() else Uri.fromFile(file).toString()
          val game: LemGame?
          withContext(Dispatchers.IO) {
            game = mService?.getLemGame(u)
          }
          if (game != null) {
            intent.putExtra("game", game)
            intent.setClass(context, LemuActivity::class.java)
            startActivityForResult(intent, RQ_PLAY)
          } else {
            toastAndLog("game not exists")
          }
        }
        return
      }
    }
    startActivityForResult(intent, RQ_PLAY)
  }

  private fun toastAndLog(text: String) {
    runOnUiThread {
      Toast.makeText(this, text, Toast.LENGTH_LONG).show()
    }
    Timber.d(text)
  }

  override fun onActivityResult(
    requestCode: Int,
    resultCode: Int,
    data: Intent?
  ) {

    if (resultCode == RESULT_OK && data != null) {
      super.onActivityResult(requestCode, resultCode, data)
    }

    if (requestCode == RQ_PLAY) {
      eventSink?.success("game_over")
    }

    if (requestCode == RQ_APP_UPDATE) {
      if (resultCode != RESULT_OK) {
        Timber.e("Update flow failed! Result code: $resultCode")
        // If the update is cancelled or fails,
        // you can request to start the update again.
      }
    }

    if (requestCode == RQ_SCAN_ROMS) {
      val extras = data?.extras
      if (extras != null) {
        val searchUri = extras.getString(Keys.SEARCH_PATH)
        val searchZips = extras.getBoolean(Keys.SEARCH_ZIPS)
        val downloadArt = extras.getBoolean(Keys.DOWNLOAD_ART)
        val clearGallery = extras.getBoolean(Keys.CLEAR_GALLERY)
        val searchSubdirectories = extras.getBoolean(Keys.SEARCH_SUBDIR)
        val searchSingleFile = extras.getBoolean(Keys.SEARCH_SINGLE_FILE)
        searchUri?.let {
          refreshRoms(
            it,
            searchZips,
            downloadArt,
            clearGallery,
            searchSubdirectories,
            searchSingleFile
          )
        }
      }
    }
  }

  /**===================================扫描游戏 START==================================================*/
  private val romExt = listOf(
    "zip",
    "nes",
    "smc", "sfc",
    "gba",
    "gbc", "gb",
    "smd", "md", "gen", "sms", "cue",/*, "iso"*/
    "n64", "v64", "z64",
    "gcm", "tgc", "iso", "ciso", "gcz", "wbfs", "wia", "rvz", "wad", "dol", "elf", "json",
    "nds",
    "bin",
    "3ds"
  )

  //Progress dialog for ROM scan
  private var mProgress: ProgressDialog? = null

  val coroutineExceptionHandler = CoroutineExceptionHandler { _, throwable ->
    throwable.printStackTrace()
    Timber.e("""出错了${throwable.printStackTrace()}""")
  }

  private fun refreshRoms(
    searchUri: String,
    searchZips: Boolean,
    downloadArt: Boolean,
    clearGallery: Boolean,
    searchSubdirectories: Boolean,
    searchSingleFile: Boolean
  ) {
    try {// Don't let the activity sleep in the middle of scan
      window.setFlags(LayoutParams.FLAG_KEEP_SCREEN_ON, LayoutParams.FLAG_KEEP_SCREEN_ON)

      val title: CharSequence = getString(string.scanning_title)
      val message: CharSequence = getString(string.toast_pleaseWait)
      val rootDocumentFile = if (searchSingleFile) FileUtil.getDocumentFileSingle(
        activity,
        Uri.parse(searchUri)
      ) else FileUtil.getDocumentFileTree(activity, Uri.parse(searchUri))
      val text = if (rootDocumentFile != null) rootDocumentFile.name else ""
      mProgress = ProgressDialog(mProgress, activity, title, text, message, true)
      mProgress?.show()
      val result = ScanRomResult(searchSingleFile = searchSingleFile)

      val startTime = System.currentTimeMillis()
      CoroutineScope(Dispatchers.Main + coroutineExceptionHandler).launch {
        withContext(Dispatchers.IO) {
          if (searchSingleFile) {
            val game = createOneGameNew(rootDocumentFile)
            if (game != null) result.games.add(game)
          } else {
            createDirGame(rootDocumentFile, result)
          }
        }
        Timber.d("刷新本地rom 耗时：${System.currentTimeMillis() - startTime}ms 结果：${gson.toJson(result)}")
        mProgress?.dismiss()
        mResult?.success(gson.toJson(result))
        window.clearFlags(LayoutParams.FLAG_KEEP_SCREEN_ON)
        // 刷新游戏，nds 和 lemu的游戏要手动添加到数据库
        if (!searchSingleFile) {
          mService?.refreshUserNDSDir(searchUri)
        }
        mService?.addLemGame(result.games)
        mService?.updateCore(games = result.games)
      }
    } catch (e: Exception) {
      e.printStackTrace()
      window.clearFlags(LayoutParams.FLAG_KEEP_SCREEN_ON)
      toastAndLog("Error occurred: " + e.message)
      mProgress?.dismiss()
      Firebase.analytics.logEvent("app_error") {
        param("error_name", "refreshRoms")
        param("error_message", e.message.orEmpty())
      }
    }
  }

  private fun createDirGame(
    rootDocumentFile: DocumentFile,
    result: ScanRomResult
  ) {
    Timber.d("当前目录：${rootDocumentFile.name}")

    val listFiles = rootDocumentFile.listFiles()
    for (file in listFiles) {
      if (file.isDirectory) {
        createDirGame(file, result)
      } else {
        // 去重
        if (result.games.find { it.romLocalPath == file.getAbsolutePath(context) } != null) {
          continue
        }
        val game = createOneGameNew(file)
        if (game != null) result.games.add(game)
      }
    }
  }

  /*private fun createOneGame(file: DocumentFile): Game? {
    try {
      val romFile = File(file.getAbsolutePath(this))

      if (romFile.name == "neogeo.zip") {
        return null
      }

      if (!isValidRomFormat(FileNameUtils.getExtension(romFile.name))) {
        Timber.w("无效的rom文件:${romFile.name}")
        return null
      }

      // 1,先通过文件夹游戏类型
      val dirGameType = calcGameTypeByParentFile(romFile)

      val crC32 = FileUtils.checksumCRC32(romFile).toHexString().uppercase()
      var namePhotoGameType = getRomInfoByDb(crC32, romFile.name)

      var gameTypeInsideNameCrc: Triple<String, String, String>? = null
      if (namePhotoGameType == null) {
        // 2，通过文件名获取
        gameTypeInsideNameCrc = getGameTypeInnerNameCrc(romFile)
        // 3，名称图片类型
        namePhotoGameType =
          getRomInfoByDb(gameTypeInsideNameCrc.third, gameTypeInsideNameCrc.second)
      }

      // 名字 图片
      var gameName = ""
      var photo = ""
      if (namePhotoGameType != null) {
        gameName = namePhotoGameType.first.orEmpty()
        photo = namePhotoGameType.second.orEmpty()
      } else {
        gameName = FileNameUtils.getBaseName(romFile.absolutePath)
      }

      // 游戏类型
      val gameType = if (dirGameType.isNotEmpty()) {
        dirGameType
      } else if (namePhotoGameType != null && !TextUtils.isEmpty(namePhotoGameType.third)) {
        namePhotoGameType.third!!
      } else {
        gameTypeInsideNameCrc?.first.orEmpty()
      }

      val dest = copyRom2LocalDir(gameType, file, romFile)

      val game = Game(
        name = gameName,
        photo = photo,
        romLocalPath = dest.absolutePath,
        gameType = GameType(name = gameType),
        localGame = true
      )
      game.createTime = Date()
      game.updateTime = Date()
      Timber.d("扫描到一个游戏：$game")
      Firebase.analytics.logEvent("create_one_game") {
        param("game_name", game.name)
        param("game_detail", game.toString())
      }
      return game
    } catch (e: Exception) {
      e.printStackTrace()
      Firebase.analytics.logEvent("app_error") {
        param("error_name", "createOneGame")
        param("error_message", e.message.orEmpty())
      }
      toastAndLog("Error occurred: " + e.message)
      return null
    }
  }*/

  private fun createOneGameNew(file: DocumentFile): Game? {
    try {
      val fileName = FileUtil.getFileName(applicationContext, file.uri)

      if (fileName == "neogeo.zip") {
        return null
      }

      if (!isValidRomFormat(FileNameUtils.getExtension(fileName))) {
        Timber.w("无效的rom文件:${fileName}")
        return null
      }

      // 1,先通过文件夹游戏类型
      val dirGameType = calcGameTypeByParentFile(file)

      var crc32 = ""
      applicationContext.contentResolver.openFileDescriptor(file.uri, "r")
        .use { parcelFileDescriptor ->
          if (parcelFileDescriptor != null) {
            val bufferedInputStream =
              BufferedInputStream(FileInputStream(parcelFileDescriptor.fileDescriptor))
            crc32 = checkCRC32(bufferedInputStream).toHexString().uppercase()
          }
        }

      var namePhotoGameType = getRomInfoByDb(crc32, fileName)

      var gameTypeInnerNameCrc: Triple<String, String, String>? = null
      if (namePhotoGameType == null) {
        // 2，通过文件名获取
        gameTypeInnerNameCrc = getGameTypeInnerNameCrc(file)
        // 3，名称图片类型
        namePhotoGameType =
          getRomInfoByDb(gameTypeInnerNameCrc.third, gameTypeInnerNameCrc.second)
      }

      // 名字 图片
      var gameName = ""
      var photo = ""
      if (namePhotoGameType != null) {
        gameName = namePhotoGameType.first.orEmpty()
        photo = namePhotoGameType.second.orEmpty()
      } else {
        gameName = fileName
      }

      // 游戏类型
      val gameType = if (dirGameType.isNotEmpty()) {
        dirGameType
      } else if (namePhotoGameType != null && !TextUtils.isEmpty(namePhotoGameType.third)) {
        namePhotoGameType.third!!
      } else {
        gameTypeInnerNameCrc?.first.orEmpty()
      }

      // todo 要不要拷贝
//      val dest = copyRom2LocalDir(gameType, file, romFile)

      // 补救
      if (photo.isEmpty()) {
        photo = getGamePhoto(gameType.lowercase(), FilenameUtils.getBaseName(fileName))
      }

      val game = Game(
        name = gameName,
        photo = photo,
        romLocalPath = file.uri.toString(),
        gameType = GameType(name = gameType),
        localGame = true
      )
      game.createTime = Date()
      game.updateTime = Date()
      Timber.d("扫描到一个游戏：$game")
      Firebase.analytics.logEvent("create_one_game") {
        param("game_name", game.name)
        param("game_detail", game.toString())
      }
      return game
    } catch (e: Exception) {
      e.printStackTrace()
      Firebase.analytics.logEvent("app_error") {
        param("error_name", "createOneGame")
        param("error_message", e.message.orEmpty())
      }
      toastAndLog("Error occurred: " + e.message)
      return null
    }
  }

/*  private fun readUrlFile(file: Uri) {
    val fileName = FileUtil.getFileName(applicationContext, file)
    try {
      applicationContext.contentResolver.openFileDescriptor(file, "r").use { parcelFileDescriptor ->
        if (parcelFileDescriptor != null) {
          val bufferedStream: InputStream =
            BufferedInputStream(FileInputStream(parcelFileDescriptor.fileDescriptor))
          val md5 = FileUtil.computeMd5(bufferedStream)
        }
      }
    } catch (e: java.lang.Exception) {
      e.printStackTrace()
    } catch (e: OutOfMemoryError) {
      e.printStackTrace()
    }
  }*/

  private fun checkCRC32(bufferedStream: InputStream?): Long {
    val crc = CRC32()
    var ins: InputStream? = null
    try {
      ins = CheckedInputStream(bufferedStream, crc)
      IOUtils.copy(ins, NullOutputStream())
    } finally {
      IOUtils.closeQuietly(ins)
    }
    return crc.value
  }

  /**
   * 把文件拷贝到内部目录
   *//*
  private fun copyRom2LocalDir(
    gameTypeDir: String,
    file: DocumentFile,
    romFile: File
  ): File {
    var dir = "local-rom"
    if (gameTypeDir.isNotEmpty()) {
      dir += "/$gameTypeDir"
    }
    val dest = File(getExternalFilesDir(dir), file.name!!)
    if (!dest.exists()) {
      FileUtil.copyFile(romFile, dest, false)
    }
    return dest
  }

  private fun calcGameTypeByParentFile(dest: File): String {
    val parentFile = dest.parentFile ?: return ""
    return when (parentFile.name.lowercase()) {
      "nes" -> "NES"
      "snes" -> "SNES"
      "neo" -> "NEO"
      "md" -> "MD"
      "gbc" -> "GBC"
      "gba" -> "GBA"
      "mame" -> "MAME"
      "n64" -> "N64"
      "gc", "gamecube" -> "GC"
      "wii" -> "Wii"
      "nds" -> "NDS"
      "psp" -> "PSP"
      "psx" -> "PSX"
      "3ds" -> "3DS"
      else -> ""
    }
  }*/

  private fun calcGameTypeByParentFile(file: DocumentFile): String {
    val parentFile = file.parentFile ?: return ""
    return when (parentFile.name?.lowercase()) {
      "nes" -> "NES"
      "snes" -> "SNES"
      "neo" -> "NEO"
      "md" -> "MD"
      "gbc" -> "GBC"
      "gba" -> "GBA"
      "swan" -> "SWAN"
      "mame" -> "MAME"
      "n64" -> "N64"
      "gc", "gamecube" -> "GC"
      "wii" -> "Wii"
      "nds" -> "NDS"
      "psp" -> "PSP"
      "psx" -> "PSX"
      "3ds" -> "3DS"
      else -> ""
    }
  }

  /**
   * 返回游戏类型和压缩包里面文件的名字
   *//*
  private fun getGameTypeInnerNameCrc(romFile: File): Triple<String, String, String> {
    var gameType = ""
    var zipInsideName = ""
    var crc = ""
    try {
      val ext = FilenameUtils.getExtension(romFile.absolutePath)

      if (ext.lowercase() == "zip") {
        val zipFile = ZipFile(romFile)
        Timber.d("getRomGameType 是zip：${romFile.name}")
        zipFile.use { file ->
          val zipEntries = file.entries()
          while (zipEntries.hasMoreElements()) {
            val zipEntry = zipEntries.nextElement() as ZipEntry
            val fileName: String = zipEntry.name
            zipInsideName = fileName
            Timber.d("zip文件$fileName")

            crc = zipEntry.crc.toHexString().uppercase()
            Timber.d("内部crc32：${crc}")
            gameType = getGameTypeByExtension(FilenameUtils.getExtension(fileName))
          }
        }

      } else {
        Timber.d("getRomGameType 不是zip：${romFile.name}")
        gameType = getGameTypeByExtension(ext)
      }
    } catch (e: Exception) {
      e.printStackTrace()
    }

    return Triple(gameType, zipInsideName, crc)
  }*/

  /**
   * 返回游戏类型和压缩包里面文件的名字
   */
  private fun getGameTypeInnerNameCrc(file: DocumentFile): Triple<String, String, String> {
    var gameType = ""
    var zipInsideName = ""
    var crc = ""
    try {
      val ext = FilenameUtils.getExtension(file.name)

      if (ext.lowercase() == "zip") {

        applicationContext.contentResolver.openFileDescriptor(file.uri, "r")
          .use { parcelFileDescriptor ->
            if (parcelFileDescriptor != null) {
              val bs: InputStream =
                BufferedInputStream(FileInputStream(parcelFileDescriptor.fileDescriptor))
              val zipIn = ZipInputStream(bs)
              val zipEntry: ZipEntry? = zipIn.nextEntry
              if (zipEntry != null) {
                zipInsideName = zipEntry.name

                Timber.d("getGameTypeInnerNameCrc zip压缩的文件名：$zipInsideName")

                crc = zipEntry.crc.toHexString().uppercase()
                Timber.d("getGameTypeInnerNameCrc zip压缩的文件crc32：${crc}")
                gameType = getGameTypeByExtension(FilenameUtils.getExtension(zipInsideName))
                bs.close()
              }
              bs.close()
            }
          }
      } else {
        Timber.d("getGameTypeInnerNameCrc 不是zip：${file.name}")
        gameType = getGameTypeByExtension(ext)
      }
    } catch (e: Exception) {
      e.printStackTrace()
    }

    return Triple(gameType, zipInsideName, crc)
  }

  /**
   * 返回名字，图片，类型
   */
  private fun getRomInfoByDb(
    crc: String,
    romName: String
  ): Triple<String?, String?, String?>? {

    val fileDir = getExternalFilesDir("db")
    val dbFile = File(fileDir, "libretro-db.sqlite")
    if (!dbFile.exists()) {
      Timber.d("游戏数据不存在，没有游戏类型")
      return null
    }

    val db: SQLiteDatabase = SQLiteDatabase.openDatabase(dbFile.absolutePath, null, 0)
    if (db.isOpen) {

      var c = db.rawQuery("SELECT * FROM games WHERE crc32 = ?;", arrayOf(crc))

      if (!c.moveToFirst()) {
        c = db.rawQuery("SELECT * FROM games WHERE romName = ?;", arrayOf(romName))
      }

      if (c.moveToFirst()) {
        do {
          // Passing values
          val id: String? = c.getString(0)
          val name: String? = c.getString(1)
          val system: String? = c.getString(2)
//          val romName: String? = c.getString(3)
          val developer: String? = c.getString(4)
          val crc32: String? = c.getString(5)
          val serial: String? = c.getString(6)
          // Do something Here with values
          if (system == "fbneo") continue
          return Triple(
            name,
            getGamePhoto(system.orEmpty(), name.orEmpty()),
            getGameTypeBySystem(system.orEmpty())
          )
        } while (c.moveToNext())
      }
      c.close()
      db.close()
    }
    return null
  }

  private fun getGamePhoto(system: String, name: String): String {
    val url = "https://thumbnails.libretro.com/"
    val url2 = when (system) {
      "nes" -> "Nintendo - Nintendo Entertainment System/"
      "snes" -> "Nintendo - Super Nintendo Entertainment System/"
      "wsc" -> "Bandai - WonderSwan Color/"
      "ws" -> "Bandai - WonderSwan/"
      "gba" -> "Nintendo - Game Boy Advance/"
      "gbc" -> "Nintendo - Game Boy Color/"
      "gb" -> "Nintendo - Game Boy/"
      "md" -> "Sega - Mega Drive - Genesis/"
      "sms" -> "Sega - Master System - Mark III/"
      "n64" -> "Nintendo - Nintendo 64/"
      "fbneo", "mame2003plus" -> "MAME/"
      "gc" -> "Nintendo - GameCube/"
      "wii" -> "Nintendo - Wii/"
      "nds" -> "Nintendo - Nintendo DS/"
      "psp" -> "Sony - PlayStation Portable/"
      "psx" -> "Sony - PlayStation/"
      "3ds" -> "Nintendo - Nintendo 3DS/"
      else -> ""
    }

    val thumbGameName = name.replace("&", "_")
    val url3 = "Named_Boxarts/${thumbGameName}.png"
    return url + url2 + url3
  }

  private fun getGameTypeBySystem(system: String): String {
    return when (system.lowercase()) {
      "nes" -> "NES"
      "snes" -> "SNES"
      "gba" -> "GBA"
      "gbc", "gb" -> "GBC"
      "wsc", "ws" -> "SWAN"
      "md", "sms" -> "MD"
      "n64" -> "N64"
      "fbneo", "mame2003plus" -> "MAME"
      "nds" -> "NDS"
      "psp" -> "PSP"
      "psx" -> "PSX"
      "3ds" -> "3DS"
      else -> ""
    }
  }

  private fun getGameTypeByExtension(fileName: String): String {
    // neo mame 后缀 zip 忽略
    // wii, gc
    return when (fileName.lowercase()) {
      "nes" -> "NES"
      "smc", "sfc" -> "SNES"
      "gba" -> "GBA"
      "gbc", "gb" -> "GBC"
      "wsc", "ws"/*, "bin" */ -> "SWAN"
      "smd", "md", "gen", "sms", "cue"/*, "iso"*/ -> "MD"
      "n64", "v64", "z64" -> "N64"
      "gcm", "tgc", "iso", "ciso", "gcz", "wbfs", "wia", "rvz", "wad", "dol", "elf", "json" -> "Wii"
      "nds" -> "NDS"
      "bin" -> "PSX"
      "iso" -> "PSP"
      "3ds" -> "3DS"
      else -> ""
    }
  }

  private fun isValidRomFormat(ext: String): Boolean {
    return romExt.contains(ext.lowercase())
  }

  data class ScanRomResult(
    val games: MutableList<Game> = ArrayList(),
    val searchSingleFile: Boolean
  )

  /**===================================扫描游戏 END==================================================*/

  override fun onDestroy() {
    super.onDestroy()
    mService?.stopSelf()
    job.cancel()
    Timber.d("我要退出了 onDestroy")
  }

  private var lastCallUpdateNotification = 0L

  @Subscribe(threadMode = MAIN) fun onDownloadEvent(event: DownloadEvent) {

    if (event.downloadState == DOWNLOAD_STATE_PROGRESS) {
      val now = System.currentTimeMillis()
      if (now - lastCallUpdateNotification < 1000) {
        return
      }
      lastCallUpdateNotification = now
    }

    if (event.downloadState == DOWNLOAD_STATE_ERROR) {
      val dialog: AlertDialog.Builder = AlertDialog.Builder(context)
      dialog.setTitle("Network error")
      dialog.setMessage(event.msg + " There seems to be a connection problem. Please check your network connection and try again")
      dialog.setPositiveButton(android.R.string.ok) { d, which ->
        d.dismiss()
      }
      dialog.show()
    }

    if (event.downloadState == DOWNLOAD_STATE_FINISH || event.downloadState == DOWNLOAD_STATE_PAUSE) {
      ToastUtil.toastAndLog(event.msg)
    }
    event.downloadTask

    flutterChannel?.invokeMethod("updateDownload", event.covertToJson())
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    val messenger = flutterEngine.dartExecutor.binaryMessenger

    // 新建一个 Channel 对象
    flutterChannel = MethodChannel(messenger, "com.actduck.videogame/video_game")

    // TODO: Register the ListTileNativeAdFactory
    GoogleMobileAdsPlugin.registerNativeAdFactory(
      flutterEngine, "listTile", ListTileNativeAdFactory(context)
    );

    GoogleMobileAdsPlugin.registerNativeAdFactory(
      flutterEngine, "homeTile",
      HomeTileNativeAdFactory(context)
    );
  }

  override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
    super.cleanUpFlutterEngine(flutterEngine)

    // TODO: Unregister the ListTileNativeAdFactory
    GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "listTile")
    GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "homeTile")
  }

  /*******************************用户同意************************************/
  private lateinit var consentInformation: ConsentInformation
  private var consentForm: ConsentForm? = null

  fun initConsentForm() {
    // val debugSettings = ConsentDebugSettings.Builder(this)
    //   .setDebugGeography(
    //     ConsentDebugSettings
    //       .DebugGeography
    //       .DEBUG_GEOGRAPHY_EEA
    //   )
    //   .addTestDeviceHashedId("78C4E16B02E50190CBC879F430AE7588")
    //   .build()

    // Set tag for underage of consent. Here false means users are not underage.
    val params = ConsentRequestParameters.Builder()
      .setTagForUnderAgeOfConsent(false)
      // .setConsentDebugSettings(debugSettings)
      .build()

    consentInformation = UserMessagingPlatform.getConsentInformation(this)
    consentInformation.requestConsentInfoUpdate(
      this,
      params,
      {
        // The consent information state was updated.
        // You are now ready to check if a form is available.
        if (consentInformation.isConsentFormAvailable) {
          loadForm()
        }

      },
      { formError ->
        // Handle the error.
        Timber.d("initConsentForm: $formError")
      }
    )
  }

  private fun loadForm() {
    UserMessagingPlatform.loadConsentForm(
      this,
      { consentForm ->
        this.consentForm = consentForm
        if (consentInformation.consentStatus == ConsentInformation.ConsentStatus.REQUIRED) {
          Timber.d("loadForm: 需要确认")

          consentForm.show(this) { formError ->
            // Handle dismissal by reloading form.
            loadForm()
          }
        }
        if (consentInformation.consentStatus == ConsentInformation.ConsentStatus.OBTAINED) {
          Timber.d("loadForm: 用户确认了")
          // Handler().postDelayed({consentInformation.reset()}, 5000)
          val agree = PreferenceManager.getDefaultSharedPreferences(this)
            .getString("IABTCF_PublisherConsent", "") == "1"
          Timber.d("loadForm: 用户同意没 $agree")

          flutterChannel?.invokeMethod("setConsent", agree)

          // applovin
          AppLovinPrivacySettings.setHasUserConsent(agree, context)

          // unity
          val gdprMetaData = MetaData(this)
          gdprMetaData["gdpr.consent"] = agree
          gdprMetaData.commit()

        }

        if (consentInformation.consentStatus == ConsentInformation.ConsentStatus.NOT_REQUIRED) {
          Timber.d("loadForm: 用户无需同意")
        }
        if (consentInformation.consentStatus == ConsentInformation.ConsentStatus.UNKNOWN) {
          Timber.d("loadForm: 用户同意未知")
        }

      },
      { formError ->
        // Handle the error.
      }
    )
  }
}
