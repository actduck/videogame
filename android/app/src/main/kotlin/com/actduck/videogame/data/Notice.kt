package com.actduck.videogame.data

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.io.Serializable

@Entity
class Notice : Serializable {
  @PrimaryKey var id: Long = 0
  var title = ""
  var content = ""
}