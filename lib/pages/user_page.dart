import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:games_services/games_services.dart';
import 'package:launch_review/launch_review.dart';
import 'package:package_info/package_info.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:videogame/app_theme.dart';
import 'package:videogame/generated/l10n.dart';
import 'package:videogame/model/duck_account.dart';
import 'package:videogame/model/event.dart';
import 'package:videogame/pages/about_page.dart';
import 'package:videogame/pages/buy_coins_sheet.dart';
import 'package:videogame/pages/main_page.dart';
import 'package:videogame/pages/profile_page.dart';
import 'package:videogame/pages/signin_page.dart';
import 'package:videogame/util/duck_analytics.dart';
import 'package:videogame/util/duck_billing.dart';
import 'package:videogame/util/duck_game.dart';
import 'package:videogame/util/duck_user.dart';

import '../constants.dart';
import '../logger.dart';
import '../util/duck_ads.dart';

class UserPage extends StatefulWidget {
  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> with AutomaticKeepAliveClientMixin {
  static final String _TAG = "_UserPageState";
  String appName = "";
  String packageName = "";
  String version = "";
  String buildNumber = "";

  int myCoins = 0;
  bool isBillingAvailable = false;
  bool? isPremium;
  DuckAccount? userInfo;

  @override
  void initState() {
    super.initState();
    buildAppInfo();
    initCoins();
    initBilling();

    _handleGoogleSignIn();

    DuckAnalytics.analytics.setCurrentScreen(
      screenName: 'UserPage',
    );

    eventBus.on<RefreshCoinsEvent>().listen((event) {
      initCoins();
      initBilling();
    });

    eventBus.on<RefreshUserInfoEvent>().listen((event) {
      _handleGoogleSignIn();
    });
  }

  @override
  Widget build(BuildContext context) {
    var coin = "";
    var medal = "";
    if (isPremium != null) {
      medal = isPremium! ? "Pro" : "Free";
      coin = isPremium! ? "999+" : myCoins.toString();
    }

    return Material(
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          /// 会员
          Container(
            padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
            margin: const EdgeInsets.only(top: 16, left: 8, right: 8),
            decoration: new BoxDecoration(
              image: DecorationImage(
                image:
                    (isPremium != null && isPremium!) ? AssetImage("assets/images/rank_header.webp") : AssetImage(""),
                fit: BoxFit.cover,
              ),
              // 边色与边宽度
              color: AppTheme.surface1,

              shape: BoxShape.rectangle,
              // 默认值也是矩形
              borderRadius: new BorderRadius.circular((8)), // 圆角度
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                          width: 80,
                          height: 80,
                          child: userInfo == null || userInfo!.photoUrl == null
                              ? InkWell(
                                  child: new Image.asset("assets/images/score_star_unselect.webp"),
                                  onTap: () async {
                                    await onLogin(context);
                                  },
                                )
                              : InkWell(
                                  child: CircleAvatar(
                                    radius: 50,
                                    child: ClipOval(
                                      child: new CachedNetworkImage(
                                        imageUrl: userInfo!.photoUrl!,
                                        errorWidget: (context, url, error) =>
                                            new Image.asset("assets/images/score_star_unselect.webp"),
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    LOG.D(_TAG, "build: 去用户详情");
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => ProfilePage(userInfo!, isPremium!)),
                                    );
                                  },
                                )),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (userInfo == null || userInfo!.displayName == null)
                              InkWell(
                                onTap: () async {
                                  await onLogin(context);
                                },
                                child: Text(
                                  S.of(context).Tap_to_Login,
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16),
                                ),
                              )
                            else
                              Text(
                                userInfo!.displayName!,
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16),
                              ),
                            if (userInfo != null)
                              SizedBox(
                                height: 8,
                              ),
                            if (userInfo != null)
                              Row(
                                children: [
                                  Text(
                                    medal,
                                    style: Theme.of(context).textTheme.caption,
                                  ),
                                  SizedBox(width: 8),
                                  Image.asset(
                                    "assets/images/ic_medal.png",
                                    width: 20,
                                    height: 20,
                                  ),
                                  if (isPremium != null && isPremium!)
                                    Image.asset(
                                      "assets/images/gold_medal.webp",
                                      width: 20,
                                      height: 20,
                                    ),
                                  if (isPremium != null && isPremium!)
                                    Image.asset(
                                      "assets/images/icon_talent_authenticate.png",
                                      width: 20,
                                      height: 20,
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      Spacer(),
                    ],
                  ),
                ),
                if (isBillingAvailable)
                  Container(
                    decoration: new BoxDecoration(
                      image: new DecorationImage(
                          image: new AssetImage("assets/images/user_center_v_club_item_bg.png"), fit: BoxFit.fill),
                    ),
                    child: Row(
                      children: [
                        Spacer(),
                        Text(
                          S.of(context).Unlimited_Coins_No_Ads,
                          style: TextStyle(color: Color(0xfffccf17), fontSize: 12),
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        isPremium != null && !isPremium!
                            ? ElevatedButton(
                                onPressed: () {
                                  DuckAnalytics.analytics.logEvent(
                                    name: "clickPremium",
                                  );
                                  DuckBilling.instance.makePurchase("premium");
                                },
                                style: ElevatedButton.styleFrom(
                                    shape: new RoundedRectangleBorder(
                                      borderRadius: new BorderRadius.circular(30.0),
                                    ),
                                    primary: Color(0xfffccf17)),
                                child: Text(S.of(context).Premium, style: TextStyle(color: Colors.black, fontSize: 13)),
                              )
                            : Container(
                                height: 48,
                              ),

                        // Container(
                        //   decoration: new BoxDecoration(
                        //     // 边色与边宽度
                        //     shape: BoxShape.rectangle,
                        //     // 默认值也是矩形
                        //     borderRadius: new BorderRadius.circular((8)), // 圆角度
                        //     color: Color(0xfffccf17),
                        //   ),
                        //   child: Text("Premium",
                        //       style: TextStyle(color: Colors.black,fontSize: 12)),
                        //
                        // ),
                        SizedBox(
                          width: 24,
                        ),
                      ],
                    ),
                  )
              ],
            ),
          ),

          /// 金币
          Container(
            padding: const EdgeInsets.all(8.0),
            margin: const EdgeInsets.only(top: 12),
            // decoration: new BoxDecoration(
            //   // 边色与边宽度
            //   color: AppTheme.bottomBar,
            //
            //   shape: BoxShape.rectangle,
            //   // 默认值也是矩形
            //   borderRadius: new BorderRadius.circular((8)), // 圆角度
            // ),
            color: AppTheme.surface1,
            child: new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 16),
                  child: Text(
                    S.of(context).My_Coins,
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(width: 48, height: 48, child: new Image.asset("assets/images/ic_coin.png")),
                      Text(
                        coin,
                        style: TextStyle(fontSize: 36, color: Color(0xffff9b1a)),
                      ),
                      Spacer(),
                      // Text(
                      //   "Free Coins Limit Time",
                      //   style:
                      //       TextStyle(color: Color(0xffff9b1a), fontSize: 12),
                      // ),
                      SizedBox(
                        width: 8,
                      ),
                      if (isPremium != null && !isPremium!)
                        ElevatedButton.icon(
                          onPressed: () {
                            showModalBottomSheet<void>(
                              isScrollControlled: true,
                              context: context,
                              builder: (context) {
                                return Wrap(
                                  children: [BuyCoinSheet()],
                                );
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                              shape: new RoundedRectangleBorder(
                                borderRadius: new BorderRadius.circular(30.0),
                              ),
                              primary: Color(0xffff9b1a)),
                          label: Text(S.of(context).Get_Coins, style: Theme.of(context).textTheme.button),
                          icon:
                              /*Icon(
                          Icons.play_circle_fill,
                          color: AppTheme.white,
                        )*/
                              Image.asset(
                            "assets/images/cl0.png",
                            width: 30,
                            height: 30,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// 分享/评论
          Container(
            margin: const EdgeInsets.only(top: 8),
            color: AppTheme.surface1,
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  ListTile(
                    leading:
                        SizedBox(width: 24, height: 24, child: new Image.asset("assets/images/share_icon_orange.webp")),
                    title: Text(
                      S.of(context).Share_With_Friends,
                      style: TextStyle(fontSize: 14, color: AppTheme.white),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Color(0xff707380),
                    ),
                    onTap: () {
                      Share.share(S.of(context).share_msg + share_url, subject: share_msg);
                      DuckAnalytics.analytics.logShare(contentType: share_msg, itemId: '', method: '');
                      DuckAds.instance.dontShowOpenAd();
                    },
                  ),

                  // Container(
                  //   height: 8,
                  //   color: AppTheme.background,
                  // ),
                  Divider(
                    height: 0.5,
                  ),
                  /// 成就
                  ListTile(
                    leading: SizedBox(
                        width: 24,
                        height: 24,
                        child: Icon(
                          Icons.wine_bar_rounded,
                          color: Colors.yellow,
                        )),
                    title: Text(
                      S.of(context).Achievements,
                      style: TextStyle(fontSize: 14, color: AppTheme.white),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Color(0xff707380),
                    ),
                    onTap: () async {
                      GamesServices.showAchievements();
                    },
                  ),
                  Divider(
                    height: 0.5,
                  ),

                  /// 排行榜
                  ListTile(
                    leading: SizedBox(
                        width: 24,
                        height: 24,
                        child: Icon(
                          Icons.leaderboard_rounded,
                          color: Colors.green,
                        )),
                    title: Text(
                      S.of(context).Leaderboards,
                      style: TextStyle(fontSize: 14, color: AppTheme.white),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Color(0xff707380),
                    ),
                    onTap: () async {
                      // if (!DuckUser.instance.isPlayGameSignIn) {
                      //   await DuckUser.instance.signInGameService();
                      // } else {
                      GamesServices.showLeaderboards(iOSLeaderboardID: 'ios_leaderboard_id');
                      // }
                    },
                  ),
                  Container(
                    height: 8,
                    color: AppTheme.background,
                  ),

                  /// 给我星
                  ListTile(
                    leading: SizedBox(
                        width: 24, height: 24, child: new Image.asset("assets/images/score_star_large_select.webp")),
                    title: Text(
                      S.of(context).Rate_us,
                      style: TextStyle(fontSize: 14, color: AppTheme.white),
                    ),
                    subtitle: Text(
                      S.of(context).Rate_us_hint,
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Color(0xff707380),
                    ),
                    onTap: () {
                      // Navigator.push(
                      //     context,
                      //     new MaterialPageRoute(
                      //         builder: (context) => new ReviewPage()));
                      DuckAnalytics.analytics.logEvent(
                        name: "clickGiveUsStar",
                      );
                      LaunchReview.launch();
                    },
                  ),
                  Divider(
                    height: 0.5,
                  ),

                  /// 插件 设置
                  // if (DuckGame.instance.is64Bit())
                  ListTile(
                    leading: SizedBox(
                        width: 24,
                        height: 24,
                        child: Icon(
                          Icons.extension_rounded,
                          color: Colors.blue,
                        )),
                    title: Text(
                      S.of(context).Manage_plugin,
                      style: TextStyle(fontSize: 14, color: AppTheme.white),
                    ),
                    subtitle: Text(
                      S.of(context).Manage_plugin_detail,
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Color(0xff707380),
                    ),
                    onTap: () {
                      // DuckGame.instance.openDolphinSetting(context);
                      DuckGame.instance.openPluginSetting();
                    },
                  ),
                  if (DuckGame.instance.is64Bit())
                    Divider(
                      height: 0.5,
                    ),

                  // /// n64 设置
                  // ListTile(
                  //   leading: SizedBox(
                  //       width: 24,
                  //       height: 24,
                  //       child: Icon(
                  //         Icons.settings_rounded,
                  //         color: Colors.green,
                  //       )),
                  //   title: Text(
                  //     S.of(context).N64_Setting,
                  //     style: TextStyle(fontSize: 14, color: AppTheme.white),
                  //   ),
                  //   subtitle: Text(
                  //     S.of(context).N64_Setting_hint,
                  //     style: TextStyle(fontSize: 12, color: Colors.white70),
                  //   ),
                  //   trailing: Icon(
                  //     Icons.arrow_forward_ios_rounded,
                  //     size: 16,
                  //     color: Color(0xff707380),
                  //   ),
                  //   onTap: () {
                  //     DuckGame.instance.openN64Setting();
                  //   },
                  // ),
                  // Divider(
                  //   height: 0.5,
                  // ),
                  //
                  // /// nds 设置
                  // ListTile(
                  //   leading: SizedBox(
                  //       width: 24,
                  //       height: 24,
                  //       child: Icon(
                  //         Icons.settings_rounded,
                  //         color: Colors.pink,
                  //       )),
                  //   title: Text(
                  //     S.of(context).NDS_Setting,
                  //     style: TextStyle(fontSize: 14, color: AppTheme.white),
                  //   ),
                  //   subtitle: Text(
                  //     S.of(context).NDS_Setting_hint,
                  //     style: TextStyle(fontSize: 12, color: Colors.white70),
                  //   ),
                  //   trailing: Icon(
                  //     Icons.arrow_forward_ios_rounded,
                  //     size: 16,
                  //     color: Color(0xff707380),
                  //   ),
                  //   onTap: () {
                  //     DuckGame.instance.openNDSSetting();
                  //   },
                  // ),
                  // // Container(
                  // //   height: 8,
                  // //   color: AppTheme.background,
                  // // ),
                  /// 多语言
                  // ListTile(
                  //   leading: Icon(
                  //     Icons.language_rounded,
                  //     color: Colors.cyanAccent,
                  //   ),
                  //   title: Text(S.of(context).Language,
                  //     style: TextStyle(fontSize: 14, color: AppTheme.white),
                  //   ),
                  //   subtitle: Text(S.of(context).Language_hint,
                  //     style: TextStyle(fontSize: 12, color: Colors.white70),
                  //   ),
                  //   trailing: Icon(
                  //     Icons.arrow_forward_ios_rounded,
                  //     size: 16,
                  //     color: Color(0xff707380),
                  //   ),
                  //   onTap: () async {
                  //     var lang = await DuckKV.readKey("app_language");
                  //     Navigator.push(context, new MaterialPageRoute(builder: (context) => new LocalizationPage(lang)));
                  //   },
                  // ),
                  Divider(
                    height: 0.5,
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.add_to_drive_rounded,
                      color: Colors.yellowAccent,
                    ),
                    title: Text(
                      S.of(context).Cloud_Backup,
                      style: TextStyle(fontSize: 14, color: AppTheme.white),
                    ),
                    subtitle: Text(
                      S.of(context).Cloud_Backup_Hint,
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Color(0xff707380),
                    ),
                    onTap: () async {
                      DuckGame.instance.openCloudSavesSetting();
                    },
                  ),
                  Divider(
                    height: 0.5,
                  ),
                  Container(
                    height: 8,
                    color: AppTheme.background,
                  ),

                  /// 反馈
                  ListTile(
                    leading: Icon(
                      Icons.feedback_outlined,
                      color: Colors.blueAccent,
                    ),
                    title: Text(
                      S.of(context).Give_Feedback,
                      style: TextStyle(fontSize: 14, color: AppTheme.white),
                    ),
                    subtitle: Text(
                      S.of(context).Feature_request_Bug_report,
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Color(0xff707380),
                    ),
                    onTap: onFeedBack,
                  ),
                  Divider(
                    height: 0.5,
                  ),

                  /// 关于
                  ListTile(
                    leading: Icon(Icons.info_outline_rounded),
                    title: Text(
                      S.of(context).About,
                      style: TextStyle(fontSize: 14, color: AppTheme.white),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Color(0xff707380),
                    ),
                    onTap: () {
                      DuckAnalytics.analytics.logEvent(
                        name: "clickAbout",
                      );
                      Navigator.push(context, new MaterialPageRoute(builder: (context) => new AboutPage()));
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void onFeedBack() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    var version = packageInfo.version;

    // if (Platform.isAndroid) {
    var androidInfo = DuckGame.androidInfo;
    var release = androidInfo.version.release;
    var sdkInt = androidInfo.version.sdkInt;
    var manufacturer = androidInfo.manufacturer;
    var model = androidInfo.model;
    var deviceInfo = 'Android $release (SDK $sdkInt), $manufacturer $model';
    // print(deviceInfo);
    // Android 9 (SDK 28), Xiaomi Redmi Note 7
    // }

    var query = '';
    int? option = await showFeedBackOption();
    LOG.D(_TAG, "showFeedBackOption 选择了: $option");
    switch (option) {
      case 0:
        query = 'subject=Video Game: Feature Request&body=App Version: $version\nDevice:$deviceInfo\n\n\n\n';
        break;
      case 1:
        query = 'subject=Video Game: Bug Report&body=App Version: $version\nDevice:$deviceInfo\n\n\n\n';
        break;
      case 2:
        query = 'subject=Video Game: Question&body=App Version: $version\nDevice:$deviceInfo\n\n\n\n';
        break;
      default:
        return;
    }
    final Uri _emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@actduck.com',
      query: query,
    );
    // launchURL(_emailLaunchUri.toString());
    DuckAnalytics.analytics.logEvent(
      name: "clickGiveFeedback",
    );
    launchURL(_emailLaunchUri.toString());
    DuckAds.instance.dontShowOpenAd();
  }

  onLogin(BuildContext context) async {
    DuckAnalytics.analytics.logEvent(name: 'click_tap_to_login');

    showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            SignInPage(
              () async {
                await DuckUser.instance.signIn();
                Navigator.pop(context);
              },
              () {
                // todo fb登录
              },
              () {
                // todo 苹果登录
              },
            )
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  buildAppInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    setState(() {
      appName = packageInfo.appName;
      packageName = packageInfo.packageName;
      version = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    });
  }

  void initCoins() async {
    myCoins = await DuckGame.instance.getCoins();
    setState(() {});
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> initBilling() async {
    isBillingAvailable = DuckBilling.instance.isBillingAvailable();

    isPremium = await DuckBilling.instance.isPremium();
    setState(() {});
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      userInfo = DuckUser.instance.userInfo;
    });
  }

  Future<void> _handleFacebookSignIn() async {
    // todo
  }

  Future<void> _handleAppleSignIn() async {
    // todo
  }

  Future<int?> showFeedBackOption() async {
    int? i = await showDialog<int>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 0);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(S.of(context).Feature_Request),
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 1);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.of(context).Bug_Report),
                      Text(
                        S.of(context).Bug_Report_Detail,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.secondText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 2);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(S.of(context).Others),
                ),
              ),
            ],
          );
        });

    return i;
  }
}
