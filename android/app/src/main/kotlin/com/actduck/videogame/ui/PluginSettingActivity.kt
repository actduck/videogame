package com.actduck.videogame.ui

import android.os.Bundle
import android.widget.LinearLayout
import androidx.appcompat.app.AppCompatActivity
import com.actduck.videogame.R
import com.actduck.videogame.R.layout
import com.actduck.videogame.R.string
import com.actduck.videogame.util.MySplitManager
import com.actduck.videogame.util.ToastUtil
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class PluginSettingActivity : AppCompatActivity() {

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    setContentView(layout.activity_plugin_setting)
    title = "Plugin " + getString(string.menuItem_settings)

    val gameTypeStr =
      (intent.extras?.get("gameTypeStr") as String).replace("GC ", "").replace("Wii", "GC/Wii").trim()
    val gtArray = gameTypeStr.split(" ")
    val llRoot = findViewById<LinearLayout>(R.id.ll_root)

    if (gameTypeStr.isEmpty() || gtArray.isEmpty()){
      ToastUtil.toastAndLog(resources.getString(R.string.plugin_empty))
      finish()
      return
    }

    gtArray.forEach {
      val data = PluginData()
      data.name = it
      data.installed = MySplitManager.isModuleAdded(it)

      val itemView = PluginSettingItem(this)
      itemView.setData(data)
      llRoot.addView(itemView)
    }
  }

  class PluginData {
    var name: String = ""
    var installed: Boolean = false
    var size: String = ""
  }
}