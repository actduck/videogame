package com.actduck.videogame.data

import androidx.room.Entity
import androidx.room.PrimaryKey
// import com.actduck.libad.DuckAds.AdFormat
import java.io.Serializable
import java.util.Date

@Entity
class AdAnalytics(
  @PrimaryKey var id: Long? = null,
  var userId: Long? = null,
  var userPseudoId: String? = null,
  var userIP: String? = null,
  var adFormat: Int? = null,
  var event: Int? = null, // 显示还是点击 1 显示 2 点击
  var date: Date? = null,
  var uploaded: Boolean = false // 已上传服务器
) : Serializable {

}

//{ "clickTimes": 3, "enable": true, "interval": 60000 }
data class AdsConfig(
  val clickTimes: Int,
  val enable: Boolean,
  val interval: Long
)