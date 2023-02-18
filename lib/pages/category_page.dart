import 'package:flutter/material.dart';
import 'package:videogame/app_theme.dart';
import 'package:videogame/generated/l10n.dart';
import 'package:videogame/pages/downloads_list_page.dart';
import 'package:videogame/pages/favorite_list_page.dart';
import 'package:videogame/pages/recent_list_page.dart';

import 'local_games_page.dart';

class CategoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var tabList = [
      Tab(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_rounded),
            SizedBox(
              width: 8,
            ),
            Text(S.of(context).Favorite)
          ],
        ),
      ),
      Tab(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded),
            SizedBox(
              width: 8,
            ),
            Text(S.of(context).History)
          ],
        ),
      ),
      Tab(
          child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sd_storage_rounded),
          SizedBox(
            width: 8,
          ),
          Text(S.of(context).Local)
        ],
      )),
    ];
    return DefaultTabController(
      length: tabList.length,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 8,
          bottom: TabBar(
            isScrollable: true,
            indicator: UnderlineTabIndicator(
                borderSide: const BorderSide(width: 2.0, color: AppTheme.primary),
                insets: EdgeInsets.symmetric(horizontal: 32.0)),
            tabs: tabList,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            FavoriteListPage(),
            RecentListPage(),
            LocalGamesPage(),
          ],
        ),
      ),
    );
  }
}
