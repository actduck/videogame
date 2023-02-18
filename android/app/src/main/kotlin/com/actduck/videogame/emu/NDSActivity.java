package com.actduck.videogame.emu;

import android.content.Context;
import android.os.Bundle;
import androidx.annotation.Nullable;
import com.actduck.videogame.MyApp;
import com.actduck.videogame.util.MySplitManager;
import com.google.android.play.core.splitcompat.SplitCompat;
import me.magnum.melonds.ui.emulator.EmulatorActivity;

public class NDSActivity extends EmulatorActivity {

  @Override
  protected void attachBaseContext(Context base) {
    super.attachBaseContext(base);
    // Emulates installation of on demand modules using SplitCompat.
    SplitCompat.installActivity(this);
  }

  @Override protected void onCreate(@Nullable Bundle savedInstanceState) {
    if (MySplitManager.INSTANCE.isModuleAdded("NDS")){
      MySoLoader.INSTANCE.loadNDSSo(MyApp.instance);
    }
    super.onCreate(savedInstanceState);
  }
}
