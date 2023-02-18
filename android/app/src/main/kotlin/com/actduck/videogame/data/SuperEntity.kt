package com.actduck.videogame.data

import androidx.room.Ignore
import androidx.room.PrimaryKey
import androidx.room.TypeConverters
import java.io.Serializable
import java.util.Date

/**
 * Base Entity
 *
 * @author cem ikta
 */
abstract class SuperEntity(
  var id: Long? = null,
  var createTime: Date? = null,
  var updateTime: Date? = null
) : Serializable