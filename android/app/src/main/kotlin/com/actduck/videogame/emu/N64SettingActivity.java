package com.actduck.videogame.emu;

import android.os.Bundle;
import android.view.View;
import android.widget.ListView;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import com.actduck.videogame.R;
import paulscode.android.mupen64plusae.ActivityHelper;

public class N64SettingActivity extends AppCompatActivity {

  @Override protected void onCreate(@Nullable Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_n64_setting);
    setTitle("N64 " + getString(R.string.menuItem_settings));
  }

  public void onDisplayClick(View view) {
    ActivityHelper.startDisplayPrefsActivity(this);
  }

  public void onShadersClick(View view) {
    ActivityHelper.startShadersPrefsActivity(this);
  }

  public void onAudioClick(View view) {
    ActivityHelper.startAudioPrefsActivity(this);
  }

  public void onTouchscreenClick(View view) {
    ActivityHelper.startTouchscreenPrefsActivity(this);
  }

  public void onInputClick(View view) {
    ActivityHelper.startInputPrefsActivity(this);
  }

  public void onSelectProfileClick(View view) {
    ActivityHelper.startDefaultPrefsActivity( this );
  }

  public void onProfileEmulatorClick(View view) {
    ActivityHelper.startManageEmulationProfilesActivity(this);
  }

  public void onProfileTouchscreenClick(View view) {
    ActivityHelper.startManageTouchscreenProfilesActivity(this);
  }

  public void onProfileControllerClick(View view) {
    ActivityHelper.startManageControllerProfilesActivity(this);
  }
}
