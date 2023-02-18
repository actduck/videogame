package com.actduck.videogame.data.source

import com.actduck.videogame.data.DuckAccount
import com.actduck.videogame.data.Game
import com.actduck.videogame.data.GameType
import com.actduck.videogame.data.Page
import com.google.android.gms.auth.api.signin.GoogleSignInAccount

interface Repository {

    suspend fun getGameType(forceUpdate: Boolean) : List<GameType>

    suspend fun getGamesByGameType(page: Int, gameTypeId: Long, forceUpdate: Boolean = false): Page<Game>

    suspend fun getFavoriteGames(): List<Game>

    suspend fun getGame(gameId: Long, forceUpdate: Boolean = false): Game?

    suspend fun saveGame(game: Game)

    suspend fun getUserInfo(googleAccount: GoogleSignInAccount): DuckAccount

    suspend fun searchGame(query: String): List<Game>

    suspend fun recentGames() : List<Game>

}