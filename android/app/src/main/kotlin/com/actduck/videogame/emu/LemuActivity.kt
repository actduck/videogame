package com.actduck.videogame.emu

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.appcompat.app.AppCompatActivity
import com.swordfish.lemuroid.app.shared.game.GameLauncher
import com.swordfish.lemuroid.lib.library.db.entity.Game
import dagger.hilt.android.AndroidEntryPoint
import timber.log.Timber
import javax.inject.Inject

@AndroidEntryPoint
class LemuActivity : AppCompatActivity() {

  @Inject lateinit var gameLauncher: GameLauncher

  var game: Game? = null

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    game = intent.getSerializableExtra("game") as Game?

    game?.let {
      gameLauncher.launchGameAsync(this, it, false, false)
    }
    Timber.d("我的游戏是$game")

    Looper.myLooper()?.let { Handler(it).postDelayed({ finish() }, 5000) }

  }

}