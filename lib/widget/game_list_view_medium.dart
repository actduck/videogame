import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:videogame/app_theme.dart';
import 'package:videogame/model/game.dart';
import 'package:videogame/model/list_item.dart';
import 'package:videogame/net/api.dart';
import 'package:videogame/pages/home_page.dart';
import 'package:videogame/util/duck_ads.dart';

import '../common/platform_adaptive_progress_indicator.dart';

class GameListViewMedium extends StatefulWidget {
  const GameListViewMedium({Key? key, this.gamePage, this.controller, this.onGameClick, this.onLongPress, this.onLoadMore})
      : super(key: key);

  final GamePage? gamePage;

  final ScrollController? controller;

  final Function? onGameClick;

  final Function? onLongPress;

  final Function? onLoadMore;

  @override
  _GameListViewMediumState createState() => _GameListViewMediumState();
}

class _GameListViewMediumState extends State<GameListViewMedium> with TickerProviderStateMixin {
  AnimationController? animationController;

  @override
  void initState() {
    animationController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this);
    super.initState();
  }

  Future<bool> getData() async {
    await Future<dynamic>.delayed(const Duration(milliseconds: 50));
    return true;
  }

  @override
  void dispose() {
    animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double rate = MediaQuery.of(context).textScaleFactor;

    // 需要加上一个字体增加的缩放率
    var height = 216 + (rate - 1) * 30;
    return Container(
      height: height,
      width: double.infinity,
      child: FutureBuilder<bool>(
        future: getData(),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox();
          } else {
            var list = widget.gamePage!.content;
            return ListView.builder(
              padding: const EdgeInsets.only(right: 8, left: 8),
              itemCount: list!.length + 1,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              controller: widget.controller,
              itemBuilder: (BuildContext context, int index) {
                // 加载更多要放到前面
                if (index == list.length) {
                  if (widget.gamePage!.last == false) {
                    widget.onLoadMore!(widget.gamePage!.number!);
                    return Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 100,
                          child: Center(child: PlatformAdaptiveProgressIndicator()),
                        ),
                        Container()
                      ],
                    );
                  }
                  return Container();
                }

                ListItem li = list[index];
                if (li is Game) {
                  final int count = list.length > 10 ? 10 : list.length;
                  final Animation<double> animation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
                      parent: animationController!,
                      curve: Interval((1 / count) * index, 1.0, curve: Curves.fastOutSlowIn)));
                  animationController!.forward();

                  return Wrap(
                    children: [
                      GameView(
                        game: li,
                        animation: animation,
                        animationController: animationController,
                        onGameClick: () {
                          widget.onGameClick!(li);
                        },
                        onLongPress: () {
                          widget.onLongPress!(li);
                        },
                      ),
                    ],
                  );
                } else if (li is AdItem) {
                  return DuckAds.instance.NativeAdWidget1(li.nativeAd);
                }
                return Container();
              },
            );
          }
        },
      ),
    );
  }
}

class GameView extends StatelessWidget {
  const GameView({Key? key, this.game, this.animationController, this.animation, this.onGameClick, this.onLongPress})
      : super(key: key);

  final VoidCallback? onGameClick;
  final VoidCallback? onLongPress;
  final Game? game;
  final AnimationController? animationController;
  final Animation<dynamic>? animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: animation as Animation<double>,
          child: Transform(
            transform: Matrix4.translationValues(100 * (1.0 - animation!.value), 0.0, 0.0),
            child: InkWell(
              splashColor: Colors.transparent,
              onTap: () {
                onGameClick!();
              },
              onLongPress: () {
                onLongPress!();
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
                child: Column(
                  children: [
                    // 大图
                    ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                      child: CachedNetworkImage(
                          width: 216,
                          height: 120,
                          placeholder: (context, url) => placeHolderImage,
                          imageUrl: Api.HOST + game!.photo!,
                          fit: BoxFit.cover),
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    // 底下的
                    Container(
                      width: 216,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // 小头像
                          ClipRRect(
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                            child: SizedBox(
                              height: 64,
                              width: 64,
                              child: Semantics(
                                child: ExcludeSemantics(
                                  child: CachedNetworkImage(
                                    imageUrl: Api.HOST + game!.boxArt!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => placeHolderImage,
                                    errorWidget: (context, url, error) => placeHolderImage,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 16,
                          ),
                          Container(
                            width: 136,// 216-64-16
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  game!.name!,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 14, color: AppTheme.mainText),
                                  maxLines: 1,
                                ),
                                // 在下载吗 显示进度条
                                // isThreeLine: true,
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 4,
                                    ),
                                    game!.size == null
                                        ? Container()
                                        : Text(
                                            game!.size! + " | " + game!.gameType!.name!,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: AppTheme.secondText,
                                            ),
                                          ),
                                    SizedBox(
                                      height: 4,
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.center,

                                      children: [
                                        Icon(
                                          Icons.favorite,
                                          size: 10,
                                          color: AppTheme.secondText,
                                        ),
                                        SizedBox(width: 2),
                                        Text(
                                          game!.starCount.toString() + " ",
                                          style: TextStyle(fontSize: 12, color: AppTheme.secondText),
                                        ),
                                      ],
                                    ),
                                    /*Container(
                              margin: const EdgeInsets.only(top: 4),
                              height: 2,
                              child: new LinearProgressIndicator(
                                value: game.task!.progress! / 100,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                                backgroundColor: Color(0xFFFFDAB8),
                              ),
                            ),*/
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    )
                    // Row(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     Container(
                    //       width: 216,
                    //       child: Text(
                    //         game!.name!,
                    //         overflow: TextOverflow.ellipsis,
                    //         style: TextStyle(fontSize: 14, color: AppTheme.mainText),
                    //       ),
                    //     ),
                    //     SizedBox(
                    //       height: 2,
                    //     ),
                    //     Row(
                    //       crossAxisAlignment: CrossAxisAlignment.center,
                    //       mainAxisAlignment: MainAxisAlignment.center,
                    //       children: [
                    //         if (game!.starCount! > 0)
                    //           Row(
                    //             children: [
                    //               Text(
                    //                 game!.starCount.toString() + " ",
                    //                 style: TextStyle(fontSize: 12, color: AppTheme.secondText),
                    //               ),
                    //               Icon(
                    //                 Icons.favorite,
                    //                 size: 10,
                    //                 color: AppTheme.secondText,
                    //               ),
                    //             ],
                    //           ),
                    //         if (game!.createTime!.millisecondsSinceEpoch + 86400000 * 14 >
                    //             DateTime.now().millisecondsSinceEpoch)
                    //           Row(
                    //             children: [
                    //               Text(
                    //                 " • ",
                    //                 style: TextStyle(fontSize: 12, color: AppTheme.secondText),
                    //               ),
                    //               Text(
                    //                 "New",
                    //                 style: TextStyle(fontSize: 12, color: AppTheme.primary),
                    //               ),
                    //             ],
                    //           )
                    //       ],
                    //     ),
                    //   ],
                    // )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
