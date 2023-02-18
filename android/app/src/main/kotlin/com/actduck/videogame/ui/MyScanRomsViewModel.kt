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
package com.actduck.videogame.ui

import android.content.Context
import android.net.Uri
import androidx.lifecycle.*
import com.actduck.videogame.data.source.remote.ApiService
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.launch
import okhttp3.ResponseBody
import org.apache.commons.io.FileUtils
import org.apache.commons.io.FilenameUtils
import paulscode.android.mupen64plusae.util.FileUtil
import timber.log.Timber
import java.io.BufferedInputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.io.InputStream
import java.util.zip.ZipEntry
import java.util.zip.ZipInputStream
import javax.inject.Inject

/**
 * ViewModel for the game list screen.
 */
@HiltViewModel
class MyScanRomsViewModel @Inject constructor(
  private val savedStateHandle: SavedStateHandle,
  private val apiService: ApiService,
) : ViewModel() {

}
