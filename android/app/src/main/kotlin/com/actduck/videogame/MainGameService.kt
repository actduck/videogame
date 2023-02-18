package com.actduck.videogame

import android.app.Service
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Binder
import android.os.IBinder
import com.actduck.videogame.data.source.remote.DownloadService
import com.actduck.videogame.util.LemUtils
import com.actduck.videogame.util.NDSUtils
import com.swordfish.lemuroid.lib.library.db.entity.Game
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.CoroutineExceptionHandler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import me.magnum.melonds.domain.repositories.RomsRepository
import me.magnum.melonds.domain.repositories.SettingsRepository
import okhttp3.ResponseBody
import org.apache.commons.io.FilenameUtils
import paulscode.android.mupen64plusae.util.FileUtil
import timber.log.Timber
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import javax.inject.Inject

@AndroidEntryPoint
class MainGameService : Service() {
  // Binder given to clients
  private val binder = LocalBinder()

  /**
   * Class used for the client Binder.  Because we know this service always
   * runs in the same process as its clients, we don't need to deal with IPC.
   */
  inner class LocalBinder : Binder() {
    // Return this instance of LocalService so clients can call public methods
    fun getService(): MainGameService = this@MainGameService
  }

  override fun onBind(intent: Intent): IBinder {
    return binder
  }

  @Inject lateinit var service: DownloadService
  @Inject lateinit var ndsUtils: NDSUtils
  @Inject lateinit var lemUtils: LemUtils

  val coroutineExceptionHandler = CoroutineExceptionHandler { _, throwable ->
    throwable.printStackTrace()
    Timber.e("""出错了${throwable.printStackTrace()}""")
  }

  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    return super.onStartCommand(intent, flags, startId)
  }

  fun downloadGameDb(context: Context) {
    val fileDir = getExternalFilesDir("db")
    val dbFile = File(fileDir, "libretro-db.sqlite")
    if (dbFile.exists()) {
      Timber.d("游戏本地数据库存在，不用下载")
      return
    }

    Timber.d("游戏本地数据库不存在，开始下载")
    CoroutineScope(Dispatchers.IO + coroutineExceptionHandler).launch {
      val url = "https://vg.actduck.com/videogame/file/libretro-db.zip"
      val dbZipFile = File(context.externalCacheDir, FilenameUtils.getName(url))
      val responseBody = service.downloadFile(url).body()
      val saveFile = saveFile(responseBody, dbZipFile.absolutePath)
      FileUtil.unzipAll(
        context,
        Uri.fromFile(File(saveFile)),
        context.getExternalFilesDir("db")?.absolutePath
      )
      Timber.d("游戏数据准备成功")
      dbZipFile.delete()
    }
  }

  fun downloadBios(context: Context) {

    val bios1 = File(getExternalFilesDir("local-rom/NEO"), "neogeo.zip")
    val bios2 = File(getExternalFilesDir("local-rom/MAME"), "neogeo.zip")
    val bios3 = File(getExternalFilesDir("rom/NEO"), "neogeo.zip")
    val bios4 = File(getExternalFilesDir("rom/MAME"), "neogeo.zip")
    if (bios1.exists() && bios2.exists() && bios3.exists() && bios4.exists()) {
      Timber.d("游戏本地bios存在，不用下载")
      return
    }
    Timber.d("游戏本地bios不存在，开始下载")

    CoroutineScope(Dispatchers.IO + coroutineExceptionHandler).launch {

      var bios = bios1

      if (!bios.exists()) {
        bios = bios2
      }

      if (!bios.exists()) {
        bios = bios3
      }

      if (!bios.exists()) {
        bios = bios4
      }

      if (!bios.exists()) {
        Timber.d("所有的neogeo.zip 都不存在 开始网络下载吧")

        val url = "https://vg.actduck.com/videogame/file/neogeo.zip"
        val responseBody = service.downloadFile(url).body()
        val neogeoInCache = saveFile(
          responseBody,
          File(context.externalCacheDir, FilenameUtils.getName(url)).absolutePath
        )
        bios = File(neogeoInCache)
      }

      if (!bios1.exists()) {
        FileUtil.copyFile(bios, bios1, false)
      }
      if (!bios2.exists()) {
        FileUtil.copyFile(bios, bios2, false)
      }
      if (!bios3.exists()) {
        FileUtil.copyFile(bios, bios3, false)
      }
      if (!bios4.exists()) {
        FileUtil.copyFile(bios, bios4, false)
      }
      Timber.d("本地bios准备成功")
      bios.delete()
    }
  }

  private fun saveFile(body: ResponseBody?, toSaveFile: String): String {
    if (body == null)
      return ""
    var input: InputStream? = null
    try {
      input = body.byteStream()
      //val file = File(getCacheDir(), "cacheFileAppeal.srl")
      val fos = FileOutputStream(toSaveFile)
      fos.use { output ->
        val buffer = ByteArray(4 * 1024) // or other buffer size
        var read: Int
        while (input.read(buffer).also { read = it } != -1) {
          output.write(buffer, 0, read)
        }
        output.flush()
      }
      return toSaveFile
    } catch (e: Exception) {
      Timber.e("saveFile$e")
    } finally {
      input?.close()
    }
    return ""
  }

  override fun onDestroy() {
    super.onDestroy()
    Timber.d("服务要退出了")
  }

  /**=========================================nds相关 START=============================================*/
  @Inject lateinit var settingsRepository: SettingsRepository
  @Inject lateinit var ndsRomsRepository: RomsRepository

  fun prepareNDSDir() {
    ndsUtils.prepareNDSDir()
  }

  fun addLemGame(games: List<com.actduck.videogame.data.Game>) {
    lemUtils.addLemGame(games)
  }

  fun refreshUserNDSDir(searchUri: String) {
    ndsUtils.refreshUserNDSDir(searchUri)
  }

  fun getLemGame(fileUrl: String): Game? {
    return lemUtils.getLemGame(fileUrl)
  }

  fun updateCore(
    gameTypeName: String? = "",
    games: List<com.actduck.videogame.data.Game> = emptyList()
  ) {
    lemUtils.updateCore(gameTypeName, games)

  }
  /**=========================================lem相关 START=============================================*/
}