package com.actduck.videogame.util

import android.net.Uri
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import com.actduck.videogame.MyApp
import com.actduck.videogame.vm.coroutineExceptionHandler
import com.swordfish.lemuroid.app.shared.library.CoreUpdateWork
import com.swordfish.lemuroid.app.shared.library.LibraryIndexScheduler
import com.swordfish.lemuroid.lib.library.SystemID
import com.swordfish.lemuroid.lib.library.db.RetrogradeDatabase
import com.swordfish.lemuroid.lib.library.db.entity.Game
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.apache.commons.io.FilenameUtils
import paulscode.android.mupen64plusae.util.FileUtil
import timber.log.Timber
import java.io.File

class LemUtils(
  var retrogradedb: RetrogradeDatabase
) {

  private val lemSupportGameType = listOf(
    "NES",
    "SNES",
    "GBA",
    "GBC",
    "SWAN",
    "MD",
    "N64",
    "MAME",
    "NDS",
    "PSP",
    "PSX",
    "3DS"
  )

  fun addLemGame(link: String?, gameTypeName: String?) {
    if (
      link.isNullOrBlank()
      || gameTypeName.isNullOrBlank()
      || !lemSupportGameType.contains(gameTypeName)
    ) {
      return
    }

    val fileName = FilenameUtils.getName(link)
    val file = File(MyApp.instance.getExternalFilesDir("rom/$gameTypeName"), fileName)
    val fileUri = Uri.fromFile(file).toString()

    realAddLemGame(fileName, fileUri, gameTypeName)
  }

  private fun realAddLemGame(fileName: String, fileUri: String, gameTypeName: String) {
    CoroutineScope(Dispatchers.IO + coroutineExceptionHandler).launch {
      Timber.d("添加游戏到Lem数据库")
      val dbGame = retrogradedb.gameDao().selectByFileUri(fileUri)
      if (dbGame != null) {
        Timber.d("Lem 本地数据库有 更新 fileName:$fileName")
        val game = Game(
          id = dbGame.id,
          fileName = fileName,
          fileUri = fileUri,
          title = FilenameUtils.getBaseName(fileName),
          systemId = gameTypeName2SystemId(gameTypeName),
          developer = null,
          coverFrontUrl = null,
          lastIndexedAt = System.currentTimeMillis()
        )
        retrogradedb.gameDao().update(game)
      } else {
        Timber.d("Lem 本地数据库没有 新增加 fileName:$fileName")
        val game = Game(
          fileName = fileName,
          fileUri = fileUri,
          title = FilenameUtils.getBaseName(fileName),
          systemId = gameTypeName2SystemId(gameTypeName),
          developer = null,
          coverFrontUrl = null,
          lastIndexedAt = System.currentTimeMillis()
        )
        retrogradedb.gameDao().insert(listOf(game))
      }
    }
  }

  fun addLemGame(games: List<com.actduck.videogame.data.Game>) {
    for (game in games) {
      realAddLemGame(
        FileUtil.getFileName(MyApp.instance, Uri.parse(game.romLocalPath)),
        game.romLocalPath!!,
        game.gameType!!.name
      )
    }
  }

  private fun gameTypeName2SystemId(gameTypeName: String): String {
    return when (gameTypeName) {
      "PSP" -> SystemID.PSP.dbname
      "PSX" -> SystemID.PSX.dbname
      "3DS" -> SystemID.NINTENDO_3DS.dbname
      "NES" -> SystemID.NES.dbname
      "SNES" -> SystemID.SNES.dbname
      "GBA" -> SystemID.GBA.dbname
      "GBC" -> SystemID.GBC.dbname
      "SWAN" -> SystemID.WSC.dbname
      "MD" -> SystemID.GENESIS.dbname
      "N64" -> SystemID.N64.dbname
      "MAME" -> SystemID.MAME2003PLUS.dbname
      "NDS" -> SystemID.NDS.dbname
      else -> ""
    }
  }

  fun getLemGame(fileUrl: String): Game? {
    val game = retrogradedb.gameDao().selectByFileUri(fileUrl)
    if (game != null) {
      Timber.w("获取LemGame成功：$game")
    }
    return game
  }

  fun updateCore(
    gameTypeName: String? = "",
    games: List<com.actduck.videogame.data.Game> = emptyList()
  ) {
    if (gameTypeName == "PSP" || games.any { it.gameType?.name == "PSP" }) {
      Timber.w("LemGame 更新core 开始")
      WorkManager.getInstance(MyApp.instance)
        .beginUniqueWork(
          LibraryIndexScheduler.CORE_UPDATE_WORK_ID,
          ExistingWorkPolicy.APPEND_OR_REPLACE,
          OneTimeWorkRequestBuilder<CoreUpdateWork>().build()
        )
        .enqueue()
    }
  }
}