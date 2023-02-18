package com.actduck.videogame.ui

import android.content.Context
import android.content.Intent
import android.util.AttributeSet
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.core.content.ContextCompat.startActivity
import com.actduck.videogame.R
import com.actduck.videogame.R.layout
import com.actduck.videogame.data.ModuleInstallEvent
import com.actduck.videogame.emu.LemSettingActivity
import com.actduck.videogame.emu.N64SettingActivity
import com.actduck.videogame.ui.PluginSettingActivity.PluginData
import com.actduck.videogame.util.MySplitManager

import com.seleuco.mame4droid.prefs.UserPreferences
import org.dolphinemu.dolphinemu.features.settings.ui.MenuTag
import org.dolphinemu.dolphinemu.features.settings.ui.SettingsActivity
import org.greenrobot.eventbus.EventBus
import org.greenrobot.eventbus.Subscribe
import org.greenrobot.eventbus.ThreadMode.MAIN

class PluginSettingItem @JvmOverloads constructor(
  context: Context?,
  attrs: AttributeSet? = null
) : LinearLayout(context, attrs) {
  var tvName: TextView
  var ivAdd: ImageView
  var ivRemove: ImageView
  var ivSetting: ImageView
  var ivPlugin: ImageView

  var pluginData: PluginData? = null

  var pluginPic = mapOf(
    "MAME" to R.drawable.game_system_arcade,
    "NES" to R.drawable.game_system_nes,
    "SNES" to R.drawable.game_system_snes,
    "GBA" to R.drawable.game_system_gba,
    "GBC" to R.drawable.game_system_gbc,
    "MD" to R.drawable.game_system_sms,
    "NEO" to R.drawable.game_system_arcade,
    "SWAN" to R.drawable.game_system_ws,
    "GC/Wii" to R.drawable.game_system_wii,
    "N64" to R.drawable.game_system_n64,
    "NDS" to R.drawable.game_system_ds,
    "PSX" to R.drawable.game_system_psx,
    "PSP" to R.drawable.game_system_psp,
    "3DS" to R.drawable.game_system_3ds
  )

  init {
    inflate(context, layout.item_plugin_setting, this)
    tvName = findViewById(R.id.tv_plugin_name)
    ivAdd = findViewById(R.id.iv_plugin_add)
    ivRemove = findViewById(R.id.iv_plugin_remove)
    ivSetting = findViewById(R.id.iv_plugin_setting)
    ivPlugin = findViewById(R.id.iv_plugin_pic)

    ivAdd.setOnClickListener {
      pluginData?.let {
        MySplitManager.addModule(it.name)
      }
    }
    ivRemove.setOnClickListener {
      pluginData?.let {
        MySplitManager.removeModule(it.name)
      }
    }
    ivSetting.setOnClickListener {
      pluginData?.let {
        go2Setting(it.name)
      }
    }
    EventBus.getDefault().register(this)
  }

  @Subscribe(threadMode = MAIN) fun onDownloadEvent(event: ModuleInstallEvent) {
    pluginData?.let {
      val data = PluginData()
      data.name = it.name
      data.installed = MySplitManager.isModuleAdded(it.name)
      setData(data)
    }

  }

  private fun go2Setting(gameTypeName: String) {
    when (gameTypeName) {
      "GC/Wii", "GC", "Wii" -> {
        SettingsActivity.launch(context, MenuTag.SETTINGS)
      }
      "N64" -> {
        startActivity(context, Intent(context, N64SettingActivity::class.java), null)
      }
      "NDS" -> {
        startActivity(
          context,
          Intent(context, me.magnum.melonds.ui.settings.SettingsActivity::class.java),
          null
        )
      }
      "MAME" -> {
        startActivity(context, Intent(context, UserPreferences::class.java), null)
      }
      "3DS", "PSP", "PSX" -> {
        startActivity(context, Intent(context, LemSettingActivity::class.java), null)
      }
      else -> {
        Toast.makeText(
          context,
          "Please go to the game running Screen to enter the settings",
          Toast.LENGTH_LONG
        ).show()
      }
    }
  }

  fun setData(
    data: PluginData
  ) {
    pluginData = data
    tvName.text = data.name
    val installed = data.installed
    tvName.isEnabled = installed
    ivAdd.visibility = if (installed) GONE else VISIBLE
    ivSetting.visibility = if (installed) VISIBLE else GONE
    ivRemove.visibility = if (installed) VISIBLE else GONE
    ivPlugin.setImageResource(pluginPic[data.name]!!)
  }
}