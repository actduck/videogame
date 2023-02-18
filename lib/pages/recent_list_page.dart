import 'package:flutter/material.dart';
import 'package:videogame/common/loading_status.dart';
import 'package:videogame/db/db.dart';
import 'package:videogame/model/event.dart';
import 'package:videogame/model/game.dart';
import 'package:videogame/pages/base_game_list_page.dart';
import 'package:videogame/util/duck_analytics.dart';

import '../generated/l10n.dart';
import 'main_page.dart';

class RecentListPage extends BaseGameListPage {
  @override
  _RecentListPageState createState() => new _RecentListPageState();
}

class _RecentListPageState extends BaseGameListState with GameListMixin {
  static final String _TAG = "_RecentListPageState";

  @override
  void initState() {
    super.initState();

    DuckAnalytics.analytics.setCurrentScreen(
      screenName: 'RecentListPage',
    );

    eventBus.on<RefreshRecentEvent>().listen((event) {
      loadGameList();
    });
  }

  /// 开始加载游戏列表
  @override
  loadGameList({int page = 1}) async {
    loadingState = LoadingStatus.loading;

    DuckDao.getRecentGames().then((list) => {
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
    setState(() {
      myList.removeAt(index);
    });

    DuckDao.getGame(game.id).then((g) {
      if (g != null) {
        g.lastPlayTime = null;
        DuckDao.insertOrUpdateGame(g);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.of(context).Game_is_removed_from_History(game.name!))));
      }
    });
  }
}
