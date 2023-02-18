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
package com.actduck.videogame.data.source

import com.actduck.videogame.data.DuckAccount
import com.actduck.videogame.data.Game
import com.actduck.videogame.data.GameType
import com.actduck.videogame.data.Page
import com.actduck.videogame.data.source.local.DbService
import com.actduck.videogame.data.source.remote.ApiService
import com.google.android.gms.auth.api.signin.GoogleSignInAccount
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers

/**
 * Default implementation of [DataSource]. Single entry point for managing Games' data.
 */
class RepositoryImpl(
  private val api: ApiService,
  private val db: DbService,
  private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO
) : Repository {

  override suspend fun getGameType(forceUpdate: Boolean): List<GameType> {
    if (forceUpdate) {
      api.gameType().forEach {
        db.saveGameType(it)
      }
    }
    return db.gameType()
  }

  override suspend fun getGamesByGameType(
    page: Int,
    gameTypeId: Long,
    forceUpdate: Boolean
  ): Page<Game> {
      return Page(
        content = emptyList(),
        totalPages = 0,
        totalElements = 0,
        empty = true,
        last = true,
        number = 0,
        first = true,
        size = 0
      )

  }

  override suspend fun getFavoriteGames(): List<Game> {
    return db.getFavoriteGames()
  }

  override suspend fun getGame(gameId: Long, forceUpdate: Boolean): Game? {
    return db.getGame(gameId)
  }

  override suspend fun saveGame(game: Game) {
    db.insertOrUpdateGame(game)
  }

  override suspend fun getUserInfo(googleAccount: GoogleSignInAccount): DuckAccount {
    val userInfo = api.userInfo(
      googleAccount.displayName,
      googleAccount.email,
      googleId = googleAccount.id,
      photoUrl = googleAccount.photoUrl.toString()
    )
    return userInfo
  }

  override suspend fun searchGame(query: String): List<Game> {
    return api.searchGame(query, 1).content
  }

  override suspend fun recentGames(): List<Game> {
   return db.recentGames()
  }
}
