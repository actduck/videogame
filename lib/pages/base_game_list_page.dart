import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:videogame/app_theme.dart';
import 'package:videogame/common/error_view.dart';
import 'package:videogame/common/loading_status.dart';
import 'package:videogame/common/loading_view.dart';
import 'package:videogame/common/platform_adaptive_progress_indicator.dart';
import 'package:videogame/generated/l10n.dart';
import 'package:videogame/model/event.dart';
import 'package:videogame/model/game.dart';
import 'package:videogame/model/list_item.dart';
import 'package:videogame/net/api.dart';
import 'package:videogame/net/app_repo.dart';
import 'package:videogame/pages/game_info_page.dart';
import 'package:videogame/pages/home_page.dart';
import 'package:videogame/util/duck_ads.dart';
import 'package:videogame/util/duck_ads_id.dart';
import 'package:videogame/util/duck_game.dart';
import 'package:videogame/widget/game_start_button.dart';
import 'package:videogame/widget/loading_more_view.dart';

import '../db/db.dart';
import '../logger.dart';
import '../model/download_event.dart';
import '../util/duck_downloader.dart';
import '../widget/empty_view.dart';
import 'downloads_list_page.dart';
import 'main_page.dart';

abstract class BaseGameListPage extends StatefulWidget {
  BaseGameListPage({Key? key}) : super(key: key);
}

abstract class BaseGameListState<Page extends BaseGameListPage> extends State<Page>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {}

const SORT_POPULAR = "popular";
const SORT_ALPHA = "alpha";
const SORT_DIRECTION_ASC = "asc";
const SORT_DIRECTION_DESC = "desc";
const SORT_LETTER_All = "All";

mixin GameListMixin<Page extends BaseGameListPage> on BaseGameListState<Page> {
  static final String _TAG = "GameListMixin";

  List<ListItem> myList = [];

  AppRepo appRepo = new AppRepo();

  // int page = 1;
  // int pageNum = 1;
  // int total = 0;
  // bool? last = false;
  GamePage? mGp;

  ScrollController controller = new ScrollController();

  late LoadingStatus loadingState;
  late TabController _tabController;

  bool hasPlugin = true;
  String pluginPackageName = "";
  bool loadingMore = false;

  @override
  void initState() {
    super.initState();

    loadingState = LoadingStatus.loading;
    loadGameList();

    initView();

    _initDownloading();
    _initShowDownloadRed();

    eventBus.on<DisableAdEvent>().listen((event) {
      LOG.D(_TAG, "禁用广告 ${event.adFormat}");
      if (event.adFormat == AD_ADMOB_NATIVE1) {
        onDisableNativeAd1();
      }
      if (event.adFormat == AD_ADMOB_NATIVE2) {
        onDisableNativeAd2();
      }
    });
  }


  @override
  void dispose() {
    controller.dispose();
    _tabController.dispose();
    DuckAds.instance.disposeNativeAd2();
    // DuckAds.instance.disposeInterstitialAd();
    // _interstitialAd.dispose();
    // _unbindBackgroundIsolate();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: buildAppBar(),
      body: LoadingView(
        status: loadingState,
        loadingContent: Center(child: const PlatformAdaptiveProgressIndicator()),
        errorContent: ErrorView(
          description: S.of(context).Oops_an_error_occurred,
          onRetry: () {
            setState(() {
              loadingState = LoadingStatus.loading;
              loadGameList();
            });
          },
        ),
        successContent: Column(
          children: [
            if (sortBy == SORT_ALPHA) uiFilter(),
            if (myList.length == 0) EmptyView(),
            Expanded(
              child: Scrollbar(
                child: CustomScrollView(
                  controller: controller,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    CupertinoSliverRefreshControl(
                      onRefresh: pullToRefresh,
                    ),
                    // buildAppBar(),
                    buildSliverList(),
                    SliverToBoxAdapter(
                      child: LoadingMoreView(loadingMore),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Null> pullToRefresh() async {
    await Future.delayed(new Duration(seconds: 1));
    await loadGameList();
    return null;
  }

  void initView() {
    _tabController = new TabController(vsync: this, length: 2);
    controller.addListener(() {
      // LOG.D(_TAG,
      //     "controller.position.pixels: ${controller.position.pixels} controller.position.maxScrollExtent: ${controller.position.maxScrollExtent}");
      if (hasMore()) {
        onLoadMore();
      }
    });
  }

  loadGameList({int page = 1}) {}

  /// 列表Item
  Widget onBuildListItem(ListItem item, {int? ranking}) {
    if (item is Game) {
      return buildGameItem(item, ranking: ranking);
    }
    if (item is AdItem) {
      return Column(
        children: [
          DuckAds.instance.NativeAdWidget2(item.nativeAd),
          Divider(
            height: 0.5,
          )
        ],
      );
    }
    return Container();
  }

  /// 游戏Item
  Widget buildGameItem(Game game, {int? ranking}) {
    final imageWidget = Semantics(
      child: ExcludeSemantics(
        child: CachedNetworkImage(
          imageUrl: Api.HOST + game.photo!,
          fit: BoxFit.cover,
          placeholder: (context, url) => placeHolderImage,
          errorWidget: (context, url, error) => placeHolderImage,
        ),
      ),
    );

    var rankingWidget;
    if (ranking != null) {
      switch (ranking) {
        case 1:
          rankingWidget = Center(child: new Image.asset("assets/images/rank1.png"));
          break;
        case 2:
          rankingWidget = Center(child: new Image.asset("assets/images/rank2.png"));
          break;

        case 3:
          rankingWidget = Center(child: new Image.asset("assets/images/rank3.png"));
          break;
        default:
          rankingWidget = Center(
              child: Text(
            ranking.toString(),
            style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold, fontSize: 14),
          ));
      }
    }
    return Column(
      children: [
        Row(
          children: [
            if (ranking != null)
              Container(
                margin: const EdgeInsets.only(left: 8, right: 8),
                width: 36,
                child: rankingWidget,
              ),
            Expanded(
                child: ListTile(
              contentPadding: ranking == null
                  ? EdgeInsets.symmetric(horizontal: 16.0, vertical: 10)
                  : EdgeInsets.only(right: 8.0, top: 10, bottom: 10),
              visualDensity: VisualDensity(vertical: 2),
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
              // isThreeLine: true,
              subtitle: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 4,
                  ),
                  game.size == null
                      ? Container()
                      : Text(
                          game.size! + " | " + game.gameType!.name!,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.secondText,
                          ),
                        ),
                  SizedBox(
                    height: 4,
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 10,
                        color: AppTheme.primary,
                      ),
                      SizedBox(width: 2),
                      Text(
                        game.starCount.toString() + " ",
                        style: TextStyle(fontSize: 12, color: AppTheme.primary),
                      ),
                    ],
                  ),
                  /*Container(
                          margin: const EdgeInsets.only(top: 4),
                          height: 2,
                          child: new LinearProgressIndicator(
                            value: game.task!.progress! / 100,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                            backgroundColor: Color(0xFFFFDAB8),
                          ),
                        ),*/
                ],
              ),
              trailing: GameStartButton(game),
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

  ///===============================================下载按钮红点START=================================
  bool showDownloadRed = false;

  void _initShowDownloadRed() async {
    var gats = await DuckDao.getAllGameAndTask();
    var show = false;
    gats.forEach((element) {
      var event = downloadEventFromMap(element.taskInfo!);
      if (event.downloadState == DOWNLOAD_STATE_PROGRESS) {
        LOG.D(_TAG, "_initShowDownloadRed true：${event.downloadTask!.gameId!}");

        show = true;
      }
    });
    LOG.D(_TAG, "_initShowDownloadRed show：$show");

    setState(() {
      showDownloadRed = show;
    });
  }

  /// 下载进度
  void _initDownloading() async {
    LOG.D(_TAG, "initDownloading：初始化");
    eventBus.on<DownloadEvent>().listen((event) {
      LOG.D(_TAG, "initDownloading：收到");
      _initShowDownloadRed();
    });
  }

  Widget uiDownloadBt() {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          children: [
            CircleAvatar(
              backgroundColor: Colors.black26,
              child: IconButton(
                padding: EdgeInsets.all(0.0),
                icon: Icon(Icons.download_rounded),
                color: AppTheme.white,
                onPressed: () {
                  Navigator.push(context, new MaterialPageRoute(builder: (context) => new DownloadsListPage()));
                },
              ),
            ),
            if (showDownloadRed)
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  margin: const EdgeInsets.only(right: 12, top: 8),
                  width: 6,
                  height: 6,
                  child: CircleAvatar(
                    backgroundColor: Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget uiDownloadBtNoBg() {
    return IconButton(
      icon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Stack(
          children: [
            Icon(Icons.download_rounded),
            if (showDownloadRed)
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  margin: const EdgeInsets.only(right: 2),
                  width: 6,
                  height: 6,
                  child: CircleAvatar(
                    backgroundColor: Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
      onPressed: () {
        Navigator.push(context, new MaterialPageRoute(builder: (context) => new DownloadsListPage()));
      },
    );
  }

  ///===============================================下载按钮红点END=================================
  // Widget buildGetOrStartGame(Game game) {
  //   // if (game.isUnziping == true) {
  //   //   // 正在解压
  //   //   return Container(
  //   //       child: Center(
  //   //         child: AnimatedTextKit(
  //   //           animatedTexts: [
  //   //             WavyAnimatedText(
  //   //               S.of(context).Loading,
  //   //               textStyle: const TextStyle(
  //   //                 fontSize: 14.0,
  //   //               ),
  //   //             ),
  //   //           ],
  //   //         ),
  //   //       ));
  //   // }
  //   return FutureBuilder<bool>(
  //     future: DuckGame.instance.isRomExist(game),
  //     builder: (context, existData) {
  //       if (existData.data == null) {
  //         return Container();
  //       }
  //       return existData.data! ? buildPlayButton(game) : buildDownloadBtn(game);
  //     },
  //   );
  // }

  ///=============================================== 过滤START=================================

  var alphaList = [
    SORT_LETTER_All,
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "L",
    "M",
    "N",
    "O",
    "P",
    "Q",
    "R",
    "S",
    "T",
    "U",
    "V",
    "W",
    "X",
    "Y",
    "Z"
  ];
  var sortBy = SORT_POPULAR;
  var sortLetter = SORT_LETTER_All;
  var sortDirection = SORT_DIRECTION_DESC;

  Widget uiFilter() {
    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.all(4.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        child: Row(
          children: alphaList.map((e) {
            var bg = sortLetter == e
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: AppTheme.secondaryContainer,
                  )
                : BoxDecoration();
            return InkWell(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: bg,
                child: Text(
                  e,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppTheme.mainText,
                  ),
                ),
              ),
              onTap: () {
                setState(() {
                  sortLetter = e;
                  loadGameList();
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  ///=============================================== 过滤END=================================

  Widget buildPluginItem() {
    if (hasPlugin) {
      return Container();
    }
    // todo 改成插件加载进度
    return Container(
      decoration: new BoxDecoration(color: hasPlugin ? Colors.green : Color(0xff7c2828)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
        leading: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          child: SizedBox(
              height: 64,
              width: 64,
              child: new Icon(
                Icons.info,
                color: Color(0xfffa5251),
              )),
        ),
        title: Text(
          hasPlugin ? "Plugin Installed" : "Missing necessary plugin",
          style: TextStyle(color: Color(0xffbe9496)),
        ),
//        trailing: RawMaterialButton(
//          onPressed: () {},
//          child: hasPlugin
//              ? new Icon(
//                  Icons.check_circle,
//                  color: Colors.white,
//                )
//              : new Icon(
//                  Icons.cloud_download,
//                  color: Color(0xfffa5251),
//                ),
//          shape: new CircleBorder(),
//          constraints: new BoxConstraints(minHeight: 32.0, minWidth: 32.0),
//        ),
        // 在下载吗 显示进度条
        onTap: () {
          // showDownloadPluginDialog();
          onInstallPlugin();
        },
        onLongPress: () {
          onRemovePlugin();
        },
      ),
    );
  }

  /// 下载游戏rom
  void _requestDownload(Game game) async {
    var canPlay = await DuckGame.instance.canPlayGame(context, game);
    DuckGame.instance.prepareSthByGameType(game.gameType);
    if (canPlay) {
      DuckGame.instance.legalDownloadRom(context, () async {
        DuckGame.instance.downloadRoms(game);
      });
    }
  }

  /// 去游戏详情页面
  void moveToGame(Game game) {
    Navigator.push<dynamic>(
      context,
      MaterialPageRoute<dynamic>(
        builder: (BuildContext context) => GameInfoPage(game),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  buildAppBar() {
    return null;
  }

  SliverList buildSliverList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          ListItem item = myList[index];

          if (item is AdItem) {
            LOG.D(_TAG, "原生广告 显示 $index");

            return Column(
              children: [
                DuckAds.instance.NativeAdWidget2(item.nativeAd),
                Divider(
                  height: 0.5,
                )
              ],
            );
          } else if (item is Game) {
            Game game = item;

            if (needDismiss()) {
              return Dismissible(
                // Each Dismissible must contain a Key. Keys allow Flutter to
                // uniquely identify widgets.
                key: Key(game.id.toString()),
                // Provide a function that tells the app
                // what to do after an item has been swiped away.
                onDismissed: (direction) {
                  // Remove the item from the data source.
                  onDismiss(index, game, context);
                },
                // Show a red background as the item is swiped away.
                background: Container(
                    color: Colors.redAccent,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    )),
                secondaryBackground: Container(
                    color: Colors.redAccent,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    )),
                child: buildGameItem(game),
              );
            } else {
              return buildGameItem(game);
            }
          }
        },
        childCount: myList.length,
      ),
    );
  }

  void onInstallPlugin() {}

  void onRemovePlugin() {}

  void onDismiss(int index, Game game, BuildContext context) {
    // setState(() {
    //   myList.removeAt(index);
    // });
    //
    // // Then show a snackbar.
    // ScaffoldMessenger.of(context)
    //     .showSnackBar(SnackBar(content: Text(S.of(context).${game.name} dismissed')));
  }

  bool needDismiss() {
    return false;
  }

  /// 是否有更多，默认根据gamepage来
  bool hasMore() {
    return controller.position.pixels + 100 >= controller.position.maxScrollExtent &&
            mGp?.last == false &&
            !loadingMore /*&&
        loadingState != LoadingStatus.loading*/
        ;
  }

  void onLoadMore() {
    setState(() {
      loadingMore = true;
    });
    var nextPage = mGp!.number! + 1 + 1;
    print("加载更多: $nextPage");
    loadGameList(page: nextPage);
  }

  void onDisableNativeAd1() {}

  void onDisableNativeAd2() {
    loadGameList(page: 1);
  }
}
