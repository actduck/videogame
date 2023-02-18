//import 'dart:async';
//
//import 'package:cached_network_image/cached_network_image.dart';
//import 'package:dio/dio.dart';
//import 'package:facebook_audience_network/ad/ad_instream.dart';
//import 'package:facebook_audience_network/ad/ad_interstitial.dart';
//import 'package:facebook_audience_network/ad/ad_native.dart';
//import 'package:flutter/cupertino.dart';
//import 'package:flutter/gestures.dart';
//import 'package:flutter/material.dart';
//import 'package:flutter_share_me/flutter_share_me.dart';
//import 'package:fluttertoast/fluttertoast.dart';
//import 'package:like_button/like_button.dart';
//import 'package:path_provider/path_provider.dart';
//import 'package:photo_view/photo_view.dart';
//import 'package:photo_view/photo_view_gallery.dart';
//import 'package:videogame/common/platform_adaptive_progress_indicator.dart';
//import 'package:videogame/constants.dart';
//import 'package:videogame/model/list_item.dart';
//
//import 'package:videogame/net/app_repo.dart';
//import 'package:videogame/util/utils.dart';
//import 'package:flutter/foundation.dart';
//import '../duck_ads_id.dart';
//
//const kTranslucentBlackColor = const Color(0x66000000);
//const _kMaxDragSpeed = 400.0;
//
//class FullScreenImagePage extends StatefulWidget {
//  int initialIndex;
//  final List<ListItem> galleryItems;
//  final PageController pageController;
//
//  FullScreenImagePage(
//    this.initialIndex,
//    this.galleryItems,
//  ) : pageController = PageController(initialPage: initialIndex);
//
//  @override
//  _FullScreenImageState createState() => new _FullScreenImageState();
//}
//
//class _FullScreenImageState extends State<FullScreenImagePage>
//    with TickerProviderStateMixin {
//  final LinearGradient backgroundGradient = new LinearGradient(
//      colors: [new Color(0x00000000), new Color(0x00000000)],
//      begin: Alignment.topLeft,
//      end: Alignment.bottomRight);
//
//  String wallpaper;
//  bool visible = true;
//  bool showingAd = false;
//  int currentIndex;
//
//  Stream<String> progressString;
//  String res;
//  bool downloading = false;
//
//  Tumblr tumblr;
//  bool like = false;
//
//  var result = "Waiting to set wallpaper";
//
//  AppRepo appRepo = new AppRepo();
//
//  var scaleControler;
//
//  void onPageChanged(int index) {
//    setState(() {
//      currentIndex = index;
//      ListItem item = widget.galleryItems[currentIndex];
//      if (item is Tumblr) {
//        tumblr = item;
//        showingAd = false;
//      } else if (item is AdItem) {
//        loadFacebookInterstitialAd();
//        showingAd = true;
//      }
//    });
//  }
//
//  @override
//  void initState() {
//    super.initState();
//
//    tumblr = widget.galleryItems[widget.initialIndex];
//
//    scaleControler = new PhotoViewScaleStateController();
//
//    _offsetController =
//        AnimationController(vsync: this, duration: Duration.zero);
//    _offsetTween = Tween<Offset>(begin: Offset.zero, end: Offset.zero);
//    _offsetAnimation = _offsetTween.animate(
//      CurvedAnimation(
//        parent: _offsetController,
//        curve: Curves.easeOut,
//      ),
//    );
//
//    _opacityController =
//        AnimationController(vsync: this, duration: Duration.zero);
//    _opacityTween = Tween<double>(begin: 1.0, end: 0.0);
//    _opacityAnimation = _opacityTween.animate(_opacityController);
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    return FadeTransition(
//      opacity: _opacityAnimation,
//      child: new CupertinoPageScaffold(
//        child: new Container(
//          decoration: new BoxDecoration(color: Colors.black),
//          constraints: BoxConstraints.expand(
//            height: MediaQuery.of(context).size.height,
//          ),
//          child: GestureDetector(
//            onLongPress: kReleaseMode
//                ? null
//                : () {
//                    showRemoveDialog(context);
//                  },
//            onTap: () {
//              setState(() {
//                visible = !visible;
//              });
//            },
//            child: new Stack(
//              children: <Widget>[
//                OffsetTransition(
//                  offset: _offsetAnimation,
//                  child: _wrapWithCloseGesture(
//                    child: PhotoViewGallery.builder(
//                      scrollPhysics: const BouncingScrollPhysics(),
//                      builder: _buildItem,
//                      itemCount: widget.galleryItems.length,
//                      pageController: widget.pageController,
//                      scaleStateChangedCallback: onScaleChange,
//                      backgroundDecoration: const BoxDecoration(
//                        color: Colors.black,
//                      ),
//                      onPageChanged: onPageChanged,
//                    ),
//                  ),
//                ),
//
////              GestureDetector(
////                onTap: () {
////                  setState(() {
////                    visible = !visible;
////                  });
////                },
//////                onVerticalDragStart: canFinish ? onVs : null,
//////                onVerticalDragEnd: canFinish ? onVe : null,
////
////
////              ),
//                Visibility(
//                  child: new Align(
//                    alignment: Alignment.topCenter,
//                    child: new Column(
//                      mainAxisAlignment: MainAxisAlignment.start,
//                      mainAxisSize: MainAxisSize.min,
//                      children: <Widget>[
//                        new AppBar(
//                          elevation: 0.0,
//                          backgroundColor: Colors.black12,
//                          leading: null,
//                          actions: <Widget>[
//                            LikeButton(
//                              likeBuilder: (bool isLiked) {
//                                return Icon(
//                                  Icons.favorite,
//                                  color: isLiked ? Colors.red : Colors.white,
//                                );
//                              },
//                              likeCount: tumblr.star,
//                              countBuilder:
//                                  (int count, bool isLiked, String text) {
//                                var color = isLiked ? Colors.red : Colors.white;
//                                Widget result;
//                                if (count == 0) {
//                                  result = Text(
//                                    "Like",
//                                    style: TextStyle(color: color),
//                                  );
//                                } else
//                                  result = Text(
//                                    text,
//                                    style: TextStyle(color: color),
//                                  );
//                                return result;
//                              },
//                              onTap: (bool isLiked) {
//                                return _like();
//                              },
//                            ),
//                            IconButton(
//                              icon: Icon(Icons.wallpaper),
//                              onPressed: () {
//                                showWallpaperDialog(
//                                    context: context,
//                                    child: new CupertinoWallpaperDialog());
//                              },
//                            ),
//                            IconButton(
//                              icon: Icon(Icons.share),
//                              onPressed: () {
//                                showShareDialog(
//                                    context: context,
//                                    child: new CupertinoShareDialog());
//                              },
//                            ),
//                          ],
//                        )
//                      ],
//                    ),
//                  ),
//                  maintainSize: true,
//                  maintainAnimation: true,
//                  maintainState: true,
//                  visible: visible && !showingAd,
//                ),
//              ],
//            ),
//          ),
//        ),
//      ),
//    );
//  }
//
//  bool _isLocked = false;
//
//  int _pointersOnScreen = 0;
//
//  Widget _wrapWithCloseGesture({Widget child}) {
//    return Listener(
//      onPointerDown: (event) {
//        _pointersOnScreen++;
//        setState(() => _isLocked = _pointersOnScreen >= 2);
//      },
//      onPointerUp: (event) => _pointersOnScreen--,
//      child: GestureDetector(
//        dragStartBehavior: DragStartBehavior.down,
//        onVerticalDragStart: _isLocked ? null : _onDragStart,
//        onVerticalDragUpdate: _isLocked
//            ? null
//            : (details) {
//                _onDrag(details.globalPosition.dy - _start);
//              },
//        onVerticalDragCancel: _isLocked ? null : () => _onDragEnd(0.0),
//        onVerticalDragEnd: _isLocked
//            ? null
//            : (details) {
//                _onDragEnd(details.velocity.pixelsPerSecond.dy);
//              },
//        child: child,
//      ),
//    );
//  }
//
//  AnimationController _opacityController;
//  Animation<double> _opacityAnimation;
//  Tween<double> _opacityTween;
//  double _start;
//  AnimationController _offsetController;
//  Animation<Offset> _offsetAnimation;
//  Tween<Offset> _offsetTween;
//  bool _isDragging = false;
//
//  void _onDragStart(DragStartDetails details) {
//    _start = details.globalPosition.dy;
//
//    setState(() => _isDragging = true);
//  }
//
//  void _onDragEnd(double velocity) {
//    _start = null;
//
//    if (velocity > _kMaxDragSpeed ||
//        _offsetTween.end.dy >= MediaQuery.of(context).size.height / 2) {
//      Navigator.of(context).pop();
//    } else {
//      _opacityTween.begin = _opacityTween.end;
//      _opacityTween.end = 1.0;
//      _opacityController.duration = Duration(milliseconds: 0);
//      _opacityController.reset();
//      _opacityController.forward();
//
//      _offsetTween.begin = Offset(0, _offsetTween.end.dy);
//      _offsetTween.end = Offset.zero;
//      _offsetController.duration = Duration(milliseconds: 200);
//      _offsetController.reset();
//      _offsetController.forward();
//    }
//
//    setState(() => _isDragging = false);
//  }
//
//  void _onDrag(double dy) {
//    if (dy < 0) {
//      return;
//    }
//    _offsetTween.begin = Offset.zero;
//    _offsetTween.end = Offset(0, dy);
//
//    _offsetController.duration = Duration.zero;
//    _offsetController.reset();
//    _offsetController.forward();
//
//    _opacityTween.begin = _opacityTween.end;
//    _opacityTween.end =
//        mapValue(dy, 0, MediaQuery.of(context).size.height, 1.0, 0.0);
//    _opacityController.duration = Duration.zero;
//    _opacityController.reset();
//    _opacityController.forward();
//  }
//
//  PhotoViewGalleryPageOptions _buildItem(BuildContext context, int index) {
//    final ListItem item = widget.galleryItems[index];
//    return item is Tumblr
//        ? PhotoViewGalleryPageOptions(
//            imageProvider: CachedNetworkImageProvider(item.url),
//            initialScale: PhotoViewComputedScale.contained,
//            minScale: PhotoViewComputedScale.contained,
//            maxScale: PhotoViewComputedScale.covered * 2.0,
//            scaleStateController: scaleControler,
//            heroAttributes: PhotoViewHeroAttributes(tag: item.url))
//        : PhotoViewGalleryPageOptions.customChild(
//            child: Center(child: buildInStreamVideoAd()),
//            childSize: Size(MediaQuery.of(context).size.width,
//                MediaQuery.of(context).size.height));
//  }
//
//  /// 功能START=============================
//
//  void showWallpaperDialog({BuildContext context, Widget child}) {
//    showCupertinoDialog<String>(
//      context: context,
//      builder: (BuildContext context) => child,
//    ).then((String value) {
//      if (value != null && value != "cancel") {}
//    });
//  }
//
//  static Stream<String> downloadImage(String url) async* {
//    StreamController<String> streamController = new StreamController();
//    try {
//      final dir = await getExternalStorageDirectory();
//      print(dir);
//      Dio dio = new Dio();
//      dio
//          .download(
//            url,
//            "${dir.path}/myShare.jpg",
//            onReceiveProgress: (int received, int total) {
//              streamController
//                  .add(((received / total) * 100).toStringAsFixed(0) + "%");
//            },
//          )
//          .then((Response response) {})
//          .catchError((ex) {
//            streamController.add(ex.toString());
//          })
//          .whenComplete(() {
//            streamController.close();
//          });
//      yield* streamController.stream;
//    } catch (ex) {
//      throw ex;
//    }
//  }
//
//  void showShareDialog({BuildContext context, Widget child}) {
//    showCupertinoDialog<String>(
//      context: context,
//      builder: (BuildContext context) => child,
//    ).then((String value) {
//      if (value != null && value != "cancel") {
//        _share(context, value);
//      }
//    });
//  }
//
//  void _share(BuildContext context, String value) async {
//    switch (value) {
//      case "facebook":
//        {
//          FlutterShareMe().shareToFacebook(
//              url: share_url, msg: share_msg);
//        }
//        break;
//      case "twitter":
//        {
//          var response = await FlutterShareMe()
//              .shareToTwitter(url: share_url, msg: share_msg);
//          if (response == 'success') {
//            print('navigate success');
//          }
//        }
//        break;
//      case "whatsapp":
//        {
////          downloadImage(tumblr.url).listen((data) {}, onDone: () async {
////            final dir = await getExternalStorageDirectory();
////
////          });
//          FlutterShareMe().shareToWhatsApp(
//              base64Image: tumblr.url, msg: share_msg);
//        }
//        break;
//      case "system":
//        {
//          var response =
//              await FlutterShareMe().shareToSystem(msg: share_msg);
//          if (response == 'success') {
//            print('navigate success');
//          }
//        }
//        break;
//    }
//  }
//
//  Future<bool> _like() {
//    final Completer<bool> completer = new Completer<bool>();
//
//    appRepo.likeSister(tumblr.id).listen((data) {
//      like = !like;
//      completer.complete(like);
//    }, onError: (e) {
//      print(e);
//      completer.complete(null);
//    });
//
//    return completer.future;
//  }
//
//
//  /// 功能END=============================
//
//  /// 广告START================================
//  Widget buildFBNative() {
//    return FacebookNativeAd(
//      placementId: AdId.FB_NATIVE,
//      adType: NativeAdType.NATIVE_AD,
//      width: double.infinity,
//      height: double.infinity,
//      backgroundColor: Colors.blue,
//      titleColor: Colors.white,
//      descriptionColor: Colors.white,
//      buttonColor: Colors.deepPurple,
//      buttonTitleColor: Colors.white,
//      buttonBorderColor: Colors.white,
//      listener: (result, value) {
//        print("Native Ad: $result --> $value");
//      },
//    );
//  }
//
//  Widget buildInStreamVideoAd() {
//    return FacebookInStreamVideoAd(
//      placementId: AdId.FB_NATIVE_VIDEO,
//      height: 300,
//      listener: (result, value) {
//        if (result == InStreamVideoAdResult.VIDEO_COMPLETE) {
//          setState(() {});
//        }
//      },
//    );
//  }
//
//  void loadFacebookInterstitialAd() {
//    FacebookInterstitialAd.loadInterstitialAd(
//      placementId: AdId.FB_IN,
//      listener: (result, value) {
//        if (result == InterstitialAdResult.LOADED) {
//          FacebookInterstitialAd.showInterstitialAd(delay: 0);
//        }
//      },
//    );
//  }
//
//  /// 广告END================================
//
//  void onScaleChange(PhotoViewScaleState scaleState) {
//    setState(() {
//      _isLocked = scaleState != PhotoViewScaleState.initial;
//    });
//  }
//
//  showRemoveDialog(context) {
//    showCupertinoDialog<String>(
//        context: context,
//        builder: (context) {
//          return new CupertinoAlertDialog(
//            title: new Text(S.of(context).要删除吗？"),
//            actions: <Widget>[
//              CupertinoDialogAction(
//                child: const Text('确定'),
//                onPressed: () {
//                  Navigator.pop(context);
//
//                },
//              ),
//              CupertinoDialogAction(
//                child: const Text('取消'),
//                isDestructiveAction: true,
//                onPressed: () {
//                  Navigator.pop(context);
//                },
//              ),
//            ],
//          );
//        });
//  }
//}
//
//class CupertinoWallpaperDialog extends StatelessWidget {
//  const CupertinoWallpaperDialog({Key key, this.title, this.content})
//      : super(key: key);
//
//  final Widget title;
//  final Widget content;
//
//  @override
//  Widget build(BuildContext context) {
//    return CupertinoAlertDialog(
//      title: title,
//      content: content,
//      actions: <Widget>[
//        CupertinoDialogAction(
//          child: const Text('Home Screen'),
//          onPressed: () {
//            Navigator.pop(context, "home");
//          },
//        ),
//        CupertinoDialogAction(
//          child: const Text('Lock Screen'),
//          onPressed: () {
//            Navigator.pop(context, "lock");
//          },
//        ),
//        CupertinoDialogAction(
//          child: const Text('Home Screen & Lock Screen'),
//          onPressed: () {
//            Navigator.pop(context, "both");
//          },
//        ),
//        CupertinoDialogAction(
//          child: const Text('Cancel'),
//          isDestructiveAction: true,
//          onPressed: () {
//            Navigator.pop(context, "cancel");
//          },
//        ),
//      ],
//    );
//  }
//}
//
//class CupertinoShareDialog extends StatelessWidget {
//  const CupertinoShareDialog({Key key, this.title, this.content})
//      : super(key: key);
//
//  final Widget title;
//  final Widget content;
//
//  @override
//  Widget build(BuildContext context) {
//    return CupertinoAlertDialog(
//      title: title,
//      content: content,
//      actions: <Widget>[
//        CupertinoDialogAction(
//          child: const Text('Twitter'),
//          onPressed: () {
//            Navigator.pop(context, "twitter");
//          },
//        ),
//        CupertinoDialogAction(
//          child: const Text('Facebook'),
//          onPressed: () {
//            Navigator.pop(context, "facebook");
//          },
//        ),
//        CupertinoDialogAction(
//          child: const Text('WhatsApp'),
//          onPressed: () {
//            Navigator.pop(context, "whatsapp");
//          },
//        ),
//        CupertinoDialogAction(
//          child: const Text('System'),
//          onPressed: () {
//            Navigator.pop(context, "system");
//          },
//        ),
//        CupertinoDialogAction(
//          child: const Text('Cancel'),
//          isDestructiveAction: true,
//          onPressed: () {
//            Navigator.pop(context, "cancel");
//          },
//        ),
//      ],
//    );
//  }
//}
//
//double mapValue(
//    double value, double low1, double high1, double low2, double high2) {
//  return low2 + (high2 - low2) * (value - low1) / (high1 - low1);
//}
//
//int mapToRange(int value, int low, int high) {
//  assert(low <= high);
//  if (value >= low && value <= high) {
//    return value;
//  }
//
//  int len = high - low + 1;
//  return value % len;
//}
//
//class OffsetTransition extends AnimatedWidget {
//  const OffsetTransition({
//    Key key,
//    @required Animation<Offset> offset,
//    this.child,
//  }) : super(key: key, listenable: offset);
//
//  final Widget child;
//
//  Animation<Offset> get offset => listenable;
//
//  @override
//  Widget build(BuildContext context) {
//    return Transform.translate(
//      offset: offset.value,
//      child: child,
//    );
//  }
//}
