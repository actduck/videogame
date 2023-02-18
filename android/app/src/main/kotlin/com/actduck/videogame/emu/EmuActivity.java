package com.actduck.videogame.emu;

import android.content.Context;
import com.google.android.play.core.splitcompat.SplitCompat;
import com.imagine.BaseActivity;
import timber.log.Timber;

public class EmuActivity extends BaseActivity {

  @Override
  protected void attachBaseContext(Context base) {
    super.attachBaseContext(base);
    // Emulates installation of on demand modules using SplitCompat.
    SplitCompat.installActivity(this);
  }
  @Override protected void onDestroy() {
    super.onDestroy();
    Timber.d("onDestroy: 要关闭了");
    android.os.Process.killProcess(android.os.Process.myPid());
  }
}
