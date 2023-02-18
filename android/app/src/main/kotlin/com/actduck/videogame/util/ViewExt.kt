/*
 * Copyright (C) 2019 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.actduck.videogame.util

/**
 * Extension functions and Binding Adapters.
 */

import android.view.View
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import com.actduck.videogame.R
import com.actduck.videogame.ScrollChildSwipeRefreshLayout
import com.google.common.reflect.TypeToken
import com.google.gson.Gson
import com.google.gson.GsonBuilder

fun Fragment.setupRefreshLayout(
    refreshLayout: ScrollChildSwipeRefreshLayout,
    scrollUpChild: View? = null
) {
    refreshLayout.setColorSchemeColors(
        ContextCompat.getColor(requireActivity(), R.color.colorPrimary),
        ContextCompat.getColor(requireActivity(), R.color.colorAccent),
        ContextCompat.getColor(requireActivity(), R.color.colorPrimaryDark)
    )
    // Set the scrolling view in the custom SwipeRefreshLayout.
    scrollUpChild?.let {
        refreshLayout.scrollUpChild = it
    }
}

var gson: Gson = GsonBuilder().setDateFormat("yyyy-MM-dd HH:mm:ss.000").create()

//convert a data class to a map
fun <T> T.serializeToMap(): Map<String, Any> {
    return convert()
}

//convert a map to a data class
inline fun <reified T> Map<String, Any>.toDataClass(): T {
    return convert()
}

//convert an object of type I to type O
inline fun <I, reified O> I.convert(): O {
    val json = gson.toJson(this)
    return gson.fromJson(json, object : TypeToken<O>() {}.type)
}

//convert a data class to a map
fun <T> T.covertToJson(): String {
    return gson.toJson(this)
}

//convert a data class to a map
inline fun <reified T> String.covertToData(): T  {
    return gson.fromJson(this, object : TypeToken<T>() {}.type)
}

inline fun <reified T> String.toDataClass(): T {
    return gson.fromJson(this, object : TypeToken<T>() {}.type)
}
// fun toastAndLog(message: String?) {
//     Timber.d(message)
//
//     if (MySplitManager.mToast == null) {
//         MySplitManager.mToast = Toast.makeText(MyApp.instance, message, Toast.LENGTH_SHORT)
//     } else {
//         val view: View? = MySplitManager.mToast?.view
//         MySplitManager.mToast?.cancel()
//         MySplitManager.mToast = Toast(MyApp.instance)
//         MySplitManager.mToast?.view = view
//         MySplitManager.mToast?.duration = Toast.LENGTH_SHORT
//         MySplitManager.mToast?.setText(message)
//     }
//     MySplitManager.mToast?.show()
// }