import 'package:videogame/common/loading_status.dart';
import 'package:videogame/pages/base_game_list_page.dart';
import 'package:videogame/util/duck_analytics.dart';

import '../model/game.dart';

class RandomListPage extends BaseGameListPage {
  @override
  _RecentListPageState createState() => new _RecentListPageState();
}

class _RecentListPageState extends BaseGameListState with GameListMixin {
  static final String _TAG = "_RecentListPageState";

  @override
  void initState() {
    super.initState();

    DuckAnalytics.analytics.setCurrentScreen(
      screenName: 'RandomListPage',
    );
  }

  /// 开始加载游戏列表
  @override
  loadGameList({int page = 1}) async {
    loadingState = LoadingStatus.loading;

    appRepo.guessYouLike().listen((data) {
      setState(() {
        GamePage gp = GamePage.fromJson(data);
        myList.clear();
        myList.addAll(gp.content!);

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
}
