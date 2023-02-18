package com.actduck.videogame.ui

import android.os.Bundle
import android.view.View
import android.widget.Button
import android.widget.TextView
import androidx.activity.viewModels
import com.actduck.videogame.R
import com.actduck.videogame.R.id
import com.actduck.videogame.R.layout
import com.google.firebase.analytics.ktx.analytics
import com.google.firebase.analytics.ktx.logEvent
import com.google.firebase.ktx.Firebase
import dagger.hilt.android.AndroidEntryPoint
import paulscode.android.mupen64plusae.ScanRomsActivity

@AndroidEntryPoint
class MyScanRomsActivity : ScanRomsActivity() {

  val viewModel by viewModels<MyScanRomsViewModel>()

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    setContentView(layout.my_scan_roms_activity)
    val folderPickerButton = findViewById<Button>(id.buttonFolderPicker)
    folderPickerButton.setOnClickListener { v: View? -> startFolderPicker() }
    val filePickerButton = findViewById<Button>(id.buttonFilePicker)
    filePickerButton.setOnClickListener { v: View? -> startFilePicker() }

    val text = findViewById<TextView>(id.text1)
    text.text = String.format(getString(R.string.my_scanRomsDialog_selectRom), "NES, SNES, MD, GB, GBC, GBA, N64, MAME, GC, Wii, NDS, PSP, PSX, 3DS")



    val extras = intent.extras
    val isFolder = extras?.get("isFolder")
    if (isFolder == true){
      startFolderPicker()
    }
  }

  override fun startFilePicker() {
    super.startFilePicker()
    Firebase.analytics.logEvent("click_file_picker"){}
  }

  override fun startFolderPicker() {
    super.startFolderPicker()

    Firebase.analytics.logEvent("click_folder_picker"){}
  }
}