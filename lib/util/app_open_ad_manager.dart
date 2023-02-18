// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// ignore_for_file: public_member_api_docs

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:videogame/constants.dart';
import 'package:videogame/logger.dart';
import 'package:videogame/util/duck_ads.dart';
import 'package:videogame/util/duck_ads_id.dart';
import 'package:videogame/util/duck_kv.dart';

/// Utility class that manages loading and showing app open ads.
class AppOpenAdManager {
  static final String _TAG = "AppOpenAdManager";

  /// Maximum duration allowed between loading and showing the ad.
  final Duration maxCacheDuration = Duration(hours: 4);

  /// Keep track of load time so we don't show an expired ad.
  DateTime? _appOpenLoadTime;

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  int _interval = 5000;

  /// Load an [AppOpenAd].
  void loadAd() {
    if (DuckAds.instance.shouldShowAd && DuckAds.instance.shouldShowOpen && isMobile) {
      AppOpenAd.load(
        adUnitId: AdId.GG_OPEN,
        orientation: AppOpenAd.orientationPortrait,
        request: AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            LOG.D(_TAG, '$ad loaded');
            _appOpenLoadTime = DateTime.now();
            _appOpenAd = ad;
          },
          onAdFailedToLoad: (error) {
            LOG.D(_TAG, 'AppOpenAd failed to load: $error');
          },
        ),
      );
    }
  }

  /// Whether an ad is available to be shown.
  bool get isAdAvailable {
    return _appOpenAd != null;
  }

  void setInterval(int interval) {
    this._interval = interval;
  }

  /// Shows the ad, if one exists and is not already being shown.
  ///
  /// If the previously cached ad has expired, this just loads and caches a
  /// new ad.
  void showAdIfAvailable({void onAdShow(int ad)?, void onAdClick(int ad)?}) async {
    if (!DuckAds.instance.shouldShowAd || !DuckAds.instance.shouldShowOpen) {
      LOG.D(_TAG, 'No need show ad 无需显示开屏广告');
      return;
    }

    int? lastShowTime = await DuckKV.readKey("last_open_ad_show_time");
    if (lastShowTime != null) {
      var myInterval = DateTime.now().millisecondsSinceEpoch - lastShowTime;
      myInterval < _interval;
      LOG.D(_TAG, 'No need show ad 间隔不够 $myInterval < $_interval');
      return;
    }

    if (!isAdAvailable) {
      LOG.D(_TAG, 'Tried to show ad before available.');
      loadAd();
      return;
    }
    if (_isShowingAd) {
      LOG.D(_TAG, 'Tried to show ad while already showing an ad.');
      return;
    }
    if (DateTime.now().subtract(maxCacheDuration).isAfter(_appOpenLoadTime!)) {
      LOG.D(_TAG, 'Maximum cache duration exceeded. Loading another ad.');
      _appOpenAd!.dispose();
      _appOpenAd = null;
      loadAd();
      return;
    }
    // Set the fullScreenContentCallback and show the ad.
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(onAdShowedFullScreenContent: (ad) {
      _isShowingAd = true;
      LOG.D(_TAG, '$ad onAdShowedFullScreenContent');
      onAdShow?.call(AD_ADMOB_OPEN);
      DuckKV.saveKey("last_open_ad_show_time", DateTime.now().millisecondsSinceEpoch);
    }, onAdFailedToShowFullScreenContent: (ad, error) {
      LOG.D(_TAG, '$ad onAdFailedToShowFullScreenContent: $error');
      _isShowingAd = false;
      ad.dispose();
      _appOpenAd = null;
    }, onAdDismissedFullScreenContent: (ad) {
      LOG.D(_TAG, '$ad onAdDismissedFullScreenContent');
      _isShowingAd = false;
      ad.dispose();
      _appOpenAd = null;
      loadAd();
    }, onAdClicked: (AppOpenAd ad) {
      LOG.D(_TAG, '$ad onAdClicked.');
      onAdClick?.call(AD_ADMOB_OPEN);
    });
    _appOpenAd?.show();
  }
}
