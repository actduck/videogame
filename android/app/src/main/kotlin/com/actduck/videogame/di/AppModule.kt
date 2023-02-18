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

package com.actduck.videogame.di

import android.content.Context
import androidx.room.Room
import com.actduck.videogame.data.source.Repository
import com.actduck.videogame.data.source.RepositoryImpl
import com.actduck.videogame.data.source.local.AppDb
import com.actduck.videogame.data.source.local.DbService
import com.actduck.videogame.data.source.remote.ApiService
import com.actduck.videogame.data.source.remote.BASE_URL
import com.actduck.videogame.data.source.remote.DownloadService
import com.actduck.videogame.di.gson.MyGsonConverterFactory
import com.actduck.videogame.util.LemUtils
import com.actduck.videogame.util.NDSUtils
import com.google.gson.GsonBuilder
import com.swordfish.lemuroid.lib.library.db.RetrogradeDatabase
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import me.magnum.melonds.domain.repositories.RomsRepository
import me.magnum.melonds.domain.repositories.SettingsRepository
import okhttp3.Cache
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import java.io.File
import java.util.concurrent.TimeUnit
import javax.inject.Singleton

/**
 * Module to tell Hilt how to provide instances of types that cannot be constructor-injected.
 *
 * As these types are scoped to the application lifecycle using @Singleton, they're installed
 * in Hilt's ApplicationComponent.
 */
@Module
@InstallIn(SingletonComponent::class)
object AppModule {

  @Singleton
  @Provides
  fun providesHttpLoggingInterceptor() = HttpLoggingInterceptor()
    .apply {
      level = HttpLoggingInterceptor.Level.BODY
    }

  @Singleton
  @Provides
  fun providesOkHttpClient(
    httpLoggingInterceptor: HttpLoggingInterceptor,
    @ApplicationContext context: Context
  ): OkHttpClient {
    val httpCacheDirectory = File(context.cacheDir, "http-cache")
    val cacheSize = 10L * 1024 * 1024 // 10 MiB

    val cache = Cache(httpCacheDirectory, cacheSize)
    return OkHttpClient
      .Builder()
      .addInterceptor(httpLoggingInterceptor)
      .addNetworkInterceptor(CacheInterceptor())
      .cache(cache)
      .readTimeout(1, TimeUnit.MINUTES)
      .writeTimeout(1, TimeUnit.MINUTES)
      .build()
  }

  @Singleton
  @Provides
  fun provideRepository(
    apiService: ApiService,
    dbService: DbService,
    ioDispatcher: CoroutineDispatcher
  ): Repository {
    return RepositoryImpl(
      apiService, dbService, ioDispatcher
    )
  }

  @Provides
  fun provideVideoGameService(
    okHttpClient: OkHttpClient
  ): Retrofit {
    return Retrofit.Builder()
      .baseUrl(BASE_URL)
      .client(okHttpClient)
      .addConverterFactory(
        MyGsonConverterFactory.create(
          GsonBuilder().setDateFormat("yyyy-MM-dd HH:mm:ss").create()
        )
      )
      .build()
  }

  @Singleton
  @Provides
  fun provideApiService(retrofit: Retrofit): ApiService = retrofit.create(ApiService::class.java)

  @Singleton
  @Provides
  fun provideDownloadService(): DownloadService {

    val okHttpClient = OkHttpClient
      .Builder()
      .readTimeout(1, TimeUnit.MINUTES)
      .writeTimeout(1, TimeUnit.MINUTES)
      .build()

    val retrofit = Retrofit.Builder()
      .baseUrl(BASE_URL)
      .client(okHttpClient)
      .addConverterFactory(
        MyGsonConverterFactory.create(
          GsonBuilder().setDateFormat("yyyy-MM-dd HH:mm:ss").create()
        )
      )
      .build()

    return retrofit.create(DownloadService::class.java)
  }

  @Singleton
  @Provides
  fun provideDbService(
    database: AppDb,
    ioDispatcher: CoroutineDispatcher
  ): DbService {
    return DbService(
      database.gameDao(), ioDispatcher
    )
  }

  @Singleton
  @Provides
  fun provideDataBase(@ApplicationContext context: Context): AppDb {
    // todo 升级数据库
    return Room.databaseBuilder(
      context.applicationContext,
      AppDb::class.java,
      "Games.db"
    )
      .build()
  }

  @Singleton
  @Provides
  fun provideNDSUtil(settingsRepository: SettingsRepository, romsRepository: RomsRepository) =
    NDSUtils(settingsRepository, romsRepository);

  @Singleton
  @Provides
  fun provideLemUtil(retrogradedb: RetrogradeDatabase) =
    LemUtils(retrogradedb)

  @Singleton
  @Provides
  fun provideIoDispatcher() = Dispatchers.IO
}

