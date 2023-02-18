/*
 * Copyright (C) 2019 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.actduck.videogame.data.source.local

import com.actduck.videogame.data.Game
import com.actduck.videogame.data.GameType
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.*

/**
 * Concrete implementation of a data source as a db.
 */
class DbService internal constructor(
  private val gamesDao: GamesDao,
  private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO
) {

  suspend fun gameType(): List<GameType> {
    return gamesDao.getGameTypes()
  }

  suspend fun saveGameType(gameType: GameType) {
    gamesDao.insertGameType(gameType)
  }

  suspend fun gameList(page: Int, typeId: Long): List<Game> {
    return gamesDao.getGamesByGameType(page - 1, typeId)
  }

  suspend fun gameCount(typeId: Long): Int {
    return gamesDao.getGamesCountByGameType(typeId)
  }

  suspend fun getGame(gameId: Long): Game? {
    return gamesDao.getGameById(gameId)
  }

  suspend fun insertOrUpdateGame(game: Game): Unit = withContext(ioDispatcher) {
//    Timber.d("insertOrUpdateGame 开始 ${game.name}")
    val dbGame = getGame(game.id)
    if (dbGame != null) {
      if (game.romLocalPath == null && dbGame.romLocalPath != null) {
        game.romLocalPath = dbGame.romLocalPath
      }
      if (game.favorite == null) {
        game.favorite = dbGame.favorite
        game.updateTime = Date()
      }
      if (game.lastPlayTime == null && dbGame.lastPlayTime != null) {
        game.lastPlayTime = dbGame.lastPlayTime
      }
      gamesDao.updateGame(game)
    } else {
      gamesDao.insertGame(game)
    }
//    Timber.d("insertOrUpdateGame 最终是 $game")
  }

  suspend fun getFavoriteGames(): List<Game> {
    return gamesDao.getFavoriteGames()
  }

  suspend fun recentGames(): List<Game> {
    return gamesDao.getRecentGames()
  }
}
