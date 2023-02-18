package com.actduck.videogame.data

import androidx.room.*
import java.io.Serializable
import java.util.*

@Entity(tableName = "Games")
@SuppressWarnings(RoomWarnings.PRIMARY_KEY_FROM_EMBEDDED_IS_DROPPED)
data class Game @Ignore constructor(
  @PrimaryKey var id: Long = 0,
  var createTime: Date? = null,
  var updateTime: Date? = null,
  var name: String = "",
  var photo: String = "",
  var summary: String = "",
  var size: String = "",
  var url: String? = null,
  @Embedded(prefix = "game_type_") var gameType: GameType? = null,
  @Embedded(prefix = "game_genre_") var gameGenre: GameGenre? = null,
  var starCount: Int = 0,
  var enable: Boolean = true,

  var heat: Int = 0,// 热度
  var romLocalPath: String? = null,// 游戏本地目录
  var favorite: Boolean? = null,
  var localGame: Boolean? = null,
  var lastPlayTime :Long? = null,
  var zipUrl: String? = null,
  // var splitCount: Int = 0,
  @Ignore
  var isUnziping :Boolean? = false // 是否正在解压

//  @Ignore
//  var downloadTask: DownloadTask? = null
) : Serializable {

  constructor() : this(
    0,
    null,
    null,
    "",
    "",
    "",
    "",
    "",
    null,
    null,
    0,
    true,
    0,
    null,
    null,
    null
  )

  override fun toString(): String {
    return name +favorite
  }
}