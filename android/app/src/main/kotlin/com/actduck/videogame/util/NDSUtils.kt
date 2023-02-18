package com.actduck.videogame.util

import android.net.Uri
import com.actduck.videogame.MyApp
import me.magnum.melonds.domain.repositories.RomsRepository
import me.magnum.melonds.domain.repositories.SettingsRepository
import timber.log.Timber
import java.io.File

class NDSUtils(
  var settingsRepository: SettingsRepository,
  var ndsRomsRepository: RomsRepository
) {

  fun prepareNDSDir() {

    val dir1 = File(MyApp.instance.getExternalFilesDir("rom"), "NDS")
//    val dir2 = File(getExternalFilesDir("local-rom"), "NDS")

    if (!dir1.exists()) dir1.mkdirs()
//    if (!dir2.exists()) dir1.mkdirs()

//    val uri =
//      RomFileProvider.getUriForFile(this, BuildConfig.APPLICATION_ID + ".romfileprovider", dir1)

//    Timber.d("NDS ROM目录扫描成功：%s", uri.path)
    val ndsDir = setOf(Uri.fromFile(dir1)/*, Uri.fromFile(dir2)*/)
    settingsRepository.addRomSearchDirectories(ndsDir)
    ndsRomsRepository.rescanRoms()
  }

  fun refreshNDSROMs() {
    ndsRomsRepository.rescanRoms()
    Timber.d("刷新NDS游戏")
  }

  fun refreshUserNDSDir(dirUri: String) {
    Timber.d("刷新用户NDS游戏文件夹")

    val dir1 = File(MyApp.instance.getExternalFilesDir("rom"), "NDS")
    if (!dir1.exists()) dir1.mkdirs()

    val ndsDir = setOf(Uri.fromFile(dir1), Uri.parse(dirUri))
    settingsRepository.addRomSearchDirectories(ndsDir)
    ndsRomsRepository.rescanRoms()
  }
}