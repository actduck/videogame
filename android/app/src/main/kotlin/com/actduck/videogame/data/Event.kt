package com.actduck.videogame.data

import com.actduck.videogame.data.source.DownloadState
import com.actduck.videogame.data.source.remote.DownloadTask

class ModuleInstallEvent() {

}

class DownloadEvent(
  var downloadTask: DownloadTask?,
  @DownloadState var downloadState: Int,
  var msg: String? = null,
) {

}

class RefreshFavoriteEvent()

class RefreshRecentEvent()