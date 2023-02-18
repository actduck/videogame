package com.actduck.videogame.util

import android.view.View
import android.widget.Toast
import com.actduck.videogame.MyApp
import timber.log.Timber

object ToastUtil {

    var mToast: Toast? = null

    fun toastAndLog(message: String? = "") {
        Timber.d(message)

        if (mToast == null) {
            mToast = Toast.makeText(MyApp.instance, message, Toast.LENGTH_SHORT)
        } else {
            val view: View? = mToast?.view
            mToast?.cancel()
            mToast = Toast(MyApp.instance)
            mToast?.view = view
            mToast?.duration = Toast.LENGTH_SHORT
            mToast?.setText(message)
        }
        mToast?.show()
    }

}