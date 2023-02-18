package com.actduck.videogame.vm

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.lifecycle.SavedStateHandle
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequest
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import com.actduck.videogame.data.DownloadEvent
import com.actduck.videogame.data.Game
import com.actduck.videogame.data.source.DOWNLOAD_STATE_ERROR
import com.actduck.videogame.data.source.DOWNLOAD_STATE_START
import com.actduck.videogame.data.source.DOWNLOAD_STATE_UNKNOWN
import com.actduck.videogame.data.source.DownloadState
import com.actduck.videogame.data.source.DownloadWorker
import com.actduck.videogame.data.source.Repository
import com.actduck.videogame.data.source.remote.ApiService
import com.actduck.videogame.data.source.remote.DownloadService
import com.actduck.videogame.data.source.remote.DownloadTask
import com.actduck.videogame.data.source.remote.DownloadTask.Finished
import com.actduck.videogame.data.source.remote.DownloadTask.Progress
import com.actduck.videogame.util.ToastUtil.toastAndLog
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.CoroutineExceptionHandler
import kotlinx.coroutines.flow.MutableStateFlow
import org.greenrobot.eventbus.Subscribe
import org.greenrobot.eventbus.ThreadMode.MAIN
import timber.log.Timber
import javax.inject.Inject

//
///*
// * Copyright 2022 The Android Open Source Project
// *
// * Licensed under the Apache License, Version 2.0 (the "License");
// * you may not use this file except in compliance with the License.
// * You may obtain a copy of the License at
// *
// *     https://www.apache.org/licenses/LICENSE-2.0
// *
// * Unless required by applicable law or agreed to in writing, software
// * distributed under the License is distributed on an "AS IS" BASIS,
// * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// * See the License for the specific language governing permissions and
// * limitations under the License.
// */
//

@HiltViewModel
class GameDetailViewModel @Inject constructor(
  private val savedStateHandle: SavedStateHandle,
  private val repo: Repository,
  private val apiService: ApiService,
  private val downloadService: DownloadService,
  @ApplicationContext private val context: Context,
) : EventViewModel() {

  private val _uiState = MutableStateFlow(GameDetailUIState(loading = true))

  fun downloadGame(game: Game) {

    val downloadReq: OneTimeWorkRequest = OneTimeWorkRequestBuilder<DownloadWorker>().setInputData(
      Data.Builder().putLong("gameId", game.id).build()
    ).build()

    WorkManager.getInstance(context).enqueueUniqueWork(
      game.id.toString(), ExistingWorkPolicy.REPLACE, downloadReq
    )
    _uiState.value = _uiState.value.copy(downloadState = DOWNLOAD_STATE_START)
  }

  fun pauseDownloadGame(game: Game) {
    WorkManager.getInstance(context).cancelUniqueWork(
      game.id.toString(),
    )
  }

  @Subscribe(threadMode = MAIN) fun onDownloadEvent(event: DownloadEvent) {
    // 判断相同游戏
    val task = event.downloadTask

    if (event.downloadState == DOWNLOAD_STATE_ERROR) {
      toastAndLog(event.msg)
    }

    var sameGame = false
    val currentGame = _uiState.value.currentGame

    if (currentGame != null) {
      when (task) {
        is Progress -> {
          if (task.gameId == currentGame.id) {
            sameGame = true
          }
        }
        is Finished -> {
          if (task.gameId == currentGame.id) {
            sameGame = true
          }
          // 游戏库刷新
          // updateGameRepo(task)
        }
        else -> {}
      }
    }


    if (sameGame) {
      _uiState.value = _uiState.value.copy(downloadTask = task, downloadState = event.downloadState)
    }
  }

}

data class GameDetailUIState(
  val currentGame: Game? = null,
  val downloadTask: DownloadTask? = null,
  @DownloadState val downloadState: Int = DOWNLOAD_STATE_UNKNOWN,
  val showDlg: Boolean = false,
  val loading: Boolean = false,
  val error: String? = null,
)

val handler: Handler = Handler(Looper.getMainLooper())

val coroutineExceptionHandler = CoroutineExceptionHandler { _, throwable ->
  throwable.printStackTrace()
  Timber.e("""Oops 出错了${throwable.printStackTrace()}""")

  handler.post {
    toastAndLog(throwable.message)
  }
}