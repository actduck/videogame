import 'package:videogame/common/loading_status.dart';
import 'package:videogame/db/db.dart';
import 'package:videogame/model/event.dart';
import 'package:videogame/pages/base_game_list_page.dart';
import 'package:videogame/util/duck_analytics.dart';

import 'main_page.dart';

class FavoriteListPage extends BaseGameListPage {
  @override
  _FavoriteListPageState createState() => new _FavoriteListPageState();
}

class _FavoriteListPageState extends BaseGameListState with GameListMixin {
  static final String _TAG = "_FavoriteListPageState";

  @override
  void initState() {
    super.initState();

    DuckAnalytics.analytics.setCurrentScreen(
      screenName: 'FavoriteListPage',
    );

    eventBus.on<RefreshFavoriteEvent>().listen((event) {
      loadGameList();
    });
  }

  /// 开始加载游戏列表
  @override
  loadGameList({int page = 1}) async {
    loadingState = LoadingStatus.loading;

    DuckDao.getFavoriteGames().then((list) => {
          setState(() {
            myList.clear();

            myList.addAll(list);

            loadingState = LoadingStatus.success;
          })
        });
  }

  @override
  bool hasMore() {
    return false;
  }
}
