package com.actduck.videogame.emu;

import android.app.AlertDialog;
import android.app.Service;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.os.Handler;
import android.view.WindowManager;
import android.view.inputmethod.InputMethodManager;
import android.widget.EditText;
import android.widget.Toast;
import com.seleuco.mame4droid.Emulator;
import com.seleuco.mame4droid.MAME4droid;
import com.seleuco.mame4droid.helpers.DialogHelper;
import com.seleuco.mame4droid.helpers.MainHelper;
import com.seleuco.mame4droid.helpers.PrefsHelper;
import dalvik.system.BaseDexClassLoader;

import static com.seleuco.mame4droid.helpers.DialogHelper.DIALOG_NONE;

public class MAMEActivity extends MAME4droid {

  private boolean isNetplay;
  private boolean isServer;

  @Override public void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);

    isNetplay = getIntent().getBooleanExtra("netplay", false);
    isServer = getIntent().getBooleanExtra("server", false);
    netPlay = new MyNetPlay(this);


    new Handler().postDelayed(new Runnable() {
      @Override public void run() {
        if (isNetplay) {
          getNetPlay().createDialog();
          ((MyNetPlay) netPlay).getNetplayDlg().hide();

          if (isServer) {
            // 1p
            getNetPlay().createGame();
          } else {
            // 2p
            onJoinClick();
          }
        }
      }
    }, 2000);
  }

  private void onJoinClick() {
    AlertDialog.Builder alert = new AlertDialog.Builder(this);

    alert.setTitle("Enter peer IP Address:");
    //alert.setMessage("Enter peer IP address:");

    final EditText input = new EditText(this);
    alert.setView(input);

    String ip =
        getPrefsHelper().getSharedPreferences().getString(PrefsHelper.PREF_NETPLAY_PEERADDR, "");

    input.setText(ip);
    input.setSelection(input.getText().length());

    alert.setPositiveButton("Ok", new DialogInterface.OnClickListener() {
      public void onClick(DialogInterface dialog, int whichButton) {
        String ip = input.getText().toString();

        if (ip == null || ip.length() == 0) {
          Toast.makeText(MAMEActivity.this, "Invalid peer IP!", Toast.LENGTH_SHORT).show();
          return;
        }

        InputMethodManager imm =
            (InputMethodManager) getSystemService(Service.INPUT_METHOD_SERVICE);
        imm.hideSoftInputFromWindow(input.getWindowToken(), 0);

        SharedPreferences sp = getPrefsHelper().getSharedPreferences();
        SharedPreferences.Editor edit = sp.edit();
        edit.putString(PrefsHelper.PREF_NETPLAY_PEERADDR, ip);
        edit.commit();

        getNetPlay().joinGame(ip);
      }
    });

    alert.setNegativeButton("Cancel", new DialogInterface.OnClickListener() {
      public void onClick(DialogInterface dialog, int whichButton) {
        // Canceled.
      }
    });

    AlertDialog dlg = alert.create();
    dlg.getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_STATE_HIDDEN);
    dlg.show();
  }

  @Override public void runMAME4droid() {
    mainHelper.copyFiles();
    mainHelper.removeFiles();
    BaseDexClassLoader classLoader = (BaseDexClassLoader) getClassLoader();
    String path = classLoader.findLibrary("MAME4droid");
    Emulator.emulate(path, this.mainHelper.getInstallationDIR());
  }

  @Override protected void initMame4droid() {
    if (!Emulator.isEmulating()) {
      if (prefsHelper.getROMsDIR() == null) {
        if (DialogHelper.savedDialog == DIALOG_NONE) {
          getMainHelper().setInstallationDirType(MainHelper.INSTALLATION_DIR_NEW);
          if (getMainHelper().ensureInstallationDIR(getMainHelper().getInstallationDIR())) {
            getPrefsHelper().setROMsDIR("");
            runMAME4droid();
          }
        }
      } else {
        if (getPrefsHelper().getInstallationDIR() != null && !getPrefsHelper().getInstallationDIR()
            .equals(getPrefsHelper().getOldInstallationDIR())) {
          if (!CheckPermissions()) {
            return;
          }
        }
        boolean res = getMainHelper().ensureInstallationDIR(mainHelper.getInstallationDIR());
        if (res == false) {
          this.getPrefsHelper().setInstallationDIR(this.getPrefsHelper().getOldInstallationDIR());
        } else {
          runMAME4droid();
        }
      }
      if (getIntent().getAction() == Intent.ACTION_VIEW) {
        if (!CheckPermissions()) {
          return;
        }
      }
    }
  }

  @Override public Boolean CheckPermissions() {
    return false;
  }
}

