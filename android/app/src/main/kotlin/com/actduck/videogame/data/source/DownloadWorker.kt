package com.actduck.videogame.data.source

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.net.Uri
import android.os.Build
import androidx.annotation.IntDef
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.hilt.work.HiltWorker
import androidx.work.CoroutineWorker
import androidx.work.ForegroundInfo
import androidx.work.WorkerParameters
import com.actduck.videogame.R
import com.actduck.videogame.data.DownloadEvent
import com.actduck.videogame.data.Game
import com.actduck.videogame.data.GameMD5
import com.actduck.videogame.data.source.remote.DownloadService
import com.actduck.videogame.data.source.remote.DownloadTask.Finished
import com.actduck.videogame.data.source.remote.DownloadTask.Progress
import com.actduck.videogame.data.source.remote.HOST
import com.actduck.videogame.data.source.remote.downloadToFileWithProgress
import com.actduck.videogame.util.FileSplitUtils
import com.actduck.videogame.util.LemUtils
import com.actduck.videogame.util.NDSUtils
import com.actduck.videogame.util.toDataClass
import com.google.firebase.analytics.FirebaseAnalytics
import com.google.firebase.analytics.ktx.logEvent
import dagger.assisted.Assisted
import dagger.assisted.AssistedInject
import org.apache.commons.io.FilenameUtils
import org.greenrobot.eventbus.EventBus
import paulscode.android.mupen64plusae.util.FileUtil
import timber.log.Timber
import java.io.File
import java.util.Timer
import javax.inject.Inject
import kotlin.concurrent.schedule
import kotlin.coroutines.cancellation.CancellationException

const val DOWNLOAD_STATE_START = 0  // 下载开始
const val DOWNLOAD_STATE_PROGRESS = 1 // 下载中
const val DOWNLOAD_STATE_FINISH = 2   // 下载完成
const val DOWNLOAD_STATE_UNZIPPING = 3 // 解压缩
const val DOWNLOAD_STATE_UNKNOWN = 4  // 未知
const val DOWNLOAD_STATE_ERROR = 5  // 出错
const val DOWNLOAD_STATE_MERGING = 6  // 合并文件
const val DOWNLOAD_STATE_PAUSE = 7  // 下载暂停

@Retention(AnnotationRetention.SOURCE)
@IntDef(
  DOWNLOAD_STATE_START,
  DOWNLOAD_STATE_PROGRESS,
  DOWNLOAD_STATE_FINISH,
  DOWNLOAD_STATE_UNZIPPING,
  DOWNLOAD_STATE_UNKNOWN,
  DOWNLOAD_STATE_ERROR,
  DOWNLOAD_STATE_MERGING,
  DOWNLOAD_STATE_PAUSE,
)
annotation class DownloadState

@HiltWorker
class DownloadWorker @AssistedInject constructor(
  @Assisted context: Context,
  @Assisted workerParams: WorkerParameters,
) : CoroutineWorker(context, workerParams) {

  @Inject lateinit var downloadService: DownloadService

  @Inject lateinit var repo: Repository
  var gameId = 0L
  override suspend fun doWork(): Result {

    val gameJson = inputData.getString("game_json")
    val game: Game? = gameJson?.toDataClass()

    setupNotification(applicationContext)

    if (game == null) {
      Timber.e("Game is null")
      onDownloadError(MyDownloadException("Game is null"), null)
      return Result.failure()
    }

    gameId = game.id
    EventBus.getDefault().post(
      DownloadEvent(
        Progress(id = id.toString(), gameId = game.id, percent = 0),
        downloadState = DOWNLOAD_STATE_START,
      )
    )
    try {
      val gameMD5 = downloadService.romInfo(gameId)
      if (gameMD5.splitCount > 0) {
        downloadSplitFileGame(game, gameMD5)
      } else {
        download1FileGame(game, gameMD5)
      }
    } catch (e: Exception) {
      e.printStackTrace()
      // onDownloadError(MyDownloadException(e.message), game)
      Timber.e("RomInfo is null")
    }

    return Result.success()
  }

  private suspend fun downloadSplitFileGame(game: Game, info: GameMD5) {
    try {
      val zipRomName = FilenameUtils.getName(game.zipUrl)
      Timber.d("下载开始：${zipRomName}")
      updateNotification(zipRomName, DOWNLOAD_STATE_PROGRESS, 0, null, false)
      val cacheDir =
        applicationContext.externalCacheDir ?: throw MyDownloadException("Cache Dir is null")

      // 本地已有下载完成的文件 dff = downloadFinishedFile
      val dff = File(cacheDir, zipRomName)
      if (dff.exists() && FileSplitUtils.getFileMD5(dff) == info.zipRom) {
        val task = Finished(file = dff)
        task.gameId = game.id
        task.id = id.toString()
        onDownloadComplete(task, game)
        return
      }

      val splitRomArr = info.splitRoms.split(",")

      val c = info.splitCount
      var j = 0
      for (i in 0 until c) {
        val fileUrl = "$HOST${FilenameUtils.removeExtension(game.zipUrl)}_$i.part"
        Timber.d("下载分片开始：${i + 1}/$c $zipRomName")

        // 先校验已下载的文件
        val fileSplitName = FilenameUtils.getBaseName(game.zipUrl) + "_$i.part"
        val splitFile = File(cacheDir, fileSplitName)
        if (splitFile.exists() && FileSplitUtils.getFileMD5(splitFile) == splitRomArr[i]) {
          Timber.w("本地已经下载过分片，下载下一个吧")
          j++
          if (j == c - 1) {
            tryMergeFile(zipRomName, cacheDir, dff, info)
            // 校验合并的文件正确
            val dffMD5 = FileSplitUtils.getFileMD5(dff)
            if (dffMD5 == info.zipRom) {
              onDownloadComplete(Finished(id.toString(), gameId, dff), game)
            } else {
              dff.delete()
              throw MyDownloadException("Merged file is incorrect")
            }
            return
          }
          continue
        }

        val response = downloadService.downloadFile(
          fileUrl, range = getFileRange(fileSplitName, cacheDir.absolutePath)
        )
        if (!response.isSuccessful) {
          splitFile.delete()
          throw MyDownloadException("response is not successful ")
        }

        response.body()?.downloadToFileWithProgress(
          cacheDir, "${FilenameUtils.getBaseName(zipRomName)}_$i.part"
        )?.collect { task ->
          when (task) {
            is Progress -> {
              task.gameId = game.id
              task.id = id.toString()
//                  Timber.d("下载分片进度：==> ${task.percent}")
              task.percent = ((i * 100 / c) + ((1.0 / c) * task.percent)).toInt()
//                  Timber.d("下载总进度：==> ${task.percent}")
              updateNotification(
                zipRomName, DOWNLOAD_STATE_PROGRESS, task.percent, null, false
              )
              EventBus.getDefault().post(
                DownloadEvent(
                  task, downloadState = DOWNLOAD_STATE_PROGRESS
                )
              )
            }
            is Finished -> {
              task.gameId = game.id
              task.id = id.toString()
              val splitMD5 = FileSplitUtils.getFileMD5(task.file)
              if (splitMD5 == splitRomArr[i]) {
                Timber.d("下载分片完成：${i + 1}/$c $zipRomName ")
                j++
              } else {
                Timber.e("下载分片大小不对，要重新下载, 本地md5 $splitMD5 远程md5 ${splitRomArr[i]}")
                task.file.delete()
                throw MyDownloadException("Download data is incorrect")
              }
              if (i == c - 1) {
                //合并文件
                tryMergeFile(zipRomName, cacheDir, dff, info)

                // 校验合并的文件正确
                val dffMD5 = FileSplitUtils.getFileMD5(dff)
                if (dffMD5 == info.zipRom) {
                  task.file = dff
                  onDownloadComplete(task, game)
                } else {
                  dff.delete()
                  throw MyDownloadException("Merged file is incorrect")
                }
              }
            }
          }
        }
      }
    } catch (e: Exception) {
      onDownloadError(e, game)
    }
  }

  private fun tryMergeFile(
    zipRomName: String?, cacheDir: File, dff: File, info: GameMD5
  ) {
    EventBus.getDefault().post(
      DownloadEvent(
        Finished(id.toString(), gameId, dff), downloadState = DOWNLOAD_STATE_MERGING
      )
    )
    Timber.d("开始合并文件 $zipRomName ")
    updateNotification(zipRomName, DOWNLOAD_STATE_MERGING)
    FileSplitUtils.merge(
      "${cacheDir.absolutePath}/${FilenameUtils.getBaseName(zipRomName)}", dff, info.splitCount
    )
    Timber.d("合并文件完成 $zipRomName ")
  }

  private suspend fun download1FileGame(game: Game, info: GameMD5) {
    try {
      val zipRomName = FilenameUtils.getName(game.zipUrl)
      Timber.d("下载开始：${zipRomName}")
      updateNotification(zipRomName, DOWNLOAD_STATE_PROGRESS, 0, null, false)

      val cacheDir =
        applicationContext.externalCacheDir ?: throw MyDownloadException("Cache Dir is null")

      // 本地已有下载完成的文件
      val dff = File(cacheDir, zipRomName)
      if (dff.exists() && FileSplitUtils.getFileMD5(dff) == info.zipRom) {
        val task = Finished(file = dff)
        task.gameId = game.id
        task.id = id.toString()
        onDownloadComplete(task, game)
      }

      val response = downloadService.downloadFile(
        HOST + game.zipUrl, range = getFileRange(zipRomName, cacheDir.absolutePath)
      )

      if (!response.isSuccessful) {
        dff.delete()
        throw MyDownloadException("response is not successful ")
      }
      // val remoteLength = fileRemoteLength(response.headers())

      response.body()?.downloadToFileWithProgress(cacheDir, zipRomName)?.collect { task ->
        when (task) {
          is Progress -> {
            task.gameId = game.id
            task.id = id.toString()
//              Timber.d("下载进度：${fileName} ==> ${task.percent}")
            updateNotification(
              zipRomName, DOWNLOAD_STATE_PROGRESS, task.percent, null, false
            )
            EventBus.getDefault().post(DownloadEvent(task, downloadState = DOWNLOAD_STATE_PROGRESS))
          }
          is Finished -> {
            task.gameId = game.id
            task.id = id.toString()
            // 校验下载的文件MD5 和 服务器的一致
            val localMD5 = FileSplitUtils.getFileMD5(task.file)
            if (localMD5 == info.zipRom) {
              onDownloadComplete(task, game)
            } else {
              Timber.e("下载分片大小不对，要重新下载, 本地md5 ${localMD5} 远程md5 ${info.zipRom}")
              task.file.delete()
              throw MyDownloadException("Download data is incorrect")
            }
          }
        }
        Timber.d("downloadGame downloadTask是:$task")
      }
    } catch (e: Exception) {
      onDownloadError(e, game)
    }
  }

  private fun getFileRange(
    filename: String?,
    savedDir: String,
  ): String? {
    val saveFilePath = savedDir + File.separator + filename
    val partialFile = File(saveFilePath)
    if (!partialFile.exists()) {
      return null
    }
    val downloadedBytes: Long = partialFile.length()
    Timber.d("恢复下载 Resume download: Range: bytes=$downloadedBytes-")
    return "bytes=$downloadedBytes-"
  }

  private suspend fun onDownloadComplete(
    task: Finished,
    game: Game,
  ) {
    val destDir = File(applicationContext.getExternalFilesDir("rom"), game.gameType!!.name)

    Timber.d("下载完成：${task.file}")
    task.gameId = game.id
    task.id = id.toString()

    val realRomName = FilenameUtils.getName(game.url)
    val destRomFile = File(destDir, realRomName)
    val zipRomName = FilenameUtils.getName(game.zipUrl)

    if (game.zipUrl != game.url) {
      // 1,解压缩zip到cache文件夹 2,移动到目的地 3,删除压缩包
      EventBus.getDefault().post(DownloadEvent(task, downloadState = DOWNLOAD_STATE_UNZIPPING))
      updateNotification(zipRomName, DOWNLOAD_STATE_UNZIPPING)
      Timber.d("开始解压：${task.file}")
      FileUtil.ExtractFirstROMFromZip(
        applicationContext, Uri.fromFile(task.file), destDir.parentFile?.absolutePath
      )
      Timber.d("解压成功：$realRomName")

      Timber.d("开始移动：$realRomName")
      FileUtil.copyFile(File(destDir.parentFile, realRomName), destRomFile, true)
      Timber.d("移动成功：$destRomFile")

      Timber.d("开始删除压缩包：${task.file.name}")
      val delete = task.file.delete()
      Timber.d("删除压缩包：$delete")
    } else {
      // 只移动
      Timber.d("开始移动：$realRomName")
      FileUtil.copyFile(task.file, destRomFile, true)
      Timber.d("移动成功：$destRomFile")
    }

    game.romLocalPath = destRomFile.absolutePath
    repo.saveGame(game)
    updateGameRepo(game)
    EventBus.getDefault().post(
      DownloadEvent(
        task,
        downloadState = DOWNLOAD_STATE_FINISH,
        msg = game.name + " download success"
      )
    )
    updateNotification(realRomName, DOWNLOAD_STATE_FINISH)
  }

  private fun onDownloadError(
    e: Exception,
    game: Game?,
  ) {
    Timber.e("下载出错了")
    e.printStackTrace()
    val isPauseDownload = e is CancellationException
    val state = if (isPauseDownload) DOWNLOAD_STATE_PAUSE else DOWNLOAD_STATE_ERROR
    val msg =
      if (isPauseDownload) applicationContext.resources.getString(R.string.game_download_pause) else e.message
    EventBus.getDefault().post(
      DownloadEvent(
        Progress(id = id.toString(), gameId = game?.id, percent = 0),
        downloadState = state,
        msg = msg
      )
    )
    updateNotification(FilenameUtils.getName(game?.zipUrl), state)

    if (state == DOWNLOAD_STATE_ERROR) {
      FirebaseAnalytics.getInstance(applicationContext).logEvent("download_error") {
        param("game_name", game?.name!!)
        param("err_msg", msg.orEmpty())
      }
    }
  }

  /*************************************** 通知START ******************************************/
  private var lastCallUpdateNotification: Long = 0

  private val CHANNEL_ID = "DOWNLOADER_NOTIFICATION"

  private fun setupNotification(context: Context) {
    // Make a channel if necessary
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      // Create the NotificationChannel
      val res = applicationContext.resources
      val channelName: String = res.getString(R.string.notification_channel_background_tasks)
      val channelDescription: String = res.getString(R.string.notification_channel_background_tasks)
      val importance: Int = NotificationManager.IMPORTANCE_LOW
      val channel = NotificationChannel(CHANNEL_ID, channelName, importance)
      channel.description = channelDescription
      channel.setSound(null, null)

      // Add the channel
      val notificationManager: NotificationManagerCompat = NotificationManagerCompat.from(context)
      notificationManager.createNotificationChannel(channel)
    }
  }

  private fun updateNotification(
    title: String?,
    @DownloadState state: Int,
    progress: Int = 0,
    intent: PendingIntent? = null,
    finalize: Boolean = true,
  ) {
    val builder = NotificationCompat.Builder(applicationContext, CHANNEL_ID).setContentTitle(title)
      .setContentIntent(intent).setOnlyAlertOnce(true).setAutoCancel(true)
      .setPriority(NotificationCompat.PRIORITY_LOW)
    val res = applicationContext.resources

    when (state) {
      DOWNLOAD_STATE_START -> {
        builder.setContentText(res.getString(R.string.game_download_start))
          .setProgress(100, 0, true)
      }
      DOWNLOAD_STATE_PROGRESS -> {
        if (progress <= 0) {
          builder.setContentText(res.getString(R.string.game_download_start))
            .setProgress(0, 0, false)
          builder.setOngoing(false).setSmallIcon(R.drawable.ic_lemuroid_tiny)
        } else if (progress < 100) {
          builder.setContentText(res.getString(R.string.game_download_running))
            .setProgress(100, progress, false)
          builder.setOngoing(true).setSmallIcon(android.R.drawable.stat_sys_download)
        } else {
          builder.setContentText(res.getString(R.string.game_download_complete))
            .setProgress(0, 0, false)
          builder.setOngoing(false).setSmallIcon(android.R.drawable.stat_sys_download_done)
        }
      }
      DOWNLOAD_STATE_PAUSE -> {
        builder.setContentText(res.getString(R.string.game_download_pause))
          .setSmallIcon(R.drawable.ic_lemuroid_tiny)
      }
      DOWNLOAD_STATE_FINISH -> {
        builder.setContentText(res.getString(R.string.game_download_complete))
          .setProgress(0, 0, false)
        builder.setOngoing(false).setSmallIcon(android.R.drawable.stat_sys_download_done)
      }

      DOWNLOAD_STATE_ERROR -> {
        builder.setContentText(res.getString(R.string.game_download_failed))
          .setProgress(0, 0, false)
        builder.setOngoing(false).setSmallIcon(android.R.drawable.stat_sys_download_done)
      }

      DOWNLOAD_STATE_UNZIPPING -> {
        builder.setContentText(res.getString(R.string.unzipping)).setProgress(0, 0, false)
        builder.setOngoing(false).setSmallIcon(android.R.drawable.stat_sys_download_done)
      }

      DOWNLOAD_STATE_MERGING -> {
        builder.setContentText(res.getString(R.string.merging)).setProgress(0, 0, false)
        builder.setOngoing(false).setSmallIcon(android.R.drawable.stat_sys_download_done)
      }

      else -> {
        builder.setProgress(0, 0, false)
        builder.setOngoing(false).setSmallIcon(R.drawable.ic_lemuroid_tiny)
      }
    }

    if (System.currentTimeMillis() - lastCallUpdateNotification < 1000) {
      if (finalize) {
        Timber.d(
          "Update too frequently!!!!, but it is the final update, we should sleep a second to ensure the update call can be processed"
        )
        try {
          Thread.sleep(1000)
        } catch (e: InterruptedException) {
          e.printStackTrace()
        }
      } else {
        Timber.d("Update too frequently!!!!, this should be dropped")
        return
      }
    }
    Timber.d(
      "Update notification: {notificationId: $gameId, title: $title, status: $state, progress: $progress}"
    )
    lastCallUpdateNotification = System.currentTimeMillis()
    when (state) {
      DOWNLOAD_STATE_START -> {
        setForegroundAsync(ForegroundInfo(gameId.toInt(), builder.build()))
      }
      DOWNLOAD_STATE_FINISH, DOWNLOAD_STATE_PAUSE -> {
        NotificationManagerCompat.from(applicationContext).notify(gameId.toInt(), builder.build())
        Timer().schedule(3000) {
          NotificationManagerCompat.from(applicationContext).cancel(gameId.toInt())
        }
      }
      else -> {
        NotificationManagerCompat.from(applicationContext).notify(gameId.toInt(), builder.build())
      }
    }
  }
  /*************************************** 通知END ******************************************/

  /**=========================================nds lem 相关 START=============================================*/

  @Inject lateinit var ndsUtils: NDSUtils
  @Inject lateinit var lemUtils: LemUtils
  private fun updateGameRepo(game: Game) {
    if (game.gameType?.name == "NDS") {
      ndsUtils.refreshNDSROMs()
    }
    lemUtils.addLemGame(game.url, game.gameType?.name)
    lemUtils.updateCore(game.gameType?.name)
  }

  /**=========================================nds lem 相关 END=============================================*/

}

class MyDownloadException(msg: String?) : RuntimeException(msg)