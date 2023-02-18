package com.actduck.videogame.data

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.io.Serializable

@Entity
class GameType(
  @PrimaryKey var id: Long = 0,
  var name: String,
  var photo: String = ""
) : Serializable {
  override fun equals(other: Any?): Boolean {
    return this.id == (other as GameType).id
  }

  override fun hashCode(): Int {
    var result = id.hashCode()
    result = 31 * result + name.hashCode()
    result = 31 * result + photo.hashCode()
    return result
  }
}