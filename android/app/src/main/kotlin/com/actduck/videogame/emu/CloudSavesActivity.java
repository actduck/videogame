package com.actduck.videogame.emu;

import android.os.Bundle;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import com.actduck.videogame.R;
import dagger.hilt.android.AndroidEntryPoint;

@AndroidEntryPoint
public class CloudSavesActivity extends AppCompatActivity {

  @Override protected void onCreate(@Nullable Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_cloud_saves);
  }
}
