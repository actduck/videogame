import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:videogame/model/ads_config.dart';
import 'package:videogame/util/duck_ads.dart';
import 'package:videogame/util/duck_ads_id.dart';

import '../constants.dart';
import '../logger.dart';

class DuckConfig {
  static final String _TAG = "DuckConfig";

  DuckConfig._();

  static final DuckConfig _instance = DuckConfig._();

  static DuckConfig get instance => _instance;
  Map<String, RemoteConfigValue>? rcMap = null;

  void setUp() async {
    await _initRemoteConfig();
    await _fetchConfig();
    DuckAds.instance.refreshAdShow();

    _configNativeAd();
    _loadNativeAd();
  }

  FirebaseRemoteConfig? remoteConfig = null;

  Future _initRemoteConfig() async {
    LOG.D(_TAG, "_initRemoteConfig 开始 $rcMap");
    remoteConfig = FirebaseRemoteConfig.instance;
    if (isReleaseMode()) {
      await remoteConfig?.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));
    } else {
      await remoteConfig?.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(minutes: 5),
      ));
    }
  }

  Future _fetchConfig() async {
    await remoteConfig?.fetchAndActivate();
    rcMap = remoteConfig?.getAll();
    LOG.D(_TAG, "获取到所有配置 $rcMap");
  }

  AdsConfig? getAdsConfig(int adFormat) {
    if (rcMap != null) {
      switch (adFormat) {
        case AD_ADMOB_BANNER:
          return AdsConfig.fromJson(jsonDecode(rcMap![KEY_BANNERADS]!.asString()));
        case AD_ADMOB_IN1:
          return AdsConfig.fromJson(jsonDecode(rcMap![KEY_INTERSTITIALADS]!.asString()));
        case AD_ADMOB_IN2:
          return AdsConfig.fromJson(jsonDecode(rcMap![KEY_INTERSTITIAL2ADS]!.asString()));
        case AD_ADMOB_REWARDED:
          return AdsConfig.fromJson(jsonDecode(rcMap![KEY_REWARDEDADS]!.asString()));
        case AD_ADMOB_OPEN:
          return AdsConfig.fromJson(jsonDecode(rcMap![KEY_OPENAPPADS]!.asString()));
        case AD_ADMOB_NATIVE1:
          return AdsConfig.fromJson(jsonDecode(rcMap![KEY_NATIVE1ADS]!.asString()));
        case AD_ADMOB_NATIVE2:
          return AdsConfig.fromJson(jsonDecode(rcMap![KEY_NATIVE2ADS]!.asString()));
      }
    }
    return null;
  }

  void _configNativeAd() {
    LOG.D(_TAG, "_configNativeAd 配置原生广告参数");
    var n1Config = getAdsConfig(AD_ADMOB_NATIVE1);
    DuckAds.instance.setNativeAd1Params(adIndex: n1Config?.adIndex, maxAd: n1Config?.maxAd);
    var n2Config = getAdsConfig(AD_ADMOB_NATIVE2);
    DuckAds.instance.setNativeAd2Params(adIndex: n2Config?.adIndex, maxAd: n2Config?.maxAd);
  }

  void _loadNativeAd() {
    LOG.D(_TAG, "_loadNativeAd 加载原生广告");
    DuckAds.instance.loadNativeAd1();
    DuckAds.instance.loadNativeAd2();
  }
}
