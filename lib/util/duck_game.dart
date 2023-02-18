import 'dart:convert';
import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:games_services/games_services.dart';
import 'package:google_api_availability/google_api_availability.dart';
import 'package:launch_review/launch_review.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:videogame/constants.dart';
import 'package:videogame/db/db.dart';
import 'package:videogame/generated/l10n.dart';
import 'package:videogame/logger.dart';
import 'package:videogame/model/event.dart';
import 'package:videogame/model/game.dart';
import 'package:videogame/model/game_type.dart';
import 'package:videogame/model/scan_roms_result.dart';
import 'package:videogame/net/app_repo.dart';
import 'package:videogame/pages/about_page.dart';
import 'package:videogame/pages/buy_coins_sheet.dart';
import 'package:videogame/pages/main_page.dart';
import 'package:videogame/util/duck_ads.dart';
import 'package:videogame/util/duck_ads_id.dart';
import 'package:videogame/util/duck_analytics.dart';
import 'package:videogame/util/duck_billing.dart';
import 'package:videogame/util/duck_config.dart';
import 'package:videogame/util/duck_kv.dart';
import 'package:videogame/util/duck_user.dart';

import '../app_theme.dart';
import '../model/ad_analytics.dart';
import '../model/download_event.dart';
import 'duck_downloader.dart';

class DuckGame {
  static final String _TAG = "DuckGame";

  static late AndroidDeviceInfo androidInfo;

  DuckGame._() {
    _eventChannel.receiveBroadcastStream().listen((dynamic event) {
      LOG.D(_TAG, "EventChannel Received event 收到通知: $event");
      if (event == "game_over") {
        DuckAds.instance.dontShowOpenAd();
        DuckAds.instance.showInterstitialAd2(onAdShow: (ad) {
          AppRepo().reportAds(AdAnalytics.ad(ad, 1));
        }, onAdClick: (ad) {
          AppRepo().reportAds(AdAnalytics.ad(ad, 2));
        });
      } else if (event == "foreground") {
        LOG.D(_TAG, "initOpenAd: 应用到前台了");
        DuckAds.instance.showOpenAdIfAvailable(onAdShow: (ad) {
          AppRepo().reportAds(AdAnalytics.ad(ad, 1));
        }, onAdClick: (ad) {
          AppRepo().reportAds(AdAnalytics.ad(ad, 2));
        });
      }
    }, onError: (dynamic error) {
      LOG.E(_TAG, "EventChannel Received error 收到错误: ${error.message}");
    }, cancelOnError: true);

    DeviceInfoPlugin().androidInfo.then((value) => androidInfo = value);
  }

  Future<bool> checkPlayServices() async {
    GooglePlayServicesAvailability playStoreAvailability;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      playStoreAvailability = await GoogleApiAvailability.instance.checkGooglePlayServicesAvailability();
    } on PlatformException {
      playStoreAvailability = GooglePlayServicesAvailability.unknown;
    }

    LOG.D(_TAG, "checkPlayServices: 检查Google Play 服务$playStoreAvailability");
    return playStoreAvailability.value == GooglePlayServicesAvailability.success.value;
  }

  static final DuckGame _instance = DuckGame._();

  /// Shared instance to initialize the AdMob SDK.
  static DuckGame get instance => _instance;

  String pluginPackageName = "com.actduck.videogame";

  String? _localPath;

  List premiumGameType = ["GC", "Wii", "PSX", "3DS"];

  Future _prepare() async {
    if (_localPath == null) {
      _localPath = (await _findLocalPath()) + Platform.pathSeparator + 'rom';
      final savedDir = Directory(_localPath!);
      bool hasExisted = await savedDir.exists();
      if (!hasExisted) {
        savedDir.create(recursive: true);
      }
    }
  }

  /// 看路径是否在
  Future<String> _findLocalPath() async {
    final directory =
        Platform.isAndroid ? await getExternalStorageDirectory() : await getApplicationDocumentsDirectory();
    return directory!.path;
  }

  /// rom是否存在
  Future<bool> isRomExist(Game game) async {
    return isWeb ? true : await isRunnableRomExist(game);
  }

  Future<bool> isTmpFileExist(Game game) async {
    var cacheDir = await getExternalCacheDirectories();
    if (cacheDir == null || cacheDir.isEmpty) {
      return false;
    }

    // 本地已有下载中的文件
    var zipRomFile = File(cacheDir[0].path + Platform.pathSeparator + basename(game.zipUrl!));

    var splitFile =
        File(cacheDir[0].path + Platform.pathSeparator + basenameWithoutExtension(game.zipUrl!) + "_0.part");

    return await zipRomFile.exists() || await splitFile.exists();
  }

  Future<bool> isDownloadRunning(Game game) async {
    var downloadRunning = false;
    var gat = await DuckDao.getGameAndTask(game.id);
    if (gat != null && downloadEventFromMap(gat.taskInfo!).downloadState == DOWNLOAD_STATE_PROGRESS) {
      downloadRunning = true;
    }
    return downloadRunning;
  }

  /// 可运行的rom是否存在
  Future<bool> isRunnableRomExist(Game game) async {
    await _prepare();

    File rom;
    String fileName;
    if (game.localGame != null && game.localGame!) {
      fileName = game.name!;
      rom = File(game.romLocalPath!);
    } else {
      fileName = basename(game.url!);
      rom = File(_localPath! + Platform.pathSeparator + game.gameType!.name! + Platform.pathSeparator + fileName);
    }
    var exist = await rom.exists();
    if (exist) {
      game.romLocalPath = rom.path;
    }
    LOG.D(_TAG, "isRomExist: 游戏rom是: $fileName: $exist");
    return exist;
  }

  // /// 解压后的rom是否存在
  // Future<bool> isUnzipRomExist(Game game) async {
  //   await _prepare();
  //   File rom = File(_localPath! +
  //       Platform.pathSeparator +
  //       game.gameType!.name! +
  //       Platform.pathSeparator +
  //       game.rom!);
  //   var exist = await rom.exists();
  //   if (exist) {
  //     game.romLocalPath = rom.path;
  //   }
  //   LOG.D(_TAG, "isUnzipRomExist: 游戏rom是: $rom: $exist");
  //   return exist;
  // }

  Future<bool> canPlayGame(BuildContext context, Game? game) async {
    if (isWeb) {
      showPlayOnMobileDialog(context);
      return false;
    }
    var gameType = game?.gameType;
    if (gameType == null) {
      showSetGameTypeDialog(context, game);
      return false;
    }
    if ((gameType.name == 'GC' || gameType.name == 'Wii' || gameType.name == '3DS') && !is64Bit()) {
      showNotSupportDialog(context);
      return false;
    }

    var hasPlugin = await isPluginSupport(gameType);
    if (!hasPlugin) {
      showUpdateDialog(context, gameType);
      return false;
    }

    var isPremium = await DuckBilling.instance.isPremium();
    if (!isPremium && premiumGameType.contains(gameType.name)) {
      showPremiumGameDialog(context, gameType);
      return false;
    }

    var coins = await getCoins();
    if (!isPremium && coins <= 0) {
      showNoCoinsDialog(context);
      return false;
    }
    return true;
  }

  /// Platform messages are asynchronous, so we initialize in an async method.
  Future isPluginSupport(GameType gameType) async {
    switch (gameType.name) {
      case "NES":
      case "GBA":
      case "GBC":
      case "SNES":
      case "MD":
      case "NEO":
      case "Wii":
      case "GC":
      case "N64":
      case "MAME":
      case "NDS":
      case "PSX":
      case "PSP":
      case "3DS":
      case "SWAN":
        return true;
      default:
        return false;
    }
  }

  /// Platform messages are asynchronous, so we initialize in an async method.
  Future<bool> isModuleInstalled(GameType? gameType) async {
    if (gameType == null) {
      return false;
    }
    return nativeIsPluginInstalled(gameType);
  }

  void showUpdateDialog(BuildContext context, GameType? gameType) {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: Text(S.of(context).Update_App),
              content: Text(S.of(context).Update_App_hint(gameType!.name!)),
              actions: <Widget>[
                TextButton(
                  child: Text(S.of(context).CANCEL, style: TextStyle(color: Colors.white54)),
                  onPressed: () => Navigator.of(context).pop(), //关闭对话框
                ),
                TextButton(
                  child: Text(S.of(context).OK, style: TextStyle(color: AppTheme.primary)),
                  onPressed: () {
                    LaunchReview.launch(androidAppId: pluginPackageName, iOSAppId: "585027354");
                  },
                ),
              ],
            ));
  }

  void showSetGameTypeDialog(BuildContext context, Game? game) async {
    var gameTypes = await DuckDao.getGameTypes();
    var gameGenres = await DuckDao.getGameGenres();
    showDialog(
        context: context,
        builder: (BuildContext context) => SimpleDialog(
              title: Text(S.of(context).ROMS_Type),
              children: gameTypes
                  .map((gameType) => SimpleDialogOption(
                        onPressed: () async {
                          game?.gameType = gameType;
                          game?.gameGenre = gameGenres[0];
                          var newRomPath = await DuckGame.instance.nativeSetGameType(game?.romLocalPath, gameType.name);
                          game?.romLocalPath = newRomPath;
                          await DuckDao.insertOrUpdateLocalGame(game!);
                          Navigator.of(context).pop();
                          eventBus.fire(RefreshLocalEvent());
                          // onPlayGame(context, game);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            gameType.name == null ? "Unknow" : gameType.name!,
                            style: TextStyle(color: AppTheme.mainText, fontSize: 16),
                          ),
                        ),
                      ))
                  .toList(),
            ));
  }

  void showGameBugDialog(BuildContext context, Game game, Function() onOkClick) {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: Text(S.of(context).Bug_Report + ": " + game.name! + "?"),
              content: Text(S.of(context).Bug_Report_Detail, style: TextStyle(height: 1.5)),
              actions: <Widget>[
                TextButton(
                  child: Text(S.of(context).CANCEL, style: TextStyle(color: Colors.white54)),
                  onPressed: () => Navigator.of(context).pop(), //关闭对话框
                ),
                TextButton(
                  child: Text(S.of(context).OK, style: TextStyle(color: AppTheme.primary)),
                  onPressed: () {
                    onOkClick.call();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ));
  }

  Future<void> legalDownloadRom(BuildContext context, Function callback) async {
    bool? agree = await DuckKV.readKey("is_agree_user_agreement");
    if (agree != null && agree) {
      callback.call();
    } else {
      showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
                title: Text(S.of(context).User_Agreement),
                content: SingleChildScrollView(
                  child: RichText(
                    text: TextSpan(children: [
                      TextSpan(text: S.of(context).user_agreement1),
                      TextSpan(
                        style: TextStyle(
                          color: Colors.blueAccent,
                        ),
                        text: "romsmania.cc \n",
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            launchURL("https://romsmania.cc/");
                          },
                      ),
                      TextSpan(
                        text: S.of(context).user_agreement2,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: S.of(context).user_agreement3,
                      ),
                    ]),
                  ),
                ),
                actions: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child: Text(S.of(context).Disagree, style: TextStyle(color: AppTheme.primary)),
                        onPressed: () => Navigator.of(context).pop(), //关闭对话框
                      ),
                      TextButton(
                        child: Text(S.of(context).Agree, style: TextStyle(color: AppTheme.primary)),
                        onPressed: () {
                          callback.call();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  TextButton(
                    child: Text(S.of(context).Agree_and_do_not_show_again, style: TextStyle(color: AppTheme.primary)),
                    onPressed: () {
                      DuckKV.saveKey("is_agree_user_agreement", true);
                      callback.call();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ));
    }
  }

  void showNoCoinsDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: Text(S.of(context).No_Coins),
              content: Text(S.of(context).A_coin_is_needed_to_start_the_game),
              actions: <Widget>[
                TextButton(
                  child: Text(S.of(context).CANCEL, style: TextStyle(color: Colors.white54)),
                  onPressed: () => Navigator.of(context).pop(), //关闭对话框
                ),
                TextButton(
                  child: Text(S.of(context).OK, style: TextStyle(color: AppTheme.primary)),
                  onPressed: () {
                    // new MaterialPageRoute(builder: (context) => new AboutPage())
                    Navigator.of(context).pop();
                    showModalBottomSheet<void>(
                      isScrollControlled: true,
                      context: context,
                      builder: (context) {
                        return Wrap(
                          children: [BuyCoinSheet()],
                        );
                      },
                    );
                  },
                ),
              ],
            ));
  }

  void showPremiumGameDialog(BuildContext context, GameType gameType) {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: Text(S.of(context).Premium_Only_Game(gameType.name!)),
              content: Text(
                S.of(context).Premium_Only_Game_hint,
                style: TextStyle(height: 1.5),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(S.of(context).CANCEL, style: TextStyle(color: Colors.white54)),
                  onPressed: () => Navigator.of(context).pop(), //关闭对话框
                ),
                TextButton(
                  child: Text(S.of(context).OK, style: TextStyle(color: AppTheme.primary)),
                  onPressed: () {
                    // new MaterialPageRoute(builder: (context) => new AboutPage())
                    Navigator.of(context).pop();
                    showModalBottomSheet<void>(
                      isScrollControlled: true,
                      context: context,
                      builder: (context) {
                        return Wrap(
                          children: [BuyCoinSheet(sku: "lifetime_premium")],
                        );
                      },
                    );
                  },
                ),
              ],
            ));
  }

  void showNotSupportDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: Text(S.of(context).Not_Supported_Game),
              content: Text(
                S.of(context).Not_Supported_Game_hint,
                style: TextStyle(height: 1.5),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(S.of(context).OK, style: TextStyle(color: AppTheme.primary)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ));
  }

  void showPlayOnMobileDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: Text(S.of(context).Not_Supported_Game),
              content: Text(
                "This game can only be played on mobile phones temporarily, please download the mobile app to play",
                style: TextStyle(height: 1.5),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text("GET APP", style: TextStyle(color: AppTheme.primary)),
                  onPressed: () {
                    launchURL("https://actduck.com/videogame");
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ));
  }

  Future<int> getCoins() async {
    int? coins = await DuckKV.readKey("my_coins");
    if (coins == null) {
      coins = 20;
      await DuckKV.saveKey("my_coins", coins);
    }
    return coins;
  }

  Future<int> addCoins(int coin) async {
    int? coins = await DuckKV.readKey("my_coins");
    if (coins == null) {
      coins = 10;
    }
    coins += coin;
    await DuckKV.saveKey("my_coins", coins);
    eventBus.fire(RefreshCoinsEvent());
    if (coins == 0) {
      LOG.D(_TAG, "addCoins: 解锁成就 没钱花了");
      GamesServices.unlock(achievement: Achievement(androidID: achievementIveGotNoCoins));
    }
    return coins;
  }

  void onNetPlayGame(BuildContext context, Game game) {
    showDialog<int>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return SimpleDialog(
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () {
                  onPlayGame(context, game, netplay: true, server: true);
                  Navigator.pop(context, 1);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.of(context).NetPlay_Server),
                      // Text(
                      //   S.of(context).Bug_Report_Detail,
                      //   style: TextStyle(
                      //     fontSize: 12,
                      //     color: AppTheme.secondText,
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  onPlayGame(context, game, netplay: true, server: false);
                  Navigator.pop(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.of(context).Connect_NetPlay),
                      // Text(
                      //   S.of(context).Bug_Report_Detail,
                      //   style: TextStyle(
                      //     fontSize: 12,
                      //     color: AppTheme.secondText,
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ],
          );
        });
  }

  static int lastPlayTime = 0;

  void onPlayGame(BuildContext context, Game? game, {bool netplay = false, bool server = false}) async {
    // 避免快速点击2次
    int now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastPlayTime < 1000) {
      lastPlayTime = now;
      LOG.W(_TAG, "onPlayGame: 点击太快歇一歇吧");
      return;
    }
    lastPlayTime = now;

    bool canPlay = await canPlayGame(context, game);
    if (!canPlay) {
      LOG.D(_TAG, "onPlayGame: 不能玩游戏" + game!.name!);
      return;
    }

    var hasModule = await isModuleInstalled(game?.gameType);
    if (!hasModule) {
      // showAddModuleDialog(context, gameType);
      Fluttertoast.showToast(msg: "Plugin is loading, please wait");
      _tryInstallPlugin(game!.gameType!);
      return;
    }

    LOG.D(_TAG, "onPlayGame: 玩游戏" + game!.name!);

    DuckAds.instance.showInterstitialAd(onAdFinish: () {
      //todo 暂时本地rom也要消耗费用吧，不然会有用户不付费了
      // if (game.localGame == false) {
      _costOneCoin();
      // }
      _nativePlay(game, netplay, server);

      var in1Config = DuckConfig.instance.getAdsConfig(AD_ADMOB_IN1);
      var in2Config = DuckConfig.instance.getAdsConfig(AD_ADMOB_IN2);

      int interval1 = 5000;
      int interval2 = 5000;
      if (in1Config != null && in1Config.interval != null) {
        interval1 = in1Config.interval!;
      }

      if (in2Config != null && in2Config.interval != null) {
        interval2 = in2Config.interval!;
      }
      LOG.D(_TAG, "延迟$interval1/$interval2 ms 加载广告1/2");
      Future.delayed(Duration(milliseconds: interval1), () {
        // 延时加载广告1
        DuckAds.instance.createInterstitialAd();
      });

      Future.delayed(Duration(milliseconds: interval2), () {
        // 延时加载广告2
        DuckAds.instance.createInterstitialAd2();
      });
    }, onAdShow: (ad) {
      AppRepo().reportAds(AdAnalytics.ad(ad, 1));
    }, onAdClick: (ad) {
      AppRepo().reportAds(AdAnalytics.ad(ad, 2));
    });
  }

  void _costOneCoin() async {
    var isPremium = await DuckBilling.instance.isPremium();
    if (!isPremium) {
      LOG.D(_TAG, "costOneCoin: 消耗一个币");
      addCoins(-1);
    }
  }

  static const _methodChannel = const MethodChannel('com.actduck.videogame/playgame_method');
  static const _eventChannel = const EventChannel('com.actduck.videogame/playgame_event');

  void makeStatus(Game game) {
    GamesServices.increment(achievement: Achievement(androidID: achievementBored, iOSID: 'ios_id', steps: 1));
    GamesServices.increment(
        achievement: Achievement(androidID: achievementReallyReallyBored, iOSID: 'ios_id', steps: 1));

    // 上报分数
    if (DuckUser.instance.userInfo != null) {
      AppRepo().saveHighScore(DuckUser.instance.userInfo).listen((data) {
        LOG.D(_TAG, "saveHighScore: 提交高分$data");
        GamesServices.submitScore(score: Score(androidLeaderboardID: leaderboardReadyPlayerOne, value: data));
      }, onError: (e) {});
    }

    // 增加游戏热度
    AppRepo().addGameHeat(game).listen((data) {
      LOG.D(_TAG, "addGameHeat: 增加游戏热度");
    }, onError: (e) {});
  }

  Future<void> _nativePlay(Game game, bool netPlay, bool server) async {
    _updateRecentGame(game);
    DuckAnalytics.analytics.logEvent(name: "native_play_game", parameters: <String, dynamic>{
      'game_name': game.name,
    });
    try {
      var map = game.toMap();
      map["netplay"] = netPlay;
      map["server"] = server;
      await _methodChannel.invokeMethod('playGame', map);
      makeStatus(game);
    } on PlatformException catch (e) {
      LOG.D(_TAG, "nativePlay: Failed to play Game: '${e.message}'.");
    }
  }

  // Future<String?> nativeGetUserInfo() async {
  //   try {
  //     return await _methodChannel.invokeMethod('getUserInfo');
  //   } on PlatformException catch (e) {
  //     LOG.D(_TAG, "nativeGetUserInfo: Error: '${e.message}'.");
  //     return null;
  //   }
  // }

  Future _tryInstallPlugin(GameType gameType) async {
    if (premiumGameType.contains(gameType.name)) {
      // 会员游戏 会员再加载
      if (await DuckBilling.instance.isPremium()) {
        nativeInstallPlugin(gameType);
      }
    } else {
      // 非premium游戏 就加载
      nativeInstallPlugin(gameType);
    }
  }

  Future nativeInstallPlugin(GameType gameType) async {
    DuckAnalytics.analytics.logEvent(name: "native_install_plugin", parameters: <String, dynamic>{
      'game_type_name': gameType.name,
    });
    try {
      return await _methodChannel.invokeMethod('installPlugin', gameType.toMap());
    } on PlatformException catch (e) {
      LOG.D(_TAG, "nativeInstallPlugin: Failed to install Plugin: '${e.message}'.");
    }
  }

  Future nativeRemovePlugin(GameType gameType) async {
    DuckAnalytics.analytics.logEvent(name: "native_remove_plugin", parameters: <String, dynamic>{
      'game_type_name': gameType.name,
    });
    try {
      return await _methodChannel.invokeMethod('removePlugin', gameType.toMap());
    } on PlatformException catch (e) {
      LOG.D(_TAG, "nativeInstallPlugin: Failed to install Plugin: '${e.message}'.");
    }
  }

  Future<bool> nativeIsPluginInstalled(GameType gameType) async {
    try {
      return await _methodChannel.invokeMethod('isPluginInstalled', gameType.toMap());
    } on PlatformException catch (e) {
      LOG.D(_TAG, "nativeIsPluginInstalled: Failed to install Plugin: '${e.message}'.");
      return Future.value(false);
    }
  }

  /// 先存储游戏到数据库，到时候就能取到最近的游戏了
  void _updateRecentGame(Game game) async {
    game.favorite = false;
    var localGame = await DuckDao.getLocalGame(game.id);
    if (localGame != null) {
      LOG.D(_TAG, "_updateRecentGame: 本地游戏喜欢${localGame.favorite}");
      game.favorite = localGame.favorite;
    }
    game.lastPlayTime = DateTime.now().millisecondsSinceEpoch.toString();
    // 这里要区分本地游戏和线上游戏
    if (game.localGame == true) {
      await DuckDao.insertOrUpdateLocalGame(game);
    } else {
      await DuckDao.insertOrUpdateGame(game);
    }

    eventBus.fire(RefreshRecentEvent());
  }

  void openDolphinSetting(BuildContext context) async {
    try {
      var inStalled = await isModuleInstalled(GameType.title(name: "GC"));
      if (!inStalled) {
        var msg = S.of(context).Plugin_not_avaible("GC/Wii");
        Fluttertoast.showToast(msg: msg);
        throw new Exception(msg);
      }
      await _methodChannel.invokeMethod('openDolphinSetting');
      DuckAds.instance.dontShowOpenAd();
    } on PlatformException catch (e) {
      LOG.D(_TAG, "openDolphinSetting: error: '${e.message}'.");
    }
  }

  void openN64Setting() async {
    try {
      await _methodChannel.invokeMethod('openN64Setting');
      DuckAds.instance.dontShowOpenAd();
    } on PlatformException catch (e) {
      LOG.D(_TAG, "openN64Setting: error: '${e.message}'.");
    }
  }

  void openNDSSetting() async {
    try {
      await _methodChannel.invokeMethod('openNDSSetting');
      DuckAds.instance.dontShowOpenAd();
    } on PlatformException catch (e) {
      LOG.D(_TAG, "openNDSSetting: error: '${e.message}'.");
    }
  }

  void openPluginSetting() async {
    try {
      var gameTypes = await DuckDao.getGameTypes();
      var s = "";
      gameTypes.forEach((element) {
        s += element.name! + " ";
      });
      await _methodChannel.invokeMethod('openPluginSetting', s);
      DuckAds.instance.dontShowOpenAd();
    } on PlatformException catch (e) {
      LOG.D(_TAG, "openPluginSetting: error: '${e.message}'.");
    }
  }

  void openCloudSavesSetting() async {
    try {
      await _methodChannel.invokeMethod('openCloudSaves');
      DuckAds.instance.dontShowOpenAd();
    } on PlatformException catch (e) {
      LOG.D(_TAG, "openCloudSaves: error: '${e.message}'.");
    }
  }

  Future unzipFile(Game game) async {
    var timeStart = new DateTime.now().millisecondsSinceEpoch;
    LOG.D(_TAG, 'onDownloadComplete 下载完成但是需要解压缩：${game.name}');
    eventBus.fire(UnzipGameEvent(game, 0, 1));

    await _prepare();
    String fileName = basename(game.zipUrl!);
    File zipFile =
        File(_localPath! + Platform.pathSeparator + game.gameType!.name! + Platform.pathSeparator + fileName);

    LOG.D(_TAG, 'unzipFile 解压文件${zipFile.absolute}');

    final destinationDir = Directory(_localPath! + Platform.pathSeparator + game.gameType!.name!);
    try {
      await ZipFile.extractToDirectory(
          zipFile: zipFile,
          destinationDir: destinationDir,
          onExtracting: (zipEntry, progress) {
            LOG.D(_TAG, 'unzipFile progress: ${progress.toStringAsFixed(1)}%');
            LOG.D(_TAG, 'unzipFile name: ${zipEntry.name}');
            LOG.D(_TAG, 'unzipFile isDirectory: ${zipEntry.isDirectory}');
            LOG.D(_TAG, 'unzipFile modificationDate: ${zipEntry.modificationDate!.toLocal().toIso8601String()}');
            LOG.D(_TAG, 'unzipFile uncompressedSize: ${zipEntry.uncompressedSize}');
            LOG.D(_TAG, 'unzipFile compressedSize: ${zipEntry.compressedSize}');
            LOG.D(_TAG, 'unzipFile compressionMethod: ${zipEntry.compressionMethod}');
            LOG.D(_TAG, 'unzipFile crc: ${zipEntry.crc}');
            return ZipFileOperation.includeItem;
          });
    } catch (e) {
      LOG.E(_TAG, e.toString());
      eventBus.fire(UnzipGameEvent(game, 0, 3));
    }
    eventBus.fire(UnzipGameEvent(game, 100, 2));
    LOG.D(_TAG, 'onDownloadComplete 解压完成 耗时：${new DateTime.now().millisecondsSinceEpoch - timeStart}ms');
  }

  bool is64Bit() {
    return androidInfo.supported64BitAbis.isNotEmpty;
  }

  void onDeleteGame(BuildContext context, Game game, Function() onDeleted) {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: Text(S.of(context).Delete_Game),
              content: Text(
                S.of(context).Delete_Game_hint,
                style: TextStyle(height: 1.5),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(S.of(context).CANCEL, style: TextStyle(color: Colors.white54)),
                  onPressed: () => Navigator.of(context).pop(), //关闭对话框
                ),
                TextButton(
                  child: Text(S.of(context).DELETE, style: TextStyle(color: Colors.red)),
                  onPressed: () async {
                    if (await _deleteRom(game)) {
                      onDeleted.call();
                      LOG.D(_TAG, "onDeleteGame: 删除成功");
                      Fluttertoast.showToast(msg: S.of(context).Delete_Success);
                    } else {
                      LOG.D(_TAG, "onDeleteGame: 删除失败，文件不存在");
                      Fluttertoast.showToast(msg: S.of(context).Delete_failed_File_not_exist);
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ));
  }

  void onDeleteDownloadTask(BuildContext context, Game game, Function() onDeleted) {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              // title: Text(S.of(context).Delete_Game),
              content: Text(
                S.of(context).Delete_Download_Task,
                style: TextStyle(height: 1.5),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(S.of(context).CANCEL, style: TextStyle(color: Colors.white54)),
                  onPressed: () => Navigator.of(context).pop(), //关闭对话框
                ),
                TextButton(
                  child: Text(S.of(context).DELETE, style: TextStyle(color: Colors.red)),
                  onPressed: () async {
                    if (await _deleteDownloadTask(game)) {
                      onDeleted.call();
                      LOG.D(_TAG, "onDeleteGame: 删除成功");
                      Fluttertoast.showToast(msg: S.of(context).Delete_Success);
                    } else {
                      LOG.D(_TAG, "onDeleteGame: 删除失败，文件不存在");
                      Fluttertoast.showToast(msg: S.of(context).Delete_failed_File_not_exist);
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ));
  }

  Future<bool> _deleteDownloadTask(Game game) async {
    var cacheDir = await getExternalCacheDirectories();
    if (cacheDir == null || cacheDir.isEmpty) {
      return false;
    }
    // 本地已有下载中的文件
    File zipRomFile = File(cacheDir[0].path + Platform.pathSeparator + basename(game.zipUrl!));
    if (await zipRomFile.exists()) {
      zipRomFile.delete(recursive: false);
      return true;
    }

    // 循环100次 把分片全删了
    for (int i = 0; i < 100; i++) {
      var splitFile =
          File(cacheDir[0].path + Platform.pathSeparator + basenameWithoutExtension(game.zipUrl!) + "_$i.part");
      splitFile.delete(recursive: false);
    }
    return true;
  }

  Future<bool> _deleteRom(Game game) async {
    await _prepare();

    String fileName = basename(game.url!);
    File rom = File(_localPath! + Platform.pathSeparator + game.gameType!.name! + Platform.pathSeparator + fileName);
    var exist = await rom.exists();
    if (exist) {
      rom.delete(recursive: false);
      return true;
    } else {
      return false;
    }
  }

  void prepareSthByGameType(GameType? gameType) async {
    if (gameType != null) {
      if (gameType.name == "MAME" || gameType.name == "NEO") {
        nativeDownloadBios();
      }
      if (gameType.name == "NDS") {
        _nativePrepareNDS();
      }
    }
  }

  void nativeDownloadBios() async {
    try {
      var result = await _methodChannel.invokeMethod('downloadBios');
      LOG.D(_TAG, "nativeDownloadBios: success: $result.");
    } on PlatformException catch (e) {
      LOG.D(_TAG, "nativeDownloadBios: error: '${e.message}'.");
      DuckAnalytics.analytics.logEvent(name: "app_error", parameters: <String, dynamic>{
        'error_name': "nativeDownloadBios",
        'error_message': e.message,
      });
    }
  }

  Future<void> scanRoms(bool isFolder) async {
    try {
      DuckAds.instance.dontShowOpenAd();
      var result = await _methodChannel.invokeMethod('scanRoms', isFolder);
      var scanRomResult = ScanRomResult.fromJson(json.decode(result));

      var games = scanRomResult.games;

      LOG.D(_TAG, "scanRoms: success: $games.");

      if (games != null) {
        for (var game in games) {
          await addLocalRom(game);
        }
      }
    } on PlatformException catch (e) {
      LOG.D(_TAG, "scanRoms: error: '${e.message}'.");
    }
  }

  Future<void> addLocalRom(Game game) async {
    // id = 0 会插不进数据
    game.id = null;
    var dbGame = await DuckDao.getLocalGameByName(game.name);
    if (dbGame != null) {
      game.id = dbGame.id;
    }
    if (game.gameType != null && game.gameType!.name!.isNotEmpty) {
      var gameType = await DuckDao.getGameTypeByName(game.gameType!.name);
      game.gameType = gameType;
    }
    LOG.D(_TAG, "addOneLocalRom: 添加了一个游戏：$game");
    await DuckDao.insertOrUpdateLocalGame(game);
  }

  /// 准备文件夹
  void prePareLocalRomsDir() async {
    LOG.D(_TAG, "prePareLocalRomsDir: 创建ROMs目录");
    var dir = (await _findLocalPath()) + Platform.pathSeparator + 'local-rom';
    var gameTypes = await DuckDao.getGameTypes();
    for (var gameType in gameTypes) {
      final savedDir = Directory(dir + Platform.pathSeparator + gameType.name!);
      bool hasExisted = await savedDir.exists();
      if (!hasExisted) {
        savedDir.create(recursive: true);
      }
    }
    _nativeDownloadGameDB();
  }

  void downloadRoms(Game game) {
    _tryInstallPlugin(game.gameType!);
    _nativeDownloadRoms(game);
  }

  void pauseDownload(Game game) {
    _nativePauseDownloadRoms(game);
  }

  /// 扫描本地目录下的rom Android11 以上用
  @Deprecated("现在支持其他文件夹了，不用这个方法 用ScanRoms")
  Future<List<Game>> nativeScanInnerDirRoms() async {
    try {
      DuckAds.instance.dontShowOpenAd();
      var result = await _methodChannel.invokeMethod('scanInnerRoms');
      var scanRomResult = ScanRomResult.fromJson(json.decode(result));

      var games = scanRomResult.games;

      LOG.D(_TAG, "nativeScanInnerDirRoms: success: $games.");

      if (games != null) {
        for (var game in games) {
          await addLocalRom(game);
        }
        return games;
      }
      return [];
    } on PlatformException catch (e) {
      LOG.D(_TAG, "nativeScanInnerDirRoms: error: '${e.message}'.");
      return [];
    }
  }

  Future<String?> nativeSetGameType(String? romLocalPath, String? newGameType) async {
    try {
      Map<String, String?> map = {
        "romLocalPath": romLocalPath,
        "newGameType": newGameType,
      };
      var result = await _methodChannel.invokeMethod('setGameType', map);

      LOG.D(_TAG, "nativeSetGameType: success: $result.");

      return result;
    } on PlatformException catch (e) {
      LOG.D(_TAG, "nativeSetGameType: error: '${e.message}'.");
      return romLocalPath;
    }
  }

  // void nativeOnDownloadComplete(TaskInfo task) async {
  //   try {
  //     Map<String, String?> map = {
  //       "link": task.link,
  //       "gameTypeName": task.gameTypeName,
  //     };
  //     var result = await _methodChannel.invokeMethod('onDownloadComplete', map);
  //
  //     LOG.D(_TAG, "nativeOnDownloadComplete: success: $result.");
  //   } on PlatformException catch (e) {
  //     LOG.D(_TAG, "nativeOnDownloadComplete: error: '${e.message}'.");
  //   }
  // }

  void _nativePrepareNDS() async {
    try {
      var result = await _methodChannel.invokeMethod('prepareNDS');

      LOG.D(_TAG, "nativePrepareNDS: success: $result.");
    } on PlatformException catch (e) {
      LOG.D(_TAG, "nativePrepareNDS: error: '${e.message}'.");
    }
  }

  void _nativeDownloadGameDB() async {
    try {
      var result = await _methodChannel.invokeMethod('downloadGameDB');

      LOG.D(_TAG, "downloadGameDB: success: $result.");
    } on PlatformException catch (e) {
      LOG.D(_TAG, "downloadGameDB: error: '${e.message}'.");
    }
  }

  void _nativeDownloadRoms(Game game) async {
    try {
      var result = await _methodChannel.invokeMethod('downloadRoms', game.toMap());

      LOG.D(_TAG, "DownloadRoms: success: $result.");
    } on PlatformException catch (e) {
      LOG.D(_TAG, "DownloadRoms: error: '${e.message}'.");
    }
  }

  void _nativePauseDownloadRoms(Game game) async {
    try {
      var result = await _methodChannel.invokeMethod('pauseDownloadRoms', game.toMap());

      LOG.D(_TAG, "pauseDownloadRoms: success: $result.");
    } on PlatformException catch (e) {
      LOG.D(_TAG, "pauseDownloadRoms: error: '${e.message}'.");
    }
  }

  void showMsgDialog(BuildContext context, String title, String content) {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: Text(title),
              content: Text(content),
              actions: <Widget>[
                TextButton(
                  child: Text(S.of(context).OK, style: TextStyle(color: AppTheme.primary)),
                  onPressed: () => Navigator.of(context).pop(), //关闭对话框
                ),
              ],
            ));
  }
}
