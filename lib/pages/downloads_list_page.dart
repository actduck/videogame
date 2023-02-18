import 'package:flutter/material.dart';
import 'package:videogame/common/loading_status.dart';
import 'package:videogame/db/db.dart';
import 'package:videogame/generated/l10n.dart';
import 'package:videogame/model/event.dart';
import 'package:videogame/model/list_item.dart';
import 'package:videogame/pages/base_game_list_page.dart';
import 'package:videogame/util/duck_ads.dart';
import 'package:videogame/util/duck_analytics.dart';
import 'package:videogame/util/duck_game.dart';
import 'package:videogame/widget/empty_view.dart';

import '../app_theme.dart';
import '../common/error_view.dart';
import '../common/loading_view.dart';
import '../common/platform_adaptive_progress_indicator.dart';
import '../model/game.dart';
import 'main_page.dart';

class DownloadsListPage extends BaseGameListPage {
  @override
  _DownloadsListPageState createState() => new _DownloadsListPageState();
}

class _DownloadsListPageState extends BaseGameListState with GameListMixin {
  static final String _TAG = "_DownloadsListPageState";

  List<ListItem> randomList = [];

  @override
  void initState() {
    super.initState();

    DuckAnalytics.analytics.setCurrentScreen(
      screenName: 'DownloadsListPage',
    );

    eventBus.on<RefreshDownloadsEvent>().listen((event) {
      loadGameList();
    });

    _getRandomGame();
  }

  void _getRandomGame() {
    appRepo.guessYouLike().listen((data) {
      setState(() {
        GamePage gp = GamePage.fromJson(data);
        randomList.clear();
        randomList.addAll(DuckAds.instance.addNativeAd2(randomList.length, gp.content!));
      });
    }, onError: (e) {});
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: AppBar(
//        automaticallyImplyLeading: false, // 返回箭头
          title: Text(S.of(context).Downloads),
          centerTitle: true,
        ),
        body: LoadingView(
            status: loadingState,
            loadingContent: Center(child: const PlatformAdaptiveProgressIndicator()),
            errorContent: ErrorView(
              description: S.of(context).Oops_an_error_occurred,
              onRetry: () {
                setState(() {
                  loadGameList();
                });
              },
            ),
            successContent: Container(color: AppTheme.surface1, child: successContent(context))));
  }

  Widget successContent(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: <Widget>[
        // 标题
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 16, right: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  S.of(context).Download_Task,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    letterSpacing: 0.27,
                    color: AppTheme.mainText,
                  ),
                ),
                SizedBox(
                  width: 4,
                ),
                Text(
                  "(${myList.length})",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 0.27,
                    color: AppTheme.secondText,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (myList.length > 0) super.buildSliverList() else SliverToBoxAdapter(child: EmptyView()),

        // /// 下载的任务
        // SliverToBoxAdapter(
        //   child: super.successContent(),
        // ),
        if (randomList.length > 0)
          SliverToBoxAdapter(
            child: Container(
              height: 8,
              color: AppTheme.surface,
            ),
          ),
        if (randomList.length > 0)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8, left: 16, right: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    S.of(context).Guess_You_Like,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: 0.27,
                      color: AppTheme.mainText,
                    ),
                  ),
                  Spacer(),
                  InkWell(
                    onTap: () {
                      _getRandomGame();
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.cached_rounded,
                          size: 14,
                          color: AppTheme.secondText,
                        ),
                        SizedBox(
                          width: 4,
                        ),
                        Text(
                          S.of(context).Change,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            letterSpacing: 0.27,
                            color: AppTheme.secondText,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        if (randomList.length > 0)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                ListItem li = randomList[index];
                return onBuildListItem(li);
              },
              childCount: randomList.length,
            ),
          )
      ],
    );
  }

  /// 开始加载游戏列表
  @override
  loadGameList({int page = 1}) async {
    loadingState = LoadingStatus.loading;

    DuckDao.getDownloadsGames().then((list) => {
          setState(() {
            if (page == 1) {
              myList.clear();
            }

            myList.addAll(list);

            loadingState = LoadingStatus.success;
          })
        });
  }

  @override
  bool hasMore() {
    return false;
  }

  @override
  bool needDismiss() {
    return true;
  }

  @override
  void onDismiss(int index, Game game, BuildContext context) {
    DuckGame.instance.onDeleteDownloadTask(context, game, () {
      setState(() {
        myList.removeAt(index);
      });

      DuckDao.getGameAndTask(game.id).then((gat) {
        if (gat != null) {
          DuckDao.deleteGameAndTask(gat.id);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(S.of(context).Game_is_removed_from_Downloads(game.name!))));
        }
      });
    });
  }
}
