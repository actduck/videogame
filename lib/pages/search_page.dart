import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:videogame/app_theme.dart';
import 'package:videogame/db/db.dart';
import 'package:videogame/logger.dart';
import 'package:videogame/model/game.dart';
import 'package:videogame/model/list_item.dart';
import 'package:videogame/model/search_game.dart';
import 'package:videogame/net/api.dart';
import 'package:videogame/net/app_repo.dart';
import 'package:videogame/pages/game_info_page.dart';
import 'package:videogame/pages/home_page.dart';
import 'package:videogame/util/duck_analytics.dart';

import '../generated/l10n.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  static final String _TAG = "_SearchPageState";

  List<ListItem> myList = [];
  List<SearchGame> myHistory = [];

  bool? last = false;
  bool loadingMore = false;
  bool showHistory = true;
  bool searching = false;
  FloatingSearchBarController mController = new FloatingSearchBarController();

  @override
  void initState() {
    super.initState();
    DuckAnalytics.analytics.setCurrentScreen(
      screenName: 'SearchPage',
    );

    getSearchHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FloatingSearchAppBar(
          iconColor: AppTheme.surface1,
          titleStyle: TextStyle(color: Colors.black87),
          hintStyle: TextStyle(color: Colors.black54),
          title: Text(S.of(context).Searching),
          alwaysOpened: true,
          transitionDuration: const Duration(milliseconds: 800),
          color: Colors.greenAccent.shade100,
          colorOnScroll: AppTheme.primary,
          progress: searching,
          controller: mController,
          onSubmitted: (query) async {
            if (query.isNotEmpty) {
              await submitSearch(query);
            }
          },
          onFocusChanged: (isFocused) {
            setState(() {
              this.showHistory = isFocused;
              LOG.D(_TAG, "onFocusChanged 焦点改变$showHistory");
            });
          },
          onQueryChanged: (query) {
            if (query.isEmpty) {
              setState(() {
                showHistory = true;
                searching = false;
              });
            } else {
              getSearchData(query);
            }
          },
          body: showHistory
              ? ListView.builder(
                  itemCount: myHistory.length,
                  itemBuilder: (context, index) {
                    return buildGameHistoryItem(myHistory[index]);
                  },
                )
              : ListView.builder(
                  itemCount: myList.length,
                  itemBuilder: (context, index) {
                    var item = myList[index];
                    if (item is Game) return buildGameSearchItem(item);
                    return Container();
                  },
                )),
    );
  }

  Future submitSearch(String? query) async {
    var gs = new SearchGame();
    gs.keywords = query;
    gs.lastSearchTime = DateTime.now().millisecondsSinceEpoch.toString();
    await DuckDao.insertOrUpdateSearchGame(gs);

    DuckAnalytics.analytics.logEvent(name: "submit_search", parameters: <String, dynamic>{
      'keywords': query,
    });

    getSearchHistory();
    getSearchData(query);
  }

  ListTile buildGameHistoryItem(SearchGame searchGame) {
    return ListTile(
      title: Text(
        searchGame.keywords!,
        style: TextStyle(color: AppTheme.mainText),
      ),
      leading: Icon(
        Icons.history_rounded,
        color: Color(0xff80868b),
      ),
      onTap: () async {
        mController.query = searchGame.keywords!;
        await submitSearch(searchGame.keywords);
      },
    );
  }

  /// 游戏Item
  Widget buildGameSearchItem(Game game) {
    final imageWidget = Semantics(
      child: ExcludeSemantics(
        child: CachedNetworkImage(
          imageUrl: Api.HOST + game.photo!,
          fit: BoxFit.cover,
          placeholder: (context, url) => placeHolderImage,
        ),
      ),
    );

    return Column(
      children: [
        ListTile(
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
          // isThreeLine: true,
          subtitle: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 2,
              ),
              game.size == null
                  ? Container()
                  : Text(
                      game.size! + " | " + game.gameType!.name!,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.secondText,
                      ),
                    ),
              SizedBox(
                height: 2,
              ),
              Text(
                game.summary!,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: TextStyle(fontSize: 12),
              )
            ],
          ),
//          dense: true,
          onTap: () {
            DuckAnalytics.analytics
                .logEvent(name: "search_game_click", parameters: <String, dynamic>{'game_name': game.name});

            moveToGame(game);
          },
        ),
        Divider(
          height: 0.5,
        )
      ],
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

  void getSearchData(String? query) {
    setState(() {
      searching = true;
    });
    AppRepo().searchGames(query, 1).listen((data) {
      setState(() {
        this.showHistory = false;
        GamePage gp = GamePage.fromJson(data);
        myList.clear();

        myList.addAll(gp.content!);

        last = gp.last;

        loadingMore = false;
        searching = false;
      });
    }, onError: (e) {});
  }

  void getSearchHistory() {
    DuckDao.getLastSearch4().then((list) => {
          setState(() {
            myHistory.clear();
            myHistory.addAll(list);
          })
        });
  }
}
