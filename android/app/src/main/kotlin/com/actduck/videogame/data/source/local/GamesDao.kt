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

import androidx.lifecycle.LiveData
import androidx.room.*
import com.actduck.videogame.data.Game
import com.actduck.videogame.data.GameType

/**
 * Data Access Object for the Games table.
 */
@Dao
interface GamesDao {

  @Query("SELECT * FROM Games")
  fun observeGames(): LiveData<List<Game>>

  @Query("SELECT * FROM Games WHERE id = :gameId")
  fun observeGameById(gameId: String): LiveData<Game>

  @Query("SELECT * FROM Games")
  suspend fun getGames(): List<Game>

  @Query("SELECT * FROM Games WHERE game_type_id = :typeId ORDER BY starCount desc LIMIT 20 OFFSET :page * 20")
  suspend fun getGamesByGameType(page: Int, typeId: Long): List<Game>

  @Query("SELECT COUNT(*) FROM Games WHERE game_type_id = :typeId")
  suspend fun getGamesCountByGameType(typeId: Long): Int

  @Query("SELECT * FROM GameType")
  suspend fun getGameTypes(): List<GameType>

  @Query("SELECT * FROM Games WHERE id = :gameId")
  suspend fun getGameById(gameId: Long): Game?

  @Insert(onConflict = OnConflictStrategy.REPLACE)
  suspend fun insertGame(game: Game)

  @Insert(onConflict = OnConflictStrategy.REPLACE)
  suspend fun insertGameType(gameType: GameType)

  @Update
  suspend fun updateGame(game: Game): Int

  @Query("SELECT * FROM Games WHERE favorite = 1 ORDER BY updateTime desc")
  suspend fun getFavoriteGames(): List<Game>

  @Query("SELECT * FROM Games WHERE lastPlayTime IS NOT NULL ORDER BY lastPlayTime desc")
  suspend fun getRecentGames(): List<Game>

//    /**
//     * Update the complete status of a game
//     *
//     * @param gameId id of the game
//     * @param completed status to be updated
//     */
//    @Query("UPDATE Games SET completed = :completed WHERE entryid = :gameId")
//    suspend fun updateCompleted(gameId: String, completed: Boolean)

  @Query("DELETE FROM Games WHERE id = :gameId")
  suspend fun deleteGameById(gameId: String): Int

  @Query("DELETE FROM Games")
  suspend fun deleteGames()
//
//    /**
//     * Delete all completed Games from the table.
//     *
//     * @return the number of Games deleted.
//     */
//    @Query("DELETE FROM Games WHERE completed = 1")
//    suspend fun deleteCompletedGames(): Int
}
