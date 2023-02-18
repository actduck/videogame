package com.actduck.videogame.emu;

import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.Window;
import android.widget.ProgressBar;
import androidx.annotation.Nullable;
import androidx.fragment.app.FragmentActivity;
import org.dolphinemu.dolphinemu.activities.EmulationActivity;
import org.dolphinemu.dolphinemu.utils.FileBrowserHelper;
import timber.log.Timber;

public class DolphinActivity extends FragmentActivity {

  @Override
  protected void onCreate(@Nullable @org.jetbrains.annotations.Nullable Bundle savedInstanceState) {
    requestWindowFeature(Window.FEATURE_NO_TITLE);
    super.onCreate(savedInstanceState);
    ProgressBar bar = new ProgressBar(this);
    bar.setBackgroundResource(android.R.color.background_dark);
    setContentView(bar);

    Timber.d("tryOpenGame: 尝试打开游戏");

    Uri data = getIntent().getData();
    FileBrowserHelper.runAfterExtensionCheck(this, data,
        FileBrowserHelper.GAME_LIKE_EXTENSIONS,
        () -> EmulationActivity.launch(this, data.toString(), false));

    new Handler(Looper.myLooper()).postDelayed(new Runnable() {
      @Override public void run() {
        finish();
      }
    }, 5000);
  }

  @Override protected void onDestroy() {
    super.onDestroy();
    Timber.d("onDestroy: 要关闭了");
  }
}
