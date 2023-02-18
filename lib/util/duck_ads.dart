import 'dart:async';

import 'package:flutter/material.dart';

// import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:videogame/constants.dart';
import 'package:videogame/logger.dart';
import 'package:videogame/model/list_item.dart';
import 'package:videogame/net/app_repo.dart';
import 'package:videogame/pages/main_page.dart';
import 'package:videogame/util/duck_ads_id.dart';
import 'package:videogame/util/duck_billing.dart';
import 'package:videogame/util/duck_config.dart';
import 'package:videogame/util/duck_kv.dart';
import 'package:videogame/util/duck_user.dart';

import '../model/ads_config.dart';
import '../model/event.dart';
import 'app_open_ad_manager.dart';
import 'duck_analytics.dart';

const int maxFailedLoadAttempts = 3;

class DuckAds {
  static final String _TAG = "DuckAds";

  DuckAds._() {
    DuckKV.readKey("ad_npa").then((value) {
      if (value == null) {
        npa = false;
      } else {
        npa = value;
      }
    });
  }

  static final DuckAds _instance = DuckAds._();

  /// Shared instance to initialize the AdMob SDK.
  static DuckAds get instance => _instance;

  bool shouldShowAd = true;

  // 由remoteConfig 控制的显示广告
  bool shouldShowBanner = true;
  bool shouldShowIn1 = true;
  bool shouldShowIn2 = true;
  bool shouldShowRewarded = true;
  bool shouldShowOpen = true;
  bool shouldShowNative1 = true;
  bool shouldShowNative2 = true;

  // 非个性广告
  bool npa = false;

  Future<void> refreshShowAdsFlag() async {
    LOG.D(_TAG, "refreshShowAdsFlag: START 开始刷新广告显示");
    shouldShowAd = !(await DuckBilling.instance.isPremium() || await DuckBilling.instance.isAdFree());
    LOG.D(_TAG, "refreshShowAdsFlag: 应该显示广告吗 $shouldShowAd");
  }

  void refreshAdShow() {
    [AD_ADMOB_BANNER, AD_ADMOB_IN1, AD_ADMOB_IN2, AD_ADMOB_REWARDED, AD_ADMOB_OPEN, AD_ADMOB_NATIVE1, AD_ADMOB_NATIVE2]
        .forEach((element) {
      refreshSingleAdShowAndInterval(element);
    });
  }

  /**
   * 刷新广告的显示和间隔
   */
  void refreshSingleAdShowAndInterval(int adFormat) async {
    int clickTimesToday = (await AppRepo().getAdsClickTimesToday(adFormat)).length;

    AdsConfig? adsConfig = await DuckConfig.instance.getAdsConfig(adFormat);

    if (adsConfig != null) {
      LOG.D(_TAG,
          "refreshSingleAdShow: $adFormat 今日点击数: $clickTimesToday 配置的点击数: ${adsConfig.clickTimes} enable: ${adsConfig.enable}");
      if (clickTimesToday > adsConfig.clickTimes! || !adsConfig.enable!) {
        disAbleSingeAds(adFormat);
      }

      if (adFormat == AD_ADMOB_OPEN) {
        setOpenAdsInterval(adsConfig.interval!);
      }
    }
  }

  void disAbleSingeAds(int adFormat) {
    LOG.W(_TAG, "disAbleSingeAds: 禁用单个广告：$adFormat");

    DuckAnalytics.analytics.logEvent(name: "disable_single_ad", parameters: <String, dynamic>{
      'ad_format': adFormat,
      'user_id': DuckUser.instance.userInfo?.id,
    });

    eventBus.fire(DisableAdEvent(adFormat));
    switch (adFormat) {
      case AD_ADMOB_BANNER:
        shouldShowBanner = false;
        break;
      case AD_ADMOB_IN1:
        shouldShowIn1 = false;
        break;
      case AD_ADMOB_IN2:
        shouldShowIn2 = false;
        break;
      case AD_ADMOB_REWARDED:
        shouldShowRewarded = false;
        break;
      case AD_ADMOB_OPEN:
        shouldShowOpen = false;
        break;
      case AD_ADMOB_NATIVE1:
        shouldShowNative1 = false;
        break;
      case AD_ADMOB_NATIVE2:
        shouldShowNative2 = false;
        break;
    }
  }

  setConsent(bool agree) {
    npa = !agree;
    LOG.D(_TAG, "setConsent 用户同意了没: $agree 使用非个性广告: $npa");
    DuckKV.saveKey("ad_npa", npa);
  }

  ///======================================横幅广告==============================

  late BannerAd myBanner;

  loadBannerAd({void onAdShow(int ad)?, void onAdClick(int ad)?}) async {
    if (shouldShowAd && shouldShowBanner && isMobile) {
      myBanner = BannerAd(
        adUnitId: AdId.GG_BANNER,
        size: AdSize.banner,
        request: AdRequest(nonPersonalizedAds: npa),
        listener: BannerAdListener(
          onAdClicked: (bannerAd) {
            LOG.D(_TAG, "loadBanner: 横幅广告点击");
            onAdClick?.call(AD_ADMOB_BANNER);
          },
          onAdImpression: (bannerAd) {
            LOG.D(_TAG, "loadBanner: 横幅广告显示");
            onAdShow?.call(AD_ADMOB_BANNER);
          },
        ),
      );
      LOG.D(_TAG, "loadBanner: 加载横幅广告 非个性化广告？ $npa");
      await myBanner.load();
    }
  }

  Widget BannerAdWidget() {
    if (shouldShowAd && shouldShowBanner && isMobile) {
      final AdWidget adWidget = new AdWidget(ad: myBanner);
      return Container(
        alignment: Alignment.center,
        child: adWidget,
        width: myBanner.size.width.toDouble(),
        height: myBanner.size.height.toDouble(),
      );
    } else {
      return Container();
    }
  }

  ///======================================插页广告==============================
  InterstitialAd? myInterstitial;
  int _numInterstitialLoadAttempts = 0;

  createInterstitialAd() {
    if (shouldShowAd && shouldShowIn1 && isMobile) {
      InterstitialAd.load(
          adUnitId: AdId.GG_IN,
          request: AdRequest(nonPersonalizedAds: npa),
          adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (InterstitialAd ad) {
              // Keep a reference to the ad so you can show it later.
              LOG.D(_TAG, '插页广告加载成功 Ad loaded.');
              myInterstitial = ad;
              _numInterstitialLoadAttempts = 0;
            },
            onAdFailedToLoad: (LoadAdError error) {
              LOG.D(_TAG, '插页广告加载失败 Ad failed to load: $error');
              _numInterstitialLoadAttempts++;
              if (_numInterstitialLoadAttempts <= maxFailedLoadAttempts) {
                createInterstitialAd();
              }
            },
          ));

      LOG.D(_TAG, '插页广告 loading');
    }
  }

  // disposeInterstitialAd() {
  //   if (myInterstitial != null) {
  //     LOG.D(_TAG, "disposeInterstitialAd: 释放插页广告");
  //     myInterstitial.dispose();
  //   }
  // }

  showInterstitialAd({void onAdFinish()?, void onAdShow(int ad)?, void onAdClick(int ad)?}) {
    if (myInterstitial == null) {
      LOG.W(_TAG, 'Warning: attempt to show interstitial before loaded.');
      onAdFinish?.call();
      return;
    }

    if (shouldShowAd && shouldShowIn1 && isMobile) {
      myInterstitial?.fullScreenContentCallback =
          FullScreenContentCallback(onAdShowedFullScreenContent: (InterstitialAd ad) {
        LOG.D(_TAG, 'ad onAdShowedFullScreenContent.');
        myInterstitial = null;
      }, onAdDismissedFullScreenContent: (InterstitialAd ad) {
        LOG.D(_TAG, '$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        // createInterstitialAd();
        onAdFinish?.call();
        onAdShow?.call(AD_ADMOB_IN1);
      }, onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        LOG.D(_TAG, '$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        onAdFinish?.call();
        // createInterstitialAd();
      }, onAdClicked: (InterstitialAd ad) {
        LOG.D(_TAG, '$ad onAdClicked.');
        onAdClick?.call(AD_ADMOB_IN1);
      });

      myInterstitial?.show();
    } else {
      onAdFinish?.call();
    }
  }

  ///======================================插页广告2==============================
  InterstitialAd? myInterstitial2;
  int _numInterstitial2LoadAttempts = 0;

  createInterstitialAd2() {
    if (shouldShowAd && shouldShowIn2 && isMobile) {
      InterstitialAd.load(
          adUnitId: AdId.GG_IN2,
          request: AdRequest(nonPersonalizedAds: npa),
          adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (InterstitialAd ad) {
              // Keep a reference to the ad so you can show it later.
              LOG.D(_TAG, '插页广告2加载成功 Ad loaded.');
              myInterstitial2 = ad;
              _numInterstitial2LoadAttempts = 0;
            },
            onAdFailedToLoad: (LoadAdError error) {
              LOG.D(_TAG, '插页广告2加载失败 Ad failed to load: $error');
              _numInterstitial2LoadAttempts++;
              if (_numInterstitial2LoadAttempts <= maxFailedLoadAttempts) {
                createInterstitialAd2();
              }
            },
          ));

      LOG.D(_TAG, '插页广告2 loading');
    }
  }

  // disposeInterstitialAd() {
  //   if (myInterstitial != null) {
  //     LOG.D(_TAG, "disposeInterstitialAd: 释放插页广告");
  //     myInterstitial.dispose();
  //   }
  // }

  showInterstitialAd2({void onAdFinish()?, void onAdShow(int ad)?, void onAdClick(int ad)?}) {
    if (myInterstitial2 == null) {
      LOG.W(_TAG, 'Warning: attempt to show interstitial before loaded.');
      onAdFinish?.call();
      return;
    }

    if (shouldShowAd && shouldShowIn2 && isMobile) {
      myInterstitial2?.fullScreenContentCallback =
          FullScreenContentCallback(onAdShowedFullScreenContent: (InterstitialAd ad) {
        LOG.D(_TAG, 'ad2 onAdShowedFullScreenContent.');
        myInterstitial2 = null;
      }, onAdDismissedFullScreenContent: (InterstitialAd ad) {
        LOG.D(_TAG, '$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        // createInterstitialAd2();
        onAdFinish?.call();
        onAdShow?.call(AD_ADMOB_IN2);
      }, onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        LOG.D(_TAG, '$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        onAdFinish?.call();
        // createInterstitialAd2();
      }, onAdClicked: (InterstitialAd ad) {
        LOG.D(_TAG, '$ad onAdClicked.');
        onAdClick?.call(AD_ADMOB_IN2);
      });

      myInterstitial2?.show();
    } else {
      onAdFinish?.call();
    }
  }

  ///======================================插页广告2加载显示==============================
  createAndShowInterstitialAd2() {
    if (shouldShowAd && shouldShowIn2 && isMobile) {
      LOG.D(_TAG, '插页广告2 loading and show');
      InterstitialAd.load(
          adUnitId: AdId.GG_IN2,
          request: AdRequest(nonPersonalizedAds: npa),
          adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (InterstitialAd ad) {
              // Keep a reference to the ad so you can show it later.
              LOG.D(_TAG, '插页广告2 加载成功 Ad loaded.');
              ad.show();
            },
            onAdFailedToLoad: (LoadAdError error) {
              LOG.D(_TAG, '插页广告2 加载失败 Ad failed to load: $error');
            },
          ));
    }
  }

  ///======================================激励广告==============================
  late RewardedAd? myRewarded;

  createRewardAd({Function()? onSuccess, Function()? onFailed}) async {
    if (shouldShowRewarded) {
      LOG.D(_TAG, 'loadAndShowRewardAd 加载激励广告');
      RewardedAd.load(
        adUnitId: AdId.GG_REWARD,
        request: AdRequest(nonPersonalizedAds: npa),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            LOG.D(_TAG, 'Ad onAdLoaded 激励广告加载成功');
            this.myRewarded = ad;
            onSuccess!.call();
          },
          onAdFailedToLoad: (LoadAdError error) {
            LOG.D(_TAG, 'Ad onAdFailedToLoad 激励广告加载失败: $error');
            onFailed!.call();
          },
        ),
      );
    }
  }

  showRewardAd(onRewarded, {void onAdShow(int ad)?, void onAdClick(int ad)?}) {
    if (shouldShowRewarded) {
      myRewarded?.fullScreenContentCallback = FullScreenContentCallback(onAdShowedFullScreenContent: (RewardedAd ad) {
        LOG.D(_TAG, 'ad2 onAdShowedFullScreenContent.');
        myInterstitial2 = null;
      }, onAdDismissedFullScreenContent: (RewardedAd ad) {
        LOG.D(_TAG, '$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        onAdShow?.call(AD_ADMOB_REWARDED);
      }, onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        LOG.D(_TAG, '$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
      }, onAdClicked: (RewardedAd ad) {
        LOG.D(_TAG, '$ad onAdClicked.');
        onAdClick?.call(AD_ADMOB_REWARDED);
      });
      myRewarded?.show(onUserEarnedReward: onRewarded);
    }
  }

  ///======================================开屏广告==============================

  bool _shouldShowOpenAd = true;
  AppOpenAdManager? _appOpenAdManager;

  void initOpenAd() {
    _appOpenAdManager = AppOpenAdManager()..loadAd();
  }

  /// 游戏结束不显示开屏广告
  void dontShowOpenAd() {
    _shouldShowOpenAd = false;
  }

  void showOpenAdIfAvailable({void onAdShow(int ad)?, void onAdClick(int ad)?}) {
    if (_shouldShowOpenAd) {
      _appOpenAdManager?.showAdIfAvailable(onAdShow: onAdShow, onAdClick: onAdClick);
    } else {
      LOG.D(_TAG, "showOpenAdIfAvailable: 不应显示开屏广告，刷新flag");
      _shouldShowOpenAd = true;
    }
  }

  setOpenAdsInterval(int interval) {
    _appOpenAdManager?.setInterval(interval);
  }

  ///======================================原生广告1==============================

  int _kAdIndex1 = 5;
  int _maxAd1 = 1;

  List<NativeAd> _newAdList1 = [];
  List<NativeAd> _oldAdList1 = [];

  Function? onAdLoaded1;
  Function? onAdShow1;
  Function? onAdClick1;

  void setNativeAd1Params(
      {int? adIndex, int? maxAd, void onAdLoaded()?, void onAdShow(int ad)?, void onAdClick(int ad)?}) {
    if (adIndex != null) {
      _kAdIndex1 = adIndex;
    }
    if (maxAd != null) {
      _maxAd1 = maxAd;
    }
    if (onAdLoaded != null) {
      onAdLoaded1 = onAdLoaded;
    }
    if (onAdShow != null) {
      onAdShow1 = onAdShow;
    }
    if (onAdClick != null) {
      onAdClick1 = onAdClick;
    }
  }

  void loadNativeAd1() {
    if (shouldShowAd && shouldShowNative1 && isMobile) {
      int adLoad = 0;
      for (int i = 0; i < _maxAd1 - _newAdList1.length; i++) {
        LOG.D(_TAG, '原生广告1 loadManyNativeAd 加载开始 index : $i');
        NativeAd(
          adUnitId: AdId.GG_NATIVE1,
          factoryId: 'homeTile',
          request: AdRequest(nonPersonalizedAds: npa),
          listener: NativeAdListener(
            onAdLoaded: (ad) {
              LOG.D(_TAG, '原生广告1加载成功 index : $i');
              _newAdList1.add(ad as NativeAd);
              adLoad++;
              if (adLoad == _maxAd1) onAdLoaded1?.call();
            },
            onAdFailedToLoad: (ad, error) {
              // Releases an ad resource when it fails to load
              ad.dispose();
              LOG.D(_TAG, '原生广告1加载失败 index : $i failed (code=${error.code} message=${error.message})');
              adLoad++;
              if (adLoad == _maxAd1) onAdLoaded1?.call();
            },
            onAdClicked: (nativeAd) {
              LOG.D(_TAG, "loadNativeAd1: 原生广告1点击");
              onAdClick1?.call(AD_ADMOB_NATIVE1);
            },
            onAdImpression: (nativeAd) {
              LOG.D(_TAG, "loadNativeAd1: 原生广告1显示");
              onAdShow1?.call(AD_ADMOB_NATIVE1);
            },
          ),
        ).load();
      }
    }
  }

  Widget NativeAdWidget1(NativeAd? nativeAd) {
    if (shouldShowAd && shouldShowNative1 && isMobile) {
      if (nativeAd == null) {
        return Container();
      } else {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          height: 196,
          width: 216,
          child: AdWidget(ad: nativeAd),
        );
      }
    } else {
      return Container();
    }
  }

  List<ListItem> addNativeAd1(int total, List<ListItem> gameList) {
    if (shouldShowAd && shouldShowNative1 && isMobile) {
      List<ListItem> list = [];
      for (int i = total; i < total + gameList.length; i++) {
        if (i > 0 && i % _kAdIndex1 == 0 && _newAdList1.length > 0) {
          var ad = _newAdList1[0];
          _oldAdList1.add(ad);
          _newAdList1.removeAt(0);
          list.add(AdItem(ad));
        }
        list.add(gameList[i - total]);
      }

      loadNativeAd1();
      return list;
    } else {
      return gameList;
    }
  }

  void disposeNativeAd1() {
    LOG.D(_TAG, '原生广告1 释放');
    for (var value in _oldAdList1) {
      value.dispose();
    }
    _oldAdList1.clear();
  }

  ///======================================原生广告2==============================

  int _kAdIndex2 = 10;
  int _maxAd2 = 1;

  List<NativeAd> _newAdList2 = [];
  List<NativeAd> _oldAdList2 = [];

  Function? onAdLoaded2;
  Function? onAdShow2;
  Function? onAdClick2;

  void setNativeAd2Params(
      {int? adIndex, int? maxAd, void onAdLoaded()?, void onAdShow(int ad)?, void onAdClick(int ad)?}) {
    if (adIndex != null) {
      _kAdIndex2 = adIndex;
    }
    if (maxAd != null) {
      _maxAd2 = maxAd;
    }
    if (onAdLoaded != null) {
      onAdLoaded2 = onAdLoaded;
    }
    if (onAdShow != null) {
      onAdShow2 = onAdShow;
    }
    if (onAdClick != null) {
      onAdClick2 = onAdClick;
    }
  }

  void loadNativeAd2() {
    if (shouldShowAd && shouldShowNative2 && isMobile) {
      for (int i = 0; i < _maxAd2 - _newAdList2.length; i++) {
        LOG.D(_TAG, '原生广告2 loadManyNativeAd 加载开始 index : $i');
        NativeAd(
          adUnitId: AdId.GG_NATIVE2,
          factoryId: 'listTile',
          request: AdRequest(nonPersonalizedAds: npa),
          listener: NativeAdListener(
            onAdLoaded: (ad) {
              LOG.D(_TAG, '原生广告2加载成功 index : $i');
              _newAdList2.add(ad as NativeAd);
              onAdLoaded2?.call();
            },
            onAdFailedToLoad: (ad, error) {
              // Releases an ad resource when it fails to load
              ad.dispose();
              LOG.D(_TAG, '原生广告2加载失败 index : $i failed (code=${error.code} message=${error.message})');
            },
            onAdClicked: (nativeAd) {
              LOG.D(_TAG, "loadNativeAd2: 原生广告2点击");
              onAdClick2?.call(AD_ADMOB_NATIVE2);
            },
            onAdImpression: (nativeAd) {
              LOG.D(_TAG, "loadNativeAd2: 原生广告2显示");
              onAdShow2?.call(AD_ADMOB_NATIVE2);
            },
          ),
        ).load();
      }
    }
  }

  List<ListItem> addNativeAd2(int total, List<ListItem> gameList) {
    if (shouldShowAd && shouldShowNative2 && isMobile) {
      List<ListItem> list = [];
      for (int i = total; i < total + gameList.length; i++) {
        if (i > 0 && i % _kAdIndex2 == 0 && _newAdList2.length > 0) {
          var ad = _newAdList2[0];
          _oldAdList2.add(ad);
          _newAdList2.removeAt(0);
          list.add(AdItem(ad));
        }
        list.add(gameList[i - total]);
      }

      loadNativeAd2();
      return list;
    } else {
      return gameList;
    }
  }

  Widget NativeAdWidget2(NativeAd? nativeAd) {
    if (shouldShowAd && shouldShowNative2 && isMobile) {
      if (nativeAd == null) {
        return Container();
      } else {
        return Container(
          height: 83.0,
          alignment: Alignment.center,
          child: AdWidget(ad: nativeAd),
        );
      }
    } else {
      return Container();
    }
  }

  void disposeNativeAd2() {
    LOG.D(_TAG, '原生广告2 释放');
    for (var value in _oldAdList2) {
      value.dispose();
    }
    _oldAdList2.clear();
  }
}
