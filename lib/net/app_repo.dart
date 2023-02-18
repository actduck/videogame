import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:videogame/db/db.dart';
import 'package:videogame/logger.dart';
import 'package:videogame/model/ad_analytics.dart';
import 'package:videogame/model/duck_account.dart';
import 'package:videogame/model/game.dart';
import 'package:videogame/model/game_type.dart';
import 'package:videogame/util/duck_ads.dart';
import 'package:videogame/util/duck_user.dart';

import '../util/duck_analytics.dart';
import '../util/duck_kv.dart';
import 'api.dart';
import 'api_service.dart';

class AppRepo {
  static final String _TAG = "AppRepo";
  static final AppRepo _singleton = AppRepo._internal();

  factory AppRepo() {
    return _singleton;
  }

  AppRepo._internal();

  ApiService apiService = ApiService();

  ///加载游戏列表
  Stream<List<GameType>> gameType() {
    var stream = Stream.fromFutures([
      DuckDao.getGameTypes(),
      apiService.get(Api.GAME_TYPE).then((value) {
        var gameTypes = gameTypeFromJson(jsonEncode(value));
        gameTypes.forEach((gameType) {
          DuckDao.insertOrUpdateGameType(gameType);
        });
        return gameTypes;
      })
    ]);
    return stream.where((list) => list.length > 0).distinct((list1, list2) {
      return listEquals(list1, list2);
    });
  }

  ///加载游戏列表
  Stream gameGenre() {
    return Stream.fromFuture(apiService.get(Api.GAME_GENRE));
  }

  int lastSaveGameTime = 0;

  ///根据游戏类型加载加载游戏列表
  Stream<GamePage> gameList(int page, int? typeId,
      {String? sortBy = null, String? sortLetter = null, String? sortDirection = null}) {
    // var completer = new Completer<GamePage>();
    // DuckDao.getGamesByTypeId(page, typeId).then((content) {
    //   completer.complete(GamePage(content: content, totalElements: content.length));
    // });
    // todo 缓存
    return Stream.fromFuture(apiService.get(Api.GAME_LIST, params: {
      'page': page,
      'typeId': typeId,
      'sort': sortBy,
      'letter': sortLetter,
      'direction': sortDirection
    }).then((value) {
      var gamePageNet = GamePage.fromJson(value);
      DuckDao.insertOrUpdateGames(gamePageNet.content!.cast());
      return gamePageNet;
    }));
  }

  ///随机5游戏
  Stream topGames() {
    return Stream.fromFuture(apiService.get(Api.TOP_GAMES));
  }

  ///编辑精选
  Stream editorChoiceGames() {
    return Stream.fromFuture(apiService.get(Api.EDITOR_CHOICE_GAME));
  }

  ///随机30游戏
  Stream guessYouLike() {
    return Stream.fromFuture(apiService.get(Api.GUESS_YOU_LIKE));
  }

  ///排行榜游戏
  Stream topChartsGames(int page) {
    return Stream.fromFuture(apiService.get(Api.TOP_CHARTS_GAMES, params: {'page': page}));
  }

  ///排行榜新游戏
  Stream topGrossingGames(int page) {
    return Stream.fromFuture(apiService.get(Api.TOP_GROSSING_GAMES, params: {'page': page}));
  }

  ///最新添加的游戏
  Stream newGames() {
    return Stream.fromFuture(apiService.get(Api.NEW_GAMES));
  }

  ///随机一个游戏
  Stream loadGame() {
    return Stream.fromFuture(apiService.get(Api.RANDOM_GAME));
  }

  ///给游戏点赞
  Stream like(int? id) {
    return Stream.fromFuture(apiService.post(Api.LIKE, params: {'id': id}));
  }

  ///根据关键字搜索游戏
  Stream searchGames(String? keywords, int page) {
    return Stream.fromFuture(apiService.post(Api.SEARCH_GAMES, params: {'keywords': keywords, 'page': page}));
  }

  ///获取用户信息
  Stream getUserInfo(DuckAccount? ga) {
    return Stream.fromFuture(apiService.post(Api.USER_INFO, params: {
      'displayName': ga?.displayName,
      'email': ga?.email,
      'googleId': ga?.googleId,
      'photoUrl': ga?.photoUrl
    }));
  }

  ///删除用户信息
  Stream deleteUser(DuckAccount? ga) {
    return Stream.fromFuture(apiService.delete(Api.DELETE_USER, params: {
      'displayName': ga?.displayName,
      'email': ga?.email,
      'googleId': ga?.googleId,
      'photoUrl': ga?.photoUrl
    }));
  }

  ///保存高分
  Stream saveHighScore(DuckAccount? ga) {
    return Stream.fromFuture(apiService.post(Api.SUBMIT_HIGH_SCORE, params: {
      'googleId': ga?.googleId,
    }));
  }

  ///增加游戏热度
  Stream addGameHeat(Game game) {
    return Stream.fromFuture(apiService.post(Api.ADD_GAME_HEAT, params: {
      'id': game.id,
    }));
  }

  ///广告分析
  reportAds(AdAnalytics analytics) async {
    analytics.userId = DuckUser.instance.userInfo?.id;
    analytics.userPseudoId = DuckAnalytics.userPseudoId;
    analytics.userIP = DuckAnalytics.localId;
    analytics.date = DateTime.now();
    LOG.D(_TAG, "onReportAdEvent: 上报广告: $analytics");

    var localAn = await DuckDao.insertOrUpdateAdAnalytics(analytics);
    DuckAds.instance.refreshSingleAdShowAndInterval(analytics.adFormat!);

    Stream.fromFuture(apiService.post(Api.REPORT_ADS, data: analytics.toMap())).listen((event) {
      localAn.uploaded = true;
      DuckDao.insertOrUpdateAdAnalytics(localAn);
    });
  }

  ///remove
  Stream removeGame(int id) {
    return Stream.fromFuture(apiService.post(Api.REMOVE, params: {'id': id}));
  }

  ///验证付款
  Stream verifyPurchase(packageName, productId, purchaseToken) {
    return Stream.fromFuture(apiService.post(Api.VERIFY_PURCHASE,
        params: {'packageName': packageName, 'productId': productId, 'purchaseToken': purchaseToken}));
  }

  void reportHistory1DayAds() async {
    var list = await DuckDao.getNotUploadedReports(
        DateTime.fromMicrosecondsSinceEpoch(DateTime.now().millisecondsSinceEpoch - (24 * 3600 * 1000)));
    LOG.D(_TAG, "reportHistory1DayAds 个数: ${list.length}");
    list.forEach((element) {
      Stream.fromFuture(apiService.post(Api.REPORT_ADS, data: element.toMap())).listen((event) {
        element.uploaded = true;
        DuckDao.insertOrUpdateAdAnalytics(element);
      });
    });
  }

  Future<List<AdAnalytics>> getAdsClickTimesToday(int adFormat) {
    DateTime dateToday = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return DuckDao.getAdsClickTimes(adFormat, dateToday);
  }
}
