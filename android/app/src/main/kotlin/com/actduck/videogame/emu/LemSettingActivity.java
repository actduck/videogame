package com.actduck.videogame.emu;

import android.os.Bundle;
import android.view.View;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import com.actduck.videogame.R;
import dagger.hilt.android.AndroidEntryPoint;
import paulscode.android.mupen64plusae.ActivityHelper;

@AndroidEntryPoint
public class LemSettingActivity extends AppCompatActivity {

  @Override protected void onCreate(@Nullable Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_lem_settings);
    setTitle("3DS/PSX/PSP " + getString(R.string.menuItem_settings));

  }
}
