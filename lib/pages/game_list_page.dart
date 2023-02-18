import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:videogame/common/loading_status.dart';
import 'package:videogame/db/db.dart';
import 'package:videogame/model/game_type.dart';
import 'package:videogame/pages/base_game_list_page.dart';
import 'package:videogame/util/duck_ads.dart';
import 'package:videogame/util/duck_analytics.dart';
import 'package:videogame/util/duck_game.dart';

import '../app_theme.dart';
import '../generated/l10n.dart';

class GameListPage extends BaseGameListPage {
  GameListPage(this.gameType);

  final GameType gameType;

  @override
  _GameListPageState createState() => new _GameListPageState(gameType);
}

class _GameListPageState extends BaseGameListState with GameListMixin {
  static final String _TAG = "GameListPageState";

  final GameType gameType;

  _GameListPageState(this.gameType);

  @override
  void initState() {
    super.initState();

    DuckAnalytics.analytics.setCurrentScreen(
      screenName: 'GameListPage',
    );

    DuckGame.instance.prepareSthByGameType(gameType);
    checkPlugin();

  }

  /// 开始加载游戏列表
  @override
  loadGameList({int page = 1}) async {
    appRepo.gameList(page, gameType.id, sortBy: sortBy, sortLetter: sortLetter, sortDirection: sortDirection).listen(
        (gp) {
      setState(() {
        if (page == 1) {
          myList.clear();
        }
        myList.addAll(DuckAds.instance.addNativeAd2(myList.length, gp.content!));
        // DuckAds.instance.loadNativeAd(myList.length);
        mGp = gp;
        loadingState = LoadingStatus.success;
        loadingMore = false;
        // 获取数据后 查看有没有正在下载的任务
      });
    }, onError: (e) {
      setState(() {
        loadingState = LoadingStatus.error;
        loadingMore = false;
      });
    });
  }

  @override
  void onInstallPlugin() {
    // DuckGame.instance.showAddModuleDialog(context, gameType);
  }

  @override
  void onRemovePlugin() {
    // DuckGame.instance.nativeRemovePlugin(gameType);
  }

  @override
  buildAppBar() {
    return AppBar(
      title: Text(gameType.name!),
      centerTitle: true,
      // floating: true,
      actions: <Widget>[
        PopupMenuButton(
            itemBuilder: (context) {
              return [
                SortItem(Icons.whatshot_rounded, S.of(context).sort_by_popular + " " + S.of(context).asc,
                    sortBy == SORT_POPULAR && sortDirection == SORT_DIRECTION_ASC, () {
                  setFiller(SORT_POPULAR, SORT_LETTER_All, SORT_DIRECTION_ASC);
                  loadGameList();
                }),
                SortItem(Icons.whatshot_rounded, S.of(context).sort_by_popular + " " + S.of(context).desc,
                    sortBy == SORT_POPULAR && sortDirection == SORT_DIRECTION_DESC, () {
                  setFiller(SORT_POPULAR, SORT_LETTER_All, SORT_DIRECTION_DESC);
                  loadGameList();
                }),
                SortItem(Icons.sort_by_alpha_rounded, S.of(context).sort_by_alpha + " " + S.of(context).asc,
                    sortBy == SORT_ALPHA && sortDirection == SORT_DIRECTION_ASC, () {
                  setFiller(SORT_ALPHA, null, SORT_DIRECTION_ASC);
                  loadGameList();
                }),
                SortItem(Icons.sort_by_alpha_rounded, S.of(context).sort_by_alpha + " " + S.of(context).desc,
                    sortBy == SORT_ALPHA && sortDirection == SORT_DIRECTION_DESC, () {
                  setFiller(SORT_ALPHA, null, SORT_DIRECTION_DESC);
                  loadGameList();
                }),
              ];
            },
            icon: Icon(Icons.sort_rounded)),
        uiDownloadBtNoBg(),
        Container(
          width: 4,
        )
      ],
    );
  }

  void setFiller(String? sortBy, String? sortLetter, String? sortDirection) {
    if (sortBy != null) {
      this.sortBy = sortBy;
    }
    if (sortLetter != null) {
      this.sortLetter = sortLetter;
    }
    if (sortDirection != null) {
      this.sortDirection = sortDirection;
    }
  }

  PopupMenuItem SortItem(IconData icon, String s, bool isSelect, VoidCallback onClick) {
    var bg = isSelect
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: AppTheme.secondaryContainer,
          )
        : BoxDecoration();
    return PopupMenuItem(
        padding: const EdgeInsets.all(0),
        onTap: onClick,
        child: Container(
          padding: const EdgeInsets.only(left: 16, right: 16),
          alignment: Alignment.centerLeft,
          decoration: bg,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(icon),
              ),
              Text(
                s,
                textAlign: TextAlign.center,
                style: TextStyle(),
              ),
            ],
          ),
          height: kMinInteractiveDimension,
        ));
  }

  void checkPlugin() async {
    var installed = await DuckGame.instance.isModuleInstalled(gameType);
    setState(() {
      hasPlugin = installed;
    });
  }
}
