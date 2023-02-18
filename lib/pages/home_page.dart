import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:videogame/app_theme.dart';
import 'package:videogame/common/error_view.dart';
import 'package:videogame/common/loading_status.dart';
import 'package:videogame/common/loading_view.dart';
import 'package:videogame/common/platform_adaptive_progress_indicator.dart';
import 'package:videogame/db/db.dart';
import 'package:videogame/logger.dart';
import 'package:videogame/model/ad_analytics.dart';
import 'package:videogame/model/game.dart';
import 'package:videogame/model/game_genre.dart';
import 'package:videogame/model/game_type.dart';
import 'package:videogame/model/list_item.dart';
import 'package:videogame/net/api.dart';
import 'package:videogame/net/app_repo.dart';
import 'package:videogame/pages/base_game_list_page.dart';
import 'package:videogame/pages/game_info_page.dart';
import 'package:videogame/pages/game_list_page.dart';
import 'package:videogame/pages/search_page.dart';
import 'package:videogame/parallax.dart';
import 'package:videogame/util/duck_ads.dart';
import 'package:videogame/util/duck_analytics.dart';
import 'package:videogame/util/duck_game.dart';
import 'package:videogame/widget/game_list_view.dart';
import 'package:videogame/widget/game_list_view_medium.dart';
import 'package:videogame/widget/loading_more_view.dart';

import '../generated/l10n.dart';

const String testDevice = '';

class HomePage extends BaseGameListPage {
  HomePage();

  @override
  _HomePageState createState() => new _HomePageState();
}

Map<GameType, GamePage?> gameMaps = new Map<GameType, GamePage?>();

class _HomePageState extends BaseGameListState with GameListMixin {
  static final String _TAG = "_HomePageState";

  List<GameType> gameTypes = [];
  List<ListItem>? topGames = [];

  bool _nativeAdLoaded = false;
  List<ListItem>? editorChoiceGames = [];
  List<ListItem>? popularGames = [];
  List<Game>? newGames = [];

  List<ListItem> topChartGames = [];
  List<ListItem> topGrossingGames = [];
  int pageGrossing = 1;
  GamePage? pageChart = null;
  int gamePart = 5;

  // bool? lastChart = false;
  bool? lastGrossing = false;
  bool loadingMoreGrossing = false;
  bool loadingMoreChart = false;

  bool _adEditorAdded = false;
  bool _adPopularAdded = false;

  Game? previousGame;
  Game? bannerGame;
  final ValueNotifier<Game?> _bannerNotifier = ValueNotifier(null);

  AppRepo appRepo = new AppRepo();
  late LoadingStatus loadingState;

  ScrollController controller = new ScrollController();

  bool topChartSelect = true;

  @override
  void initState() {
    super.initState();

    DuckAnalytics.analytics.setCurrentScreen(
      screenName: 'HomePage',
    );

    DuckAnalytics.instance.setUp();
    LOG.D(_TAG, "DuckAnalytics 设置完毕");
    DuckAds.instance.setNativeAd1Params(
      onAdLoaded: () {
        LOG.D(_TAG, "DuckAnalytics 原生广告加载完毕");
        _nativeAdLoaded = true;
      },
      onAdShow: (ad) {
        appRepo.reportAds(AdAnalytics.ad(ad, 1));
      },
      onAdClick: (ad) {
        appRepo.reportAds(AdAnalytics.ad(ad, 2));
      },
    );
    DuckAds.instance.setNativeAd2Params(
      onAdShow: (ad) {
        appRepo.reportAds(AdAnalytics.ad(ad, 1));
      },
      onAdClick: (ad) {
        appRepo.reportAds(AdAnalytics.ad(ad, 2));
      },
    );

    controller.addListener(() {
      if (controller.position.pixels + 100 >= controller.position.maxScrollExtent &&
          pageChart?.last == false &&
          !loadingMoreChart &&
          loadingState != LoadingStatus.loading) {
        if (topChartSelect) {
          var nextPage = pageChart!.number! + 1 + 1;

          loadTopCharts(nextPage);
          print("加载更多Charts$nextPage");
        }
      }
    });

    controller.addListener(() {
      if (controller.position.pixels == controller.position.maxScrollExtent &&
          !lastGrossing! &&
          loadingState != LoadingStatus.loading) {
        if (!topChartSelect) {
          pageGrossing++;
          loadTopGrossing();
          print("加载更多Grossing$pageGrossing");
        }
      }
    });

    _initData();

    myInterval(Duration(seconds: 8)).listen((data) {
      previousGame = bannerGame;
      if (mounted) {
        loadBannerGame();
      }
    });
  }

  void _initData() {
    pageGrossing = 1;
    // pageChart = 1;
    topChartGames.clear();
    topGrossingGames.clear();
    _adEditorAdded = false;
    _adPopularAdded = false;

    loadGameType(true);
    loadGameGenre();
    loadBannerGame();
    loadTopGame();
    loadNewGame();
    loadEditorChoiceGame();
    loadPopularGame();
    loadTopCharts(1);
    loadTopGrossing();
  }

  /// 开始加载游戏列表
  loadGames(GameType gameType, int page) async {
    LOG.D(_TAG, "loadGames 参数：${gameType.name} $page");
    appRepo.gameList(page, gameType.id).listen((gp) {
      setState(() {
        gameType.total = gp.totalElements;
        var oldGp = gameMaps[gameType];
        // gp.content = DuckAds.instance.addNativeAd1(oldGp == null ? 0 : oldGp.content!.length, gp.content!);
        if (oldGp == null) {
          gameMaps[gameType] = gp;
        } else {
          oldGp.content?.addAll(gp.content!);
          gp.content = oldGp.content;
          gameMaps[gameType] = gp;
        }
      });
    }, onError: (e) {
      print(e);
    });
  }

  loadGameType(bool refresh) async {
    loadingState = LoadingStatus.loading;
    var time0 = new DateTime.now().millisecondsSinceEpoch;
    appRepo.gameType().listen((data) {
      if (data.length == 0) {
        LOG.D(_TAG, "loadGameType db数据是空 return");
        return;
      }
      setState(() {
        var i = new DateTime.now().millisecondsSinceEpoch - time0;
        LOG.D(_TAG, "loadGameType 耗时: ${i}ms");
        gameTypes.clear();
        gameMaps.clear();

        gameTypes = data;
        gameTypes.forEach((gameType) {
          loadGames(gameType, 1);
        });
        loadingState = LoadingStatus.success;
      });
    }, onError: (e) {
      setState(() {
        loadingState = LoadingStatus.error;
      });
      print(e);
    });
  }

  loadGameGenre() async {
    appRepo.gameGenre().listen((data) {
      setState(() {
        var gameGenres = gameGenreFromJson(jsonEncode(data));
        gameGenres.forEach((gameGenre) {
          DuckDao.insertOrUpdateGameGenre(gameGenre);
        });
      });
    }, onError: (e) {
      print(e);
    });
  }

  loadBannerGame() async {
    appRepo.loadGame().listen((data) {
      if (mounted && data != null) {
        bannerGame = Game.fromMap(data);
        if (previousGame == null) {
          previousGame = bannerGame;
        }
        _bannerNotifier.value = bannerGame!;
      }
    }, onError: (e) {});
  }

  loadTopGame() async {
    appRepo.topGames().listen((data) {
      setState(() {
        topGames!.clear();

        GamePage gp = GamePage.fromJson(data);
        topGames = gp.content;
      });
    }, onError: (e) {});
  }

  loadEditorChoiceGame() async {
    appRepo.editorChoiceGames().listen((data) {
      setState(() {
        editorChoiceGames!.clear();

        GamePage gp = GamePage.fromJson(data);
        editorChoiceGames = gp.content;
      });
    }, onError: (e) {});
  }

  loadPopularGame() async {
    appRepo.editorChoiceGames().listen((data) {
      setState(() {
        popularGames!.clear();

        GamePage gp = GamePage.fromJson(data);
        popularGames = gp.content;
      });
    }, onError: (e) {});
  }

  loadNewGame() async {
    appRepo.newGames().listen((data) {
      setState(() {
        newGames!.clear();

        GamePage gp = GamePage.fromJson(data);
        newGames = gp.content?.cast<Game>();
      });
    }, onError: (e) {});
  }

  loadTopCharts(int page) async {
    setState(() {
      loadingMoreChart = true;
    });

    appRepo.topChartsGames(page).listen((data) {
      setState(() {
        GamePage gp = GamePage.fromJson(data);

        topChartGames.addAll(gp.content!);

        pageChart = gp;
        loadingMoreChart = false;
      });
    }, onError: (e) {
      setState(() {
        loadingMoreChart = false;
      });
    });
  }

  loadTopGrossing() async {
    setState(() {
      loadingMoreGrossing = true;
    });

    appRepo.topGrossingGames(pageGrossing).listen((data) {
      setState(() {
        GamePage gp = GamePage.fromJson(data);

        topGrossingGames.addAll(gp.content!);

        lastGrossing = gp.last;
        loadingMoreGrossing = false;
      });
    }, onError: (e) {
      setState(() {
        loadingMoreGrossing = false;
      });
    });
  }

  void _tryAddEditorAd() {
    if (_adEditorAdded) {
      return;
    }
    LOG.D(_TAG, "_tryAddEditorAd 开始添加编辑广告");

    if (_nativeAdLoaded) {
      setState(() {
        editorChoiceGames = DuckAds.instance.addNativeAd1(0, editorChoiceGames!);
        _adEditorAdded = true;
        LOG.D(_TAG, "_tryAddEditorAd 添加广告成功");
      });
    }
  }

  void _tryAddPopularAd() {
    if (_adPopularAdded) {
      return;
    }
    LOG.D(_TAG, "_tryAddPopularAd 开始添加热门广告");

    if (_nativeAdLoaded) {
      setState(() {
        popularGames = DuckAds.instance.addNativeAd1(0, popularGames!);
        LOG.D(_TAG, "_tryAddPopularAd 添加广告成功");
        _adPopularAdded = true;
      });
    }
  }

  Future<Null> pullToRefresh() async {
    await Future.delayed(new Duration(seconds: 1));

    _initData();
    return null;
  }

  @override
  void dispose() {
    controller.dispose();
    DuckAds.instance.disposeNativeAd1();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        body: LoadingView(
            status: loadingState,
            loadingContent: Center(child: const PlatformAdaptiveProgressIndicator()),
            errorContent: ErrorView(
              description: S.of(context).Oops_an_error_occurred,
              onRetry: () {
                setState(() {
                  _initData();
                });
              },
            ),
            successContent: CustomScrollView(
              controller: controller,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: <Widget>[
                CupertinoSliverRefreshControl(
                  onRefresh: pullToRefresh,
                ),

                /// 随机1游戏
                buildAppBarUI(context),

                /// 搜索框
                buildSearchBarUI(),

                /// 随机8游戏
                if (topGames!.length > 0)
                  SliverToBoxAdapter(
                      child: UIGameSystemSmall(
                          GameType.title(
                            name: S.of(context).suggested_for_you,
                          ),
                          GamePage(content: topGames, last: true),
                          false)),
                // buildCategoryUI(),
                /// 分类游戏
                SliverToBoxAdapter(
                  child: Column(
                    children: getGamesUI(1),
                  ),
                ),

                /// 编辑精选游戏
                if (editorChoiceGames!.length > 0)
                  SliverToBoxAdapter(
                      child: UIGameSystemMedium(
                          GameType(name: S.of(context).editor_choice, icon: Icons.verified_rounded),
                          GamePage(content: editorChoiceGames, last: true),
                          false,
                          _tryAddEditorAd)),

                /// 编辑精选游戏
                if (popularGames!.length > 0)
                  SliverToBoxAdapter(
                      child: UIGameSystemMedium(
                          GameType.title(
                            name: S.of(context).popular_games,
                          ),
                          GamePage(content: popularGames, last: true),
                          false,
                          _tryAddPopularAd)),

                SliverToBoxAdapter(
                  child: Column(
                    children: getGamesUI(2),
                  ),
                ),

                /// 新游戏
                if (newGames!.isNotEmpty)
                  SliverToBoxAdapter(
                    child: buildTitleItem(
                        false,
                        GameType.title(
                          name: S.of(context).new_games,
                        )),
                  ),
                for (Game game in newGames!)
                  SliverToBoxAdapter(
                    child: LocationListItem(
                      imageUrl: game.photo!,
                      name: game.name!,
                      summary: game.summary!,
                      onTap: () {
                        DuckAnalytics.analytics
                            .logEvent(name: "new_game_click", parameters: <String, dynamic>{'game_name': game.name});

                        moveToGame(game);
                      },
                    ),
                  ),

                /// 排行榜标题
                if (topChartGames.isNotEmpty || topGrossingGames.isNotEmpty)
                  SliverToBoxAdapter(
                    child: buildTitleItem(
                        false,
                        GameType.title(
                          name: S.of(context).trending,
                        )),
                  ),

                /// 切换tab
                if (topChartGames.isNotEmpty || topGrossingGames.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                          image: DecorationImage(
                        image: topChartSelect
                            ? AssetImage("assets/images/bg_top_charts.png")
                            : AssetImage("assets/images/bg_top_grossing.png"),
                        fit: BoxFit.fill,
                      )),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          InkWell(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                S.of(context).top_charts,
                                style: TextStyle(
                                    fontSize: 16, fontWeight: topChartSelect ? FontWeight.bold : FontWeight.normal),
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                topChartSelect = true;
                              });
                            },
                          ),
                          InkWell(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Text(
                                  S.of(context).top_grossing,
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: !topChartSelect ? FontWeight.bold : FontWeight.normal),
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  topChartSelect = false;
                                });
                              }),
                        ],
                      ),
                    ),
                  ),
                if (topChartSelect)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        ListItem li = topChartGames[index];
                        return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: getRankBg(index),
                            ),
                            child: onBuildListItem(li, ranking: index + 1));
                      },
                      childCount: topChartGames.length,
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        ListItem li = topGrossingGames[index];
                        return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: getRankBg(index),
                            ),
                            child: onBuildListItem(li, ranking: index + 1));
                      },
                      childCount: topGrossingGames.length,
                    ),
                  ),

                /// 加载更多
                SliverToBoxAdapter(
                  child: LoadingMoreView(topChartSelect ? loadingMoreChart : loadingMoreGrossing),
                )
              ],
            )));
  }

  var linearGradient1 = LinearGradient(
      colors: [Color(0xFFc481fa), Color(0xffa578f8)], begin: Alignment.topCenter, end: Alignment.bottomCenter);

  var linearGradient2 = LinearGradient(
      colors: [Color(0xffa578f8), Color(0xff8c6ef3)], begin: Alignment.topCenter, end: Alignment.bottomCenter);

  var linearGradient3 = LinearGradient(
      colors: [Color(0xff8c6ef3), Color(0xff5f61ee)], begin: Alignment.topCenter, end: Alignment.bottomCenter);

  var linearGradient4 = LinearGradient(
      colors: [Color(0xff5f61ee), Color(0xff5f61ee)], begin: Alignment.topCenter, end: Alignment.bottomCenter);

  getRankBg(int index) {
    var linearGradient;
    if (index == 0) {
      linearGradient = linearGradient1;
    } else if (index == 1) {
      linearGradient = linearGradient2;
    } else if (index == 2) {
      linearGradient = linearGradient3;
    } else {
      linearGradient = linearGradient4;
    }
    return linearGradient;
  }

  List<Widget> getGamesUI(int part) {
    List<Widget> list = [];
    if (part == 1) {
      var values = gameMaps.values.toList();
      for (int i = 0; i < [values.length, gamePart].reduce(min); i++) {
        if (values[i]!.content!.length > 0) {
          list.add(UIGameSystemSmall(gameMaps.keys.toList()[i], values[i], true));
        }
      }
    }
    if (part == 2) {
      var values = gameMaps.values.toList();
      for (int i = gamePart; i < [values.length, gamePart].reduce(max); i++) {
        if (values[i]!.content!.length > 0) {
          list.add(UIGameSystemSmall(gameMaps.keys.toList()[i], values[i], true));
        }
      }
    }
    return list;
  }

  // Widget buildCategoryUI() {
  //   return SliverPadding(
  //     padding: const EdgeInsets.all(8.0),
  //     sliver: SliverGrid(
  //       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
  //         crossAxisCount: 2,
  //         mainAxisSpacing: 8,
  //         crossAxisSpacing: 8,
  //         childAspectRatio: 1,
  //       ),
  //       delegate: SliverChildBuilderDelegate(
  //         (BuildContext context, int index) {
  //           // 把json转成类
  //           var gameType = gameTypes[index];
  //           return _GameTypeItem(gameType: gameType);
  //         },
  //         childCount: gameTypes.length,
  //       ),
  //     ),
  //   );
  // }

  Widget buildAppBarUI(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160,
      flexibleSpace: FlexibleSpaceBar(
        background: ValueListenableBuilder<Game?>(
          builder: (context, game, child) {
            return buildBannerUI(game);
          },
          valueListenable: _bannerNotifier,
        ),
      ),
      actions: <Widget>[
        uiDownloadBt()
        // IconButton(
        //   icon: Icon(Icons.star),
        //   onPressed: () {
        //     Navigator.push(context,
        //         new MaterialPageRoute(builder: (context) => new ReviewPage()));
        //   },
        // ),
        // IconButton(
        //   icon: Icon(Icons.info_outline),
        //   onPressed: () {
        //     Navigator.push(context,
        //         new MaterialPageRoute(builder: (context) => new AboutPage()));
        //   },
        // ),
      ],
    );
  }

  Widget buildBannerUI(Game? bannerGame) {
    return bannerGame == null
        ? Center(child: const PlatformAdaptiveProgressIndicator())
        : InkWell(
            onTap: () {
              // loadGGInterstitialAd();

              DuckAnalytics.analytics
                  .logEvent(name: "home_banner_click", parameters: <String, dynamic>{'game_name': bannerGame.name});

              moveToGame(bannerGame);
            },
            child: CachedNetworkImage(
              imageUrl: Api.HOST + bannerGame.photo!,
              placeholder: (context, url) => previousGame == null
                  ? placeHolderImage
                  : CachedNetworkImage(imageUrl: Api.HOST + previousGame!.photo!, fit: BoxFit.cover),
              fit: BoxFit.cover,
            ),
          );
  }

  Widget UIGameSystemSmall(GameType gameType, GamePage? gamePage, bool showMore) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        buildTitleItem(showMore, gameType),
        GameListView(
          gamePage: gamePage,
          onGameClick: (game) {
            moveToGame(game);
            DuckAnalytics.analytics
                .logEvent(name: "home_game_small_click", parameters: <String, dynamic>{'game_name': game.name});
          },
          onLongPress: (game) {
            DuckGame.instance.onPlayGame(context, game);
            DuckAnalytics.analytics
                .logEvent(name: "home_game_small_long_press", parameters: <String, dynamic>{'game_name': game.name});
          },
          onLoadMore: (num) {
            loadGames(gameType, num + 1 + 1);
          },
        ),
      ],
    );
  }

  Widget UIGameSystemMedium(GameType gameType, GamePage? gamePage, bool showMore, Function? onAddAd) {
    var controller = new ScrollController();
    controller.addListener(() {
      if (controller.position.pixels > 648) {
        onAddAd?.call();
        LOG.D(_TAG, "需要添加原生广告1");
      }
    });
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        buildTitleItem(showMore, gameType),
        GameListViewMedium(
          gamePage: gamePage,
          controller: controller,
          onGameClick: (game) {
            moveToGame(game);
            DuckAnalytics.analytics
                .logEvent(name: "home_game_medium_click", parameters: <String, dynamic>{'game_name': game.name});
          },
          onLongPress: (game) {
            DuckGame.instance.onPlayGame(context, game);
            DuckAnalytics.analytics
                .logEvent(name: "home_game_medium_long_press", parameters: <String, dynamic>{'game_name': game.name});
          },
          onLoadMore: (num) {
            loadGames(gameType, num + 1 + 1);
          },
        ),
      ],
    );
  }

  Widget buildTitleItem(bool showMore, GameType gameType) {
    return InkWell(
      onTap: showMore ? () => {moveToGameList(gameType)} : null,
      child: Padding(
        padding: const EdgeInsets.only(top: 12.0, bottom: 12.0, left: 16, right: 16),
        child: Row(
          children: [
            if (gameType.icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(
                  gameType.icon,
                  color: AppTheme.secondText,
                ),
              ),
            Expanded(
              child: Text(
                gameType.total == null ? gameType.name! : '${gameType.name!}(${gameType.total})',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  letterSpacing: 0.27,
                  color: AppTheme.secondText,
                ),
              ),
            ),
            if (showMore)
              Icon(
                Icons.arrow_forward_rounded,
                color: AppTheme.secondText,
              )
          ],
        ),
      ),
    );
  }

  Widget buildSearchBarUI() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.only(top: 8, left: 16, right: 16),
        height: 48,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(40.0)),
            onTap: () {
              DuckAnalytics.analytics.logEvent(name: "home_searchbar_click");

              Navigator.push<dynamic>(
                context,
                MaterialPageRoute<dynamic>(
                  builder: (BuildContext context) => SearchPage(),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xbb3c4043),
                borderRadius: const BorderRadius.all(Radius.circular(40.0)),
              ),
              child: Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                    child: Image.asset(
                      "assets/images/search_white.webp",
                      height: 20,
                      width: 20,
                    ),
                  ),
                  ValueListenableBuilder<Game?>(
                    builder: (context, game, child) {
                      String? searchHint = "Search for game";
                      if (game != null) {
                        searchHint = game.name;
                      }
                      return Expanded(
                        child: Text(
                          searchHint!,
                          maxLines: 1,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: const Color(0xFF9aa0a6),
                          ),
                        ),
                      );
                    },
                    valueListenable: _bannerNotifier,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void moveToGame(Game game) {
    DuckAnalytics.analytics.logEvent(name: "move_to_game", parameters: <String, dynamic>{'game_name': game.name});

    Navigator.push<dynamic>(
      context,
      MaterialPageRoute<dynamic>(
        builder: (BuildContext context) => GameInfoPage(game),
      ),
    );
  }

  void moveToGameList(gameType) {
    DuckAnalytics.analytics
        .logEvent(name: "move_to_game_list", parameters: <String, dynamic>{'game_type_name': gameType.name});

    Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => new GameListPage(gameType)),
    );
  }

  @override
  void onDisableNativeAd1() {
    loadEditorChoiceGame();
    loadPopularGame();
  }

  @override
  bool get wantKeepAlive => true;
}

// /// Allow the text size to shrink to fit in the space
// class _GridTitleText extends StatelessWidget {
//   const _GridTitleText(this.text);
//
//   final String text;
//
//   @override
//   Widget build(BuildContext context) {
//     return FittedBox(
//       fit: BoxFit.scaleDown,
//       alignment: AlignmentDirectional.centerStart,
//       child: Text(text),
//     );
//   }
// }

// class _GameTypeItem extends StatelessWidget {
//   _GameTypeItem({
//     Key key,
//     @required this.gameType,
//   }) : super(key: key);
//
//   final GameType gameType;
//
//   @override
//   Widget build(BuildContext context) {
//     final Widget image = Material(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
//       clipBehavior: Clip.antiAlias,
//       child: CachedNetworkImage(
//         imageUrl: gameType.photo,
//         fit: BoxFit.cover,
//       ),
//     );
//
//     return GridTile(
//         header: Material(
//           color: Colors.transparent,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
//           ),
//           clipBehavior: Clip.antiAlias,
//           child: GridTileBar(
//             title: _GridTitleText(gameType.name),
//             backgroundColor: Colors.black45,
//           ),
//         ),
//         child: InkWell(
//           onTap: () {
//             Navigator.push(
//               context,
//               new MaterialPageRoute(
//                   builder: (context) => new GameListPage(gameType)),
//             );
//           },
//           child: image,
//         ));
//   }
// }

///定时器
Stream<bool> myInterval(Duration delay, {Duration? initialDelay}) async* {
  if (initialDelay != null) {
    yield await Future.delayed(initialDelay).then((_) => true);
  } else {
    yield await Future.delayed(delay).then((_) => true);
  }

  yield* myInterval(delay);
}

var placeHolderImage = new Image.asset(
  "assets/images/default_icon.png",
  fit: BoxFit.cover,
);

var randomColor = new Container(
    decoration: new BoxDecoration(
  color: Color(0x7440bf),
));
