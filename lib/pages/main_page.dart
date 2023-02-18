import 'package:event_bus/event_bus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:videogame/constants.dart';
import 'package:videogame/db/db.dart';
import 'package:videogame/generated/l10n.dart';
import 'package:videogame/logger.dart';
import 'package:videogame/main.dart';
import 'package:videogame/model/download_event.dart';
import 'package:videogame/model/event.dart';
import 'package:videogame/model/game_and_task.dart';
import 'package:videogame/pages/category_page.dart';
import 'package:videogame/pages/home_page.dart';
import 'package:videogame/pages/user_page.dart';
import 'package:videogame/util/duck_ads.dart';
import 'package:videogame/util/duck_config.dart';
import 'package:videogame/util/duck_downloader.dart';
import 'package:videogame/util/duck_user.dart';

import 'game_library_page.dart';

class MainPage extends StatefulWidget {
  @override
  State createState() {
    return _MainPageState();
  }
}

EventBus eventBus = new EventBus();

class _MainPageState extends State {
  static final String _TAG = "_MainPageState";

  int _currentIndex = 0;

  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    DuckAds.instance.initOpenAd();
    DuckAds.instance.createInterstitialAd();

    _initChannel();

    // 第2步，初始化PageController
    this._pageController = PageController(initialPage: this._currentIndex);
    _initFbm();
    if (isMobile) {
      DuckUser.instance.signInSilently();
      // todo 不自动登录
      DuckUser.instance.signInGameService();
      DuckConfig.instance.setUp();
    }
  }

  List<Widget> _pages = [HomePage(), CategoryPage(), GameLibraryPage(), UserPage()];

  ///初始化推送消息
  void _initFbm() async {
    var token = await FirebaseMessaging.instance.getToken();
    LOG.D(_TAG, "_initFbm: 消息token是$token");
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {}
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(channel.id, channel.name, channelDescription: channel.description
                  //      one that already exists in example app.
                  ),
            ));
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      LOG.D(_TAG, "_initFbm: A new onMessageOpenedApp event was published!");
    });
  }

  @override
  Widget build(context) {
    // Build a simple container that switches content based of off the selected navigation item
    return Scaffold(
      extendBody: true,
      body: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: PageView(
          controller: this._pageController,
          children: this._pages,
          physics: new NeverScrollableScrollPhysics(),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: _handleNavigationChange,
        selectedIndex: _currentIndex,
        destinations: <Widget>[
          NavigationDestination(
            icon: Icon(Icons.sports_esports_rounded),
            selectedIcon: Icon(Icons.sports_esports_rounded),
            label: S.of(context).Games,
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: S.of(context).Favorites,
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books_rounded),
            label: S.of(context).Library,
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: S.of(context).Profile,
          ),
        ],
      ),
    );
  }

  void _handleNavigationChange(int index) {
    setState(() {
      this._currentIndex = index;
      this._pageController!.jumpToPage(this._currentIndex);
    });
  }

  ///{"downloadState":1,"downloadTask":{"gameId":227986,"id":"22f1e74c-0d00-4263-a95c-52c179f51d9e","percent":99}}
  ///{"downloadState":3,"downloadTask":{"file":{"path":"/storage/emulated/0/Android/data/com.actduck.videogame/cache/Grand Theft Auto - Vice City Stories (Europe) (PSP) (PSN).zip"},"gameId":227986,"id":"22f1e74c-0d00-4263-a95c-52c179f51d9e"}}
  ///{"downloadState":6,"downloadTask":{"file":{"path":"/storage/emulated/0/Android/data/com.actduck.videogame/cache/Grand Theft Auto - Vice City Stories (Europe) (PSP) (PSN).zip"},"gameId":227986,"id":"22f1e74c-0d00-4263-a95c-52c179f51d9e"}}
  void _initChannel() {
    var channel = MethodChannel("com.actduck.videogame/video_game");
    channel.setMethodCallHandler((call) async {
      // 同样也是根据方法名分发不同的函数
      switch (call.method) {
        case "updateDownload":
          {
            String msg = call.arguments;
            print("Native 调用 Flutter 成功，参数是：$msg");
            var event = downloadEventFromMap(msg);

            GameAndTask gat = new GameAndTask();
            gat.gameId = event.downloadTask!.gameId;
            gat.taskInfo = msg;
            if (event.downloadState == DOWNLOAD_STATE_START ||
                event.downloadState == DOWNLOAD_STATE_PROGRESS ||
                event.downloadState == DOWNLOAD_STATE_FINISH) {
              await DuckDao.insertOrUpdateGameAndTask(gat).then((value) {
                if (event.downloadState == DOWNLOAD_STATE_START) {
                  // 刷新开始按钮
                  eventBus.fire(RefreshDownloadsEvent());
                }
              });
            }

            eventBus.fire(event);

            return Future.value("成功");
          }
        case "setConsent":
          {
            bool agree = call.arguments;
            DuckAds.instance.setConsent(agree);

          }
      }
      return Future.value(null);
    });
  }
}
