import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:like_button/like_button.dart';
import 'package:package_info/package_info.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:videogame/app_theme.dart';
import 'package:videogame/db/db.dart';
import 'package:videogame/logger.dart';
import 'package:videogame/model/download_event.dart';
import 'package:videogame/model/event.dart';
import 'package:videogame/model/game.dart';
import 'package:videogame/net/api.dart';
import 'package:videogame/net/app_repo.dart';
import 'package:videogame/util/duck_ads.dart';
import 'package:videogame/util/duck_analytics.dart';
import 'package:videogame/util/duck_downloader.dart';
import 'package:videogame/util/duck_game.dart';
import 'package:videogame/util/utils.dart';
import 'package:videogame/widget/blinking_container.dart';

import '../generated/l10n.dart';
import 'about_page.dart';
import 'main_page.dart';

class GameInfoPage extends StatefulWidget {
  final Game game;

  GameInfoPage(this.game);

  @override
  _GameInfoPageState createState() => _GameInfoPageState();
}

class _GameInfoPageState extends State<GameInfoPage> with TickerProviderStateMixin {
  static final String _TAG = "_GameInfoPageState";

  late AnimationController animationController;
  Animation<double>? animation;
  double opacity1 = 0.0;
  double opacity2 = 0.0;
  double opacity3 = 0.0;

  late AnimationController _controller;
  late Tween<double> _tween;
  late Animation<double> _animation;
  var _target = 0.0;

  DownloadEvent downloadEvent = DownloadEvent(downloadState: DOWNLOAD_STATE_UNKNOWN);

  @override
  void initState() {
    super.initState();
    setAnimition();

    DuckAnalytics.analytics.setCurrentScreen(
      screenName: 'GameInfoPage',
    );
    initFavorite();
    initDownloading();
    LOG.D(_TAG, "GameInfoPage 游戏是${widget.game.toMap()}");

    DuckGame.instance.prepareSthByGameType(widget.game.gameType!);

    initProgressAnimation();
  }

  ///下载进度UI
  void initProgressAnimation() {
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _tween = Tween(begin: _target, end: _target);
    _animation = _tween.animate(
      CurvedAnimation(
        curve: Curves.easeInOut,
        parent: _controller,
      ),
    );
  }

  _updateProgress(double val) {
    _target = val;
    _tween.begin = _tween.end;
    _controller.reset();
    _tween.end = val;
    _controller.forward();
  }

  /// 喜欢按钮
  void initFavorite() async {
    var localGame = await DuckDao.getGame(widget.game.id);
    if (localGame != null) {
      LOG.D(_TAG, "initFavorite: 本地游戏喜欢${localGame.favorite}");
      setState(() {
        widget.game.favorite = localGame.favorite;
      });
    }
  }

  /// 下载进度
  void initDownloading() async {
    LOG.D(_TAG, "initDownloading：初始化");
    eventBus.on<DownloadEvent>().listen((event) {
      LOG.D(_TAG, "initDownloading：收到");
      if (event.downloadTask!.gameId == widget.game.id) {
        this.downloadEvent = event;
        if (mounted) {
          setState(() {
            switch (event.downloadState) {
              case DOWNLOAD_STATE_UNKNOWN:
                break;
              case DOWNLOAD_STATE_START:
                break;
              case DOWNLOAD_STATE_PROGRESS:
                var val = event.downloadTask!.percent! / 100;
                LOG.D(_TAG, "下载进度：$val");
                _updateProgress(val);
                break;
              case DOWNLOAD_STATE_MERGING:
                break;
              case DOWNLOAD_STATE_UNZIPPING:
                break;
              case DOWNLOAD_STATE_FINISH:
                break;
              // case DOWNLOAD_STATE_ERROR:
              //   DuckGame.instance
              //       .showMsgDialog(context, S.of(context).Download_Error, "Error: " + event.downloadTask!.msg!);
              //   break;
            }
          });
        }
      }
    });
  }

  Future<void> setAnimition() async {
    animationController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    animation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: animationController, curve: Interval(0, 1.0, curve: Curves.fastOutSlowIn)));

    animationController.forward();
    await Future<dynamic>.delayed(const Duration(milliseconds: 200));
    setState(() {
      opacity1 = 1.0;
    });
    await Future<dynamic>.delayed(const Duration(milliseconds: 200));
    setState(() {
      opacity2 = 1.0;
    });
    await Future<dynamic>.delayed(const Duration(milliseconds: 200));
    setState(() {
      opacity3 = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    Orientation orientation = MediaQuery.of(context).orientation;

    return Scaffold(
      body: orientation == Orientation.portrait ? buildPortLayout(context) : buildLandscapeLayout(context),
    );
  }

  Widget buildPortLayout(BuildContext context) {
    const picHeight = 320.00;
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: <Widget>[
              /// 游戏图片
              uiGamePic(double.infinity, picHeight),

              /// 游戏名字
              Positioned(
                child: uiGameName(context),
                top: picHeight - 24,
                bottom: 0,
                right: 0,
                left: 0,
              ),

              /// 喜欢按钮
              uiGameLike(context, picHeight - 24 - 35, 35),

              /// 返回按钮
              uiGameBack(context, MediaQuery.of(context).padding.top)
            ],
          ),
        ),

        /// 开始游戏按钮
        uiBottomBtns(context),
      ],
    );
  }

  Widget uiGamePic(double? width, double height) {
    return Container(
      width: width,
      height: height,
      child: CachedNetworkImage(
        imageUrl: Api.HOST + widget.game.photo!,
        fit: BoxFit.cover,
      ),
    );
  }

  buildLandscapeLayout(BuildContext context) {
    return Row(children: [
      Flexible(
        child: Stack(
          children: [
            uiGamePic(double.infinity, double.infinity),
            uiGameBack(context, 25),
          ],
        ),
        flex: 1,
        fit: FlexFit.tight,
      ),
      Flexible(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: uiGameName(context),
                  ),
                ),
                uiBottomBtns(context)
              ],
            ),
            uiGameLike(context, 16, 16),
          ],
        ),
        flex: 1,
        fit: FlexFit.tight,
      )
    ]);
  }

  Container uiBottomBtns(BuildContext context) {
    Widget child = Container();

    switch (downloadEvent.downloadState) {
      case DOWNLOAD_STATE_START:
        child = Container(
            color: Colors.green[50]!,
            height: 40,
            child: Center(
                child: Text(
              S.of(context).Please_wait,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                letterSpacing: 0.0,
                color: AppTheme.primaryContainer,
              ),
            )));
        break;
      case DOWNLOAD_STATE_PROGRESS:
        child = uiProgressBar();
        break;
      case DOWNLOAD_STATE_MERGING:
        child = uiMergingOrUnzipping(S.of(context).Merging_file);
        break;
      case DOWNLOAD_STATE_UNZIPPING:
        child = uiMergingOrUnzipping(S.of(context).Unzipping);
        break;
      case DOWNLOAD_STATE_UNKNOWN:
      case DOWNLOAD_STATE_FINISH:
        child = uiStartOrDownloadOrContinue();
        break;
      case DOWNLOAD_STATE_PAUSE:
      case DOWNLOAD_STATE_ERROR:
        child = uiDownloadButton();
        break;
    }

    return Container(
      height: 56,
      color: AppTheme.surface1,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: opacity3,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, left: 16, bottom: 8, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // 网络游戏
              if (widget.game.gameType!.name == "N64" || widget.game.gameType!.name == "MAME")
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      height: 40,
                      color: AppTheme.btNetplay,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.all(
                            Radius.circular(24.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_rounded),
                              SizedBox(
                                width: 8,
                              ),
                              Center(
                                  child: Text(
                                S.of(context).NetPlay,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  letterSpacing: 0.0,
                                  color: AppTheme.white,
                                ),
                              )),
                            ],
                          ),
                          onTap: () => {DuckGame.instance.onNetPlayGame(context, widget.game)},
                        ),
                      )),
                ),
              if (widget.game.gameType!.name == "N64" || widget.game.gameType!.name == "MAME")
                SizedBox(
                  width: 16,
                ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: child,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Container uiMergingOrUnzipping(String s) {
    return Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
          colors: [Colors.orangeAccent, Colors.orangeAccent[400]!],
        )),
        height: 40,
        child: Center(
          child: AnimatedTextKit(
            repeatForever: true,
            animatedTexts: [
              WavyAnimatedText(
                s,
                textStyle: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ));
  }

  Padding uiGameBack(BuildContext context, double top) {
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: SizedBox(
        width: AppBar().preferredSize.height,
        height: AppBar().preferredSize.height,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Material(
            color: Colors.transparent,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.black26,
                shape: CircleBorder(),
              ),
              child: Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
    );
  }

  Positioned uiGameLike(BuildContext context, double top, double right) {
    return Positioned(
      top: top,
      right: right,
      child: ScaleTransition(
        alignment: Alignment.center,
        scale: CurvedAnimation(parent: animationController, curve: Curves.fastOutSlowIn),
        child: Card(
          color: AppTheme.primary.withOpacity(0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0)),
          elevation: 10.0,
          child: Container(
            width: 60,
            height: 60,
            child: Center(
              child: LikeButton(
                likeBuilder: (bool isLiked) {
                  return Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 32,
                    color: isLiked ? Colors.red : Colors.white,
                  );
                },
                isLiked: widget.game.favorite ?? false,
                onTap: onLikeButtonTapped,
                // likeCount: widget.game.starCount,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget uiGameName(BuildContext context) {
    final double tempHeight = MediaQuery.of(context).size.height - (MediaQuery.of(context).size.width / 1.2) + 24.0;

    var screenSize = MediaQuery.of(context).size;
    var width = screenSize.width;
    var height = screenSize.height;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(32.0), topRight: Radius.circular(32.0)),
        boxShadow: <BoxShadow>[
          BoxShadow(color: AppTheme.grey.withOpacity(0.2), offset: const Offset(1.1, 1.1), blurRadius: 10.0),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 8),
        child: Container(
          constraints: BoxConstraints(minHeight: 100, maxHeight: height - 56),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 32.0, left: 18, right: 16),
                child: Text(
                  widget.game.name!,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                    letterSpacing: 0.27,
                    color: AppTheme.mainText,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      child: Row(
                        children: <Widget>[
                          Text(
                            widget.game.starCount.toString() + ' ',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontWeight: FontWeight.w200,
                              fontSize: 22,
                              letterSpacing: 0.27,
                              color: AppTheme.mainText,
                            ),
                          ),
                          Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 16,
                    ),
                    Container(
                      padding: const EdgeInsets.all(3.0),
                      decoration: new BoxDecoration(
                        border: new Border.all(color: Colors.orange, width: 0.8), // 边色与边宽度
                        borderRadius: new BorderRadius.all(Radius.circular(20)), // 也可控件一边圆角大小
                      ),
                      child: Text(
                        widget.game.gameType!.name!,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.w300,
                          fontSize: 12,
                          letterSpacing: 0.27,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    Spacer(),
                    // InkWell(
                    //   customBorder: CircleBorder(),
                    //   child: Padding(
                    //     padding: const EdgeInsets.all(2.0),
                    //     child: Icon(
                    //       Icons.bug_report_outlined,
                    //       color: Colors.grey.withOpacity(0.6),
                    //     ),
                    //   ),
                    //   onTap: () {
                    //     DuckGame.instance.showGameBugDialog(context, widget.game, () {
                    //       onReportBug();
                    //     });
                    //   },
                    // ),
                    // SizedBox(
                    //   width: 8,
                    // ),
                    Material(
                      color: Colors.transparent,
                      child: FutureBuilder<bool>(
                        future: DuckGame.instance.isRomExist(widget.game),
                        builder: (context, existData) {
                          return existData.data != null && existData.data!
                              ? Row(
                                  children: [
                                    Text(
                                      widget.game.size!,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w200,
                                        fontSize: 14,
                                        letterSpacing: 0.27,
                                        color: AppTheme.mainText,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 8,
                                    ),
                                    InkWell(
                                      customBorder: CircleBorder(),
                                      child: Padding(
                                        padding: const EdgeInsets.all(2.0),
                                        child: Icon(
                                          Icons.delete_outlined,
                                          color: Colors.red,
                                        ),
                                      ),
                                      onTap: () {
                                        DuckGame.instance.onDeleteGame(context, widget.game, () {
                                          setState(() {});
                                        });
                                      },
                                    ),
                                  ],
                                )
                              : Container();
                        },
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: opacity2,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
                      child: Text(
                        widget.game.summary!,
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          fontWeight: FontWeight.w200,
                          fontSize: 14,
                          letterSpacing: 0.27,
                          color: AppTheme.secondText,
                        ),
                        maxLines: 100,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).padding.bottom,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget uiPlayGame() {
    return Container(
        height: 40,
        decoration: BoxDecoration(
            gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryContainer],
        )),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.all(
              Radius.circular(24.0),
            ),
            child: BlinkingContainer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.games_rounded),
                  SizedBox(
                    width: 8,
                  ),
                  Center(
                      child: Text(
                    S.of(context).START,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: 0.0,
                      color: AppTheme.white,
                    ),
                  )),
                ],
              ),
            ),
            onTap: () => {DuckGame.instance.onPlayGame(context, widget.game)},
          ),
        ));
  }

  Future<bool> onLikeButtonTapped(bool isLiked) async {
    /// send your request here
    DuckAnalytics.analytics.logEvent(name: "like_a_game", parameters: <String, dynamic>{
      'game_name': widget.game.name,
    });

    widget.game.favorite = !isLiked;
    await DuckDao.insertOrUpdateGame(widget.game);
    eventBus.fire(RefreshFavoriteEvent());

    if (widget.game.favorite!) {
      AppRepo().like(widget.game.id).listen((data) {
        if (mounted) {
          setState(() {
            widget.game.starCount = Game.fromMap(data).starCount;
          });
        }
      }, onError: (e) {});
    }

    /// if failed, you can do nothing
    // return success? !isLiked:isLiked;

    return !isLiked;
  }

  Widget getTimeBoxUI(String text1, String txt2) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.nearlyWhite,
          borderRadius: const BorderRadius.all(Radius.circular(24.0)),
          boxShadow: <BoxShadow>[
            BoxShadow(color: AppTheme.grey.withOpacity(0.2), offset: const Offset(1.1, 1.1), blurRadius: 8.0),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 18.0, right: 18.0, top: 12.0, bottom: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                text1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.27,
                  color: AppTheme.primary,
                ),
              ),
              Text(
                txt2,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w200,
                  fontSize: 14,
                  letterSpacing: 0.27,
                  color: AppTheme.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onReportBug() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    var version = packageInfo.version;

    var androidInfo = DuckGame.androidInfo;
    var release = androidInfo.version.release;
    var sdkInt = androidInfo.version.sdkInt;
    var manufacturer = androidInfo.manufacturer;
    var model = androidInfo.model;
    var deviceInfo = 'Android $release (SDK $sdkInt), $manufacturer $model';

    var query = 'subject=Video Game: ${widget.game.name}&body=App Version: $version\nDevice:$deviceInfo\n\n\n\n';

    final Uri _emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@actduck.com',
      query: query,
    );

    launchURL(_emailLaunchUri.toString());
    DuckAds.instance.dontShowOpenAd();
  }

  _onGetGame(BuildContext context) async {
    var canPlay = await DuckGame.instance.canPlayGame(context, widget.game);
    if (canPlay) {
      DuckGame.instance.legalDownloadRom(context, () async {
        DuckGame.instance.downloadRoms(widget.game);
      });
    }
  }

  @override
  void dispose() {
    // DuckAds.instance.disposeInterstitialAd();
    super.dispose();
  }

  Widget uiProgressBar() {
    return InkWell(
      onTap: () => {DuckGame.instance.pauseDownload(widget.game)},
      child: Stack(
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(20.0)),
              border: new Border.all(color: AppTheme.primary, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(24)),
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _animation.value,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green[300]!),
                    backgroundColor: Colors.green[50]!,
                  );
                },
              ),
            ),
          ),
          Container(
            height: 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  flex: 1,
                  child: Container(),
                ),
                Flexible(
                  flex: 1,
                  child: Center(
                    child: Text(
                      Utils.getDownloadPercent(widget.game, downloadEvent.downloadTask!.percent!),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        letterSpacing: 0.0,
                        color: AppTheme.primaryContainer,
                      ),
                    ),
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: Text(
                    "(${Utils.getDownloadSpeed(widget.game, downloadEvent.downloadTask!.percent!)})",
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 10,
                      letterSpacing: 0.0,
                      color: AppTheme.primaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget uiStartOrDownloadOrContinue() {
    return Shimmer(
      child: FutureBuilder<bool>(
          future: DuckGame.instance.isRomExist(widget.game),
          builder: (context, existData) {
            if (existData.data == null) {
              return Container(
                color: Colors.green[50],
              );
            } else if (existData.data!) {
              return uiPlayGame();
            } else {
              return uiDownloadButton();
            }
          }),
    );
  }

  Widget uiDownloadButton() {
    return FutureBuilder<bool>(
      future: DuckGame.instance.isTmpFileExist(widget.game),
      builder: (context, existData) {
        if (existData.data == null) {
          return Container(
            color: Colors.orange[50],
          );
        } else if (existData.data!) {
          return uiContinueDownloadGame();
        } else {
          return uiDownloadGame();
        }
      },
    );
  }

  Widget uiDownloadGame() {
    return Container(
        height: 40,
        decoration: BoxDecoration(
            gradient: LinearGradient(
          colors: [AppTheme.Ocean3, AppTheme.Shadow3],
        )),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.all(
              Radius.circular(24.0),
            ),
            child: Center(
                child: Text(
              S.of(context).Download + " " + widget.game.size!,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: 0.0,
                color: AppTheme.onPrimary,
              ),
            )),
            onTap: () => {_onGetGame(context)},
          ),
        ));
  }

  Container uiContinueDownloadGame() {
    return Container(
        height: 40,
        color: Colors.orange,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.all(
              Radius.circular(24.0),
            ),
            child: Center(
                child: Text(
              S.of(context).Continue,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                letterSpacing: 0.0,
                color: AppTheme.nearlyWhite,
              ),
            )),
            onTap: () => {_onGetGame(context)},
          ),
        ));
  }
}
