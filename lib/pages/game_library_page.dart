import 'dart:math' as math;

import 'package:dynamic_height_grid_view/dynamic_height_grid_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:videogame/model/game_type.dart';
import 'package:videogame/pages/home_page.dart';

import '../db/db.dart';
import '../generated/l10n.dart';
import '../logger.dart';
import '../util/duck_analytics.dart';
import '../widget/game_system_view.dart';
import 'game_list_page.dart';

class GameLibraryPage extends StatefulWidget {
  @override
  _GameLibraryPageState createState() => new _GameLibraryPageState();
}

class _GameLibraryPageState extends State<GameLibraryPage> with TickerProviderStateMixin {
  static final String _TAG = "GameSystemPageState";
  List<GameType> gameTypes = List.empty();

  @override
  void initState() {
    super.initState();

    DuckAnalytics.analytics.setCurrentScreen(
      screenName: 'GameLibraryPage',
    );
    initData();
  }

  @override
  Widget build(BuildContext context) {
    Orientation orientation = MediaQuery.of(context).orientation;

    var randomColor2 = Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);

    return NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                floating: true,
                snap: true,
                title: Text(S.of(context).game_library),
                centerTitle: true,
              )
            ],
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          // child: GridView.builder(
          //     gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          //       crossAxisCount: orientation == Orientation.portrait ? 2 : 4,
          //     ),
          //     physics: const BouncingScrollPhysics(
          //       parent: AlwaysScrollableScrollPhysics(),
          //     ),
          //     itemCount: gameTypes.length,
          //     itemBuilder: (BuildContext context, int index) {
          //       var gameType = gameTypes[index];
          //       gameType.total = gameMaps[gameType]?.totalElements;
          //       return GameSystemView(
          //         gameType: gameType,
          //         onClick: () {
          //           moveToGameList(gameType);
          //         },
          //         randomColor: Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0),
          //       );
          //     }),
          child: DynamicHeightGridView(
            crossAxisCount: orientation == Orientation.portrait ? 2 : 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            // itemBuilder: (context, index) {
            //   LOG.D(_TAG, "1111$index");
            //   LOG.D(_TAG, "2222${gameTypes.length}");
            //   var gameType = gameTypes[index];
            //   gameType.total = gameMaps[gameType]?.totalElements;
            //
            //   return GameSystemView(
            //     gameType: gameType,
            //     onClick: () {
            //       moveToGameList(gameType);
            //     },
            //     randomColor: randomColor2,
            //   );
            // },
            builder: (context, index) {
              var gameType = gameTypes[index];
              gameType.total = gameMaps[gameType]?.totalElements;
              return GameSystemView(
                gameType: gameType,
                onClick: () {
                  moveToGameList(gameType);
                },
                randomColor: Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0),
              );
            },
            itemCount: gameTypes.length,
          ),
        ));
  }

  void initData() async {
    var gameTypes = await DuckDao.getGameTypes();
    setState(() {
      this.gameTypes = gameTypes;
    });
  }

  void moveToGameList(gameType) {
    DuckAnalytics.analytics
        .logEvent(name: "move_to_game_list", parameters: <String, dynamic>{'game_type_name': gameType.name});

    Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => new GameListPage(gameType)),
    );
  }
}
