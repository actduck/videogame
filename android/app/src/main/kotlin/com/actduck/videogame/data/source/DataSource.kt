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

import androidx.lifecycle.LiveData
import com.actduck.videogame.data.ApiResponse
import com.actduck.videogame.data.Game

/**
 * Interface to the data layer.
 */
interface DataSource {

    fun observeGames(): LiveData<ApiResponse<List<Game>>>

    suspend fun getGames(): ApiResponse<List<Game>>

    fun observeGame(gameId: String): LiveData<ApiResponse<Game>>

    suspend fun getGame(gameId: String, forceUpdate: Boolean = false): ApiResponse<Game>

    suspend fun refreshGames()

    suspend fun refreshGame(gameId: String)

    suspend fun saveGame(game: Game)
//
//    suspend fun completeGame(game: Game)
//
//    suspend fun completeGame(gameId: String)
//
//    suspend fun activateGame(game: Game)
//
//    suspend fun activateGame(gameId: String)
//
//    suspend fun clearCompletedGames()
//
    suspend fun deleteAllGames()
//
    suspend fun deleteGame(gameId: String)
}
