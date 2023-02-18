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

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.actduck.videogame.data.DateConverter
import com.actduck.videogame.data.Game
import com.actduck.videogame.data.GameGenre
import com.actduck.videogame.data.GameType

/**
 * The Room Database that contains the Game table.
 *
 * Note that exportSchema should be true in production databases.
 */
@Database(
  entities = [Game::class, GameGenre::class, GameType::class],
  version = 1,
  exportSchema = false
)
@TypeConverters(value = [DateConverter::class])
abstract class AppDb : RoomDatabase() {

  abstract fun gameDao(): GamesDao
}

// object MIGRATION_1_2 : Migration(1, 2) {
//   override fun migrate(database: SupportSQLiteDatabase) {
//     database.execSQL(
//       """
//                 ALTER TABLE Games ADD splitCount INTEGER NOT NULL DEFAULT 0;
//                 """
//     )
//
//   }
// }
