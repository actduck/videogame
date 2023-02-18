package com.actduck.videogame.emu;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.ParcelFileDescriptor;
import android.text.TextUtils;
import android.util.Log;
import android.view.Window;
import android.widget.ProgressBar;
import androidx.annotation.Nullable;
import androidx.documentfile.provider.DocumentFile;
import com.actduck.videogame.util.MySplitManager;
import com.google.android.play.core.splitcompat.SplitCompat;
import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.util.Date;
import paulscode.android.mupen64plusae.ActivityHelper;
import paulscode.android.mupen64plusae.SplashActivity;
import paulscode.android.mupen64plusae.game.GameActivity;
import paulscode.android.mupen64plusae.persistent.AppData;
import paulscode.android.mupen64plusae.persistent.ConfigFile;
import paulscode.android.mupen64plusae.persistent.GlobalPrefs;
import paulscode.android.mupen64plusae.task.ExtractAssetsOrCleanupTask;
import paulscode.android.mupen64plusae.util.FileUtil;
import paulscode.android.mupen64plusae.util.Notifier;
import paulscode.android.mupen64plusae.util.RomDatabase;
import paulscode.android.mupen64plusae.util.RomHeader;
import timber.log.Timber;

public class N64Activity extends SplashActivity {
  private static final String TAG = "N64Activity";

  // App data and user preferences
  private AppData mAppData = null;
  private GlobalPrefs mGlobalPrefs = null;
  private ConfigFile mConfig;
  public static final String SOURCE_DIR = "mupen64plus_data";
  private boolean installOk;
  boolean isOpenIngGame = false;

  private boolean netplay;
  private boolean server;

  @Override
  protected void attachBaseContext(Context base) {
    super.attachBaseContext(base);
    // Emulates installation of on demand modules using SplitCompat.
    SplitCompat.installActivity(this);
  }


  @Override
  public void onCreate(@Nullable @org.jetbrains.annotations.Nullable Bundle savedInstanceState) {
    supportRequestWindowFeature(Window.FEATURE_NO_TITLE);
    super.onCreate(savedInstanceState);

    if (MySplitManager.INSTANCE.isModuleAdded("N64")) {
      MySoLoader.INSTANCE.loadN64So();
    }

    tryOpenGame();
  }

  @Override public void onAssetsOk() {
    Timber.d("onAssetsOk: n64安装成功, 打开游戏");
    installOk = true;
    tryOpenGame();
  }

  private void tryOpenGame() {

    mAppData = new AppData(this);
    mGlobalPrefs = new GlobalPrefs(this, mAppData);
    mConfig = new ConfigFile(mGlobalPrefs.romInfoCacheCfg);

    ProgressBar bar = new ProgressBar(this);
    bar.setBackgroundResource(android.R.color.background_dark);
    setContentView(bar);

    new Thread(() -> {
      Timber.d("tryOpenGame: 尝试打开游戏");
      if (installOk) {
        openGame();
      } else {
        Timber.e("onCreate: N64 安装错误");
      }
    }).start();

    new Handler(Looper.myLooper()).postDelayed(new Runnable() {
      @Override public void run() {
        finish();
      }
    }, 5000);
  }

  private synchronized void openGame() {
    if (isOpenIngGame) {
      Timber.d("openGame 正在打开游戏，返回");
      return;
    }
    Uri data = getIntent().getData();

    netplay = getIntent().getBooleanExtra("netplay", false);
    server = getIntent().getBooleanExtra("server", false);

    final String givenRomPath = data.toString();

    if (!TextUtils.isEmpty(givenRomPath)) {
      getIntent().replaceExtras((Bundle) null);
      isOpenIngGame = true;

      try {
        launchGameOnCreation(givenRomPath);
      } catch (Exception e) {
        e.printStackTrace();
        runOnUiThread(() -> Notifier.showToast(getApplicationContext(),
            org.mupen64plusae.v3.alpha.R.string.toast_nativeMainFailure07));
        finish();
      }
    }
  }

  /**
   * 打开游戏的方法
   */
  private void launchGameOnCreation(String givenRomPath) {
    if (givenRomPath == null) {
      return;
    }

    Log.i(TAG, "Rom path = " + givenRomPath);

    boolean isUri;

    isUri = !new File(givenRomPath).exists();

    //mGameStartedExternally = true;

    Uri romPathUri;

    if (isUri) {
      romPathUri = Uri.parse(givenRomPath);
    } else {
      romPathUri = Uri.fromFile(new File(givenRomPath));
    }

    RomHeader header = new RomHeader(this, romPathUri);

    boolean successful = false;
    String romPath;
    String unzippedRomDir = getCacheDir().getAbsolutePath() + "/UnzippedRoms";
    if (header.isZip) {
      romPath = FileUtil.ExtractFirstROMFromZip(this, romPathUri, unzippedRomDir);

      if (romPath != null) {
        romPathUri = Uri.fromFile(new File(romPath));
        header = new RomHeader(this, romPathUri);
      }
    } else if (header.is7Zip && AppData.IS_NOUGAT) {
      romPath = FileUtil.ExtractFirstROMFromSevenZ(this, romPathUri, unzippedRomDir);

      if (romPath != null) {
        romPathUri = Uri.fromFile(new File(romPath));
        header = new RomHeader(this, romPathUri);
      }
    }

    if (header.isValid) {
      // Synchronously compute MD5 and launch game when finished
      String computedMd5 = null;
      try (ParcelFileDescriptor parcelFileDescriptor = getApplicationContext().getContentResolver()
          .openFileDescriptor(romPathUri, "r")) {

        if (parcelFileDescriptor != null) {
          InputStream bufferedStream = new BufferedInputStream(
              new FileInputStream(parcelFileDescriptor.getFileDescriptor()));
          computedMd5 = FileUtil.computeMd5(bufferedStream);
        }
      } catch (Exception | OutOfMemoryError e) {
        e.printStackTrace();
      }

      if (computedMd5 != null) {
        final RomDatabase database = RomDatabase.getInstance();

        if (!database.hasDatabaseFile()) {
          database.setDatabaseFile(mAppData.mupen64plus_ini);
        }

        successful = true;

        DocumentFile romDocFile = FileUtil.getDocumentFileSingle(this, romPathUri);
        final RomDatabase.RomDetail detail = database.lookupByMd5WithFallback(computedMd5,
            romDocFile == null ? "" : romDocFile.getName(), header.crc, header.countryCode);
        String artPath = mGlobalPrefs.coverArtDir + "/" + detail.artName;
        launchGameActivity(romPathUri.toString(), null, computedMd5, header.crc, header.name,
            header.countryCode.getValue(), artPath, detail.goodName, detail.goodName, false,
            netplay, server);
      }
    }

    if (!successful) {
      runOnUiThread(() -> Notifier.showToast(getApplicationContext(),
          org.mupen64plusae.v3.alpha.R.string.toast_nativeMainFailure07));
    }
  }

  public void launchGameActivity(String romPath, String zipPath, String romMd5, String romCrc,
      String romHeaderName, byte romCountryCode, String romArtPath, String romGoodName,
      String romDisplayName,
      boolean isRestarting,
      boolean isNetplayEnabled, boolean isNetplayServer) {
    Log.i(TAG, "launchGameActivity");

    // Make sure that the storage is accessible
    if (!ExtractAssetsOrCleanupTask.areAllAssetsPresent(SOURCE_DIR, mAppData.coreSharedDataDir)) {
      Log.e(TAG, "SD Card not accessible");
      Notifier.showToast(this, org.mupen64plusae.v3.alpha.R.string.toast_sdInaccessible);

      mAppData.putAssetCheckNeeded(true);
      ActivityHelper.startSplashActivity(this);
      finishAffinity();
      //return;
    }

    // Update the ConfigSection with the new value for lastPlayed
    final String lastPlayed = Integer.toString((int) (new Date().getTime() / 1000));

    mConfig.put(romMd5, "lastPlayed", lastPlayed);
    mConfig.save();

    // Launch the game activity
    //ActivityHelper.startGameActivity(this, romPath, zipPath, romMd5, romCrc, romHeaderName,
    //    romCountryCode,
    //    romArtPath, romGoodName, romDisplayName, isRestarting);

    startGameActivity(romPath, zipPath, romMd5, romCrc, romHeaderName,
        romCountryCode,
        romArtPath, romGoodName, romDisplayName, isRestarting,isNetplayEnabled,isNetplayServer);
  }

  void startGameActivity(String romPath, String zipPath, String romMd5, String romCrc,
      String romHeaderName, byte romCountryCode, String romArtPath, String romGoodName, String romDisplayName,
      boolean doRestart, boolean isNetplayEnabled, boolean isNetplayServer) {
    Intent intent = new Intent(this, GameActivity.class);
    intent.putExtra( ActivityHelper.Keys.ROM_PATH, romPath );
    intent.putExtra( ActivityHelper.Keys.ZIP_PATH, zipPath );
    intent.putExtra( ActivityHelper.Keys.ROM_MD5, romMd5 );
    intent.putExtra( ActivityHelper.Keys.ROM_CRC, romCrc );
    intent.putExtra( ActivityHelper.Keys.ROM_HEADER_NAME, romHeaderName );
    intent.putExtra( ActivityHelper.Keys.ROM_COUNTRY_CODE, romCountryCode );
    intent.putExtra( ActivityHelper.Keys.ROM_ART_PATH, romArtPath );
    intent.putExtra( ActivityHelper.Keys.ROM_GOOD_NAME, romGoodName );
    intent.putExtra( ActivityHelper.Keys.ROM_DISPLAY_NAME, romDisplayName );
    intent.putExtra( ActivityHelper.Keys.DO_RESTART, doRestart );
    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
    intent.putExtra( ActivityHelper.Keys.NETPLAY_ENABLED, isNetplayEnabled );
    intent.putExtra( ActivityHelper.Keys.NETPLAY_SERVER, isNetplayServer );
    startActivity(intent);
  }

  @Override public void onDestroy() {
    super.onDestroy();
    Timber.d("onDestroy: 要关闭了");
  }
}
