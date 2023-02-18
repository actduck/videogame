import 'package:cached_network_image/cached_network_image.dart';
import "package:collection/collection.dart";
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:videogame/app_theme.dart';
import 'package:videogame/common/error_view.dart';
import 'package:videogame/common/loading_status.dart';
import 'package:videogame/common/loading_view.dart';
import 'package:videogame/common/platform_adaptive_progress_indicator.dart';
import 'package:videogame/db/db.dart';
import 'package:videogame/generated/l10n.dart';
import 'package:videogame/model/event.dart';
import 'package:videogame/model/game.dart';
import 'package:videogame/model/game_type.dart';
import 'package:videogame/model/list_item.dart';
import 'package:videogame/pages/base_game_list_page.dart';
import 'package:videogame/pages/main_page.dart';
import 'package:videogame/util/duck_analytics.dart';
import 'package:videogame/util/duck_game.dart';
import 'package:videogame/widget/local_game_list_view.dart';

import '../logger.dart';
import '../widget/game_start_button.dart';
import 'home_page.dart';

class LocalGamesPage extends BaseGameListPage {
  @override
  _LocalGamesPageState createState() => new _LocalGamesPageState();
}

class _LocalGamesPageState extends BaseGameListState with GameListMixin {
  static final String _TAG = "_LocalGamesPageState";
  Map<GameType?, List<Game>> gameMaps = new Map<GameType?, List<Game>>();

  @override
  void initState() {
    super.initState();

    DuckAnalytics.analytics.setCurrentScreen(
      screenName: 'LocalGamesPage',
    );

    DuckGame.instance.prePareLocalRomsDir();

    loadRecent(true);

    // _initData();
    eventBus.on<RefreshLocalEvent>().listen((event) {
      loadGameList();
    });

    eventBus.on<RefreshRecentEvent>().listen((event) {
      loadRecent(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: LoadingView(
        status: loadingState,
        loadingContent: Center(child: const PlatformAdaptiveProgressIndicator()),
        errorContent: ErrorView(
          description: S.of(context).Local_games_is_empty,
          onRetry: () {
            loadGameList();
          },
        ),
        successContent: gameMaps.length == 0
            ? buildEmptyGameView()
            : Stack(
                children: [
                  CustomScrollView(
                    controller: controller,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      CupertinoSliverRefreshControl(
                        onRefresh: pullToRefresh,
                      ),

                      /// 最近游戏
                      if (myList.length > 0)
                        SliverToBoxAdapter(
                          child: getCategoryUI(new GameType(name: "Recent"), myList),
                        ),

                      /// 分类游戏
                      if (gameMaps.length > 0)
                        SliverToBoxAdapter(
                          child: Column(
                            children: getGamesUI(),
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: SizedBox(height: 16),
                      ),
                    ],
                  ),
                  buildActionUI(),
                ],
              ),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: () async {
          await onAddLocalGame();
        },
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.white,
        child: Icon(Icons.add),
        tooltip: "Add Roms",
      ),
    );
  }

  /// 打开扫描rom页面
  Future<void> onAddLocalGame({bool isFolder = false}) async {
    await DuckGame.instance.scanRoms(isFolder);
    loadGameList();
  }

  void onScanInnerRoms() async {
    var list = await DuckGame.instance.nativeScanInnerDirRoms();
    Fluttertoast.showToast(msg: S.of(context).Scan_ROMs_completed_hint(list.length));
    loadGameList();
  }

  Widget buildActionUI() {
    return Positioned(
      right: 0,
      child: Row(
        children: [
          // IconButton(
          //   icon: Icon(Icons.delete_outline_outlined),
          //   onPressed: () {
          //    onDeleteAllRoms();
          //   },
          // ),
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              showInfoDialog(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  loadGameList({int page = 1}) {
    LOG.D(_TAG, "loadGameList: 加载本地游戏");
    loadingState = LoadingStatus.loading;
    DuckDao.getLocalGames().then((list) => {
          setState(() {
            LOG.D(_TAG, "loadGameList getLocalGames: 加载本地所有游戏成功${list.length}");
            gameMaps.clear();

            var newMap = groupBy(list, (Game game) {
              return game.gameType;
            });

            gameMaps = newMap;

            loadingState = LoadingStatus.success;
          })
        });
  }

  @override
  bool hasMore() {
    return false;
  }

  void loadRecent(bool refresh) {
    DuckDao.getRecentLocalGames().then((list) => {
          setState(() {
            LOG.D(_TAG, "loadGameList getRecentLocalGames: 加载本地最近游戏成功${list.length}");
            if (refresh) {
              myList.clear(); // 最近游戏
            }

            myList.addAll(list);

            loadingState = LoadingStatus.success;
          })
        });
  }

  /// 游戏Item
  Widget buildLocalGameItem(Game game) {
    final imageWidget = Semantics(
      child: ExcludeSemantics(
        child: CachedNetworkImage(
          imageUrl: game.photo!,
          fit: BoxFit.cover,
          placeholder: (context, url) => placeHolderImage,
        ),
      ),
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
              minVerticalPadding: 16,
              leading: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                child: SizedBox(
                  height: 64,
                  width: 64,
                  child: imageWidget,
                ),
              ),
              title: Text(
                game.name!,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              // 在下载吗 显示进度条
              isThreeLine: true,
              subtitle: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 2,
                  ),
                  Text(
                    game.size! + " | " + (game.gameType == null ? "unknow" : game.gameType!.name!),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.secondText,
                    ),
                  ),
                  SizedBox(
                    height: 2,
                  ),
                ],
              ),
              trailing: Container(child: GameStartButton(game)),
//          dense: true,
              onTap: () {
                moveToGame(game);
              },
            )),
          ],
        ),
        Divider(
          height: 0.5,
        )
      ],
    );
  }

  List<Widget> getGamesUI() {
    List<Widget> list = [];
    gameMaps.forEach((key, value) => {
          if (value.length > 0) {list.add(getCategoryUI(key, value))}
        });
    return list;
  }

  getGameUI(GameType? gameType, List<Game>? games) {
    List<Widget> list = [];
    gameType?.total = games?.length;
    list.add(getCategoryUI(gameType, games));

    return list;
  }

  Widget buildTitleItem(GameType? gameType) {
    if (gameType == null) {
      gameType = GameType();
      gameType.name = "UnKnow";
    }
    return InkWell(
      onTap: null,
      child: Padding(
        padding: const EdgeInsets.only(top: 12.0, bottom: 12.0, left: 16, right: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                gameType.total == null ? gameType.name! : '${gameType.name!}(${gameType.total})',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  letterSpacing: 0.27,
                  color: AppTheme.mainText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getCategoryUI(GameType? gameType, List<ListItem>? games) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        buildTitleItem(gameType),
        LocalGameListView(
          list: games,
          onGameClick: (Game game) {
            DuckGame.instance.onPlayGame(context, game);
            DuckAnalytics.analytics
                .logEvent(name: "local_game_click", parameters: <String, dynamic>{'game_name': game.name});
          },
          onMenuClick: (int i, Game game) {
            /*if (i == 0) {
              //收藏
              onLikeButtonTapped(game);
            } else*/
            if (i == 1) {
              // 删除
              DuckDao.deleteLocalGame(game.id);
              loadGameList();
            }
          },
        ),
      ],
    );
  }

  // var localRomDir = "/storage/emulated/0/Android/data/\ncom.actduck.videogame/files/local-rom";
  var gameTypeDir = "NES, SNES, MD, GB, GBC, GBA, N64, MAME, GC, Wii, NDS, PSX, PSP，3DS, SWAN";

  Widget buildEmptyGameView() {
    // if (Platform.isAndroid) {
    var androidInfo = DuckGame.androidInfo;
    var release = androidInfo.version.release;
    var sdkInt = androidInfo.version.sdkInt;
    var manufacturer = androidInfo.manufacturer;
    var model = androidInfo.model;
    print('Android $release (SDK $sdkInt), $manufacturer $model');
    // Android 9 (SDK 28), Xiaomi Redmi Note 7
    // }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              S.of(context).Select_ROMs_directory,
              style: Theme.of(context).textTheme.headline5,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              S.of(context).Select_ROMs_directory_hint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: OutlinedButton(
              child: Text(S.of(context).SELECT_DIRECTORY),
              style: ElevatedButton.styleFrom(
                shape: new RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(30.0),
                ),
              ),
              onPressed: () async {
                await onAddLocalGame(isFolder: true);
              },
            ),
          ),
        ],
      ),
    );
  }

  void showInfoDialog(BuildContext context) {
    var text = S.of(context).Local_ROMs_guide_android9(gameTypeDir);

    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              content: Text(
                text,
                style: TextStyle(height: 1.5),
              ),
            ));
  }

  void onDeleteAllRoms() {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              content: Text(
                S.of(context).Delete_All_Roms_hint,
                style: TextStyle(height: 1.5),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(S.of(context).CANCEL, style: TextStyle(color: Colors.white54)),
                  onPressed: () => Navigator.of(context).pop(), //关闭对话框
                ),
                TextButton(
                  child: Text(S.of(context).RESET, style: TextStyle(color: Colors.red)),
                  onPressed: () async {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ));
  }
}
