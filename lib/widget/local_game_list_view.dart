import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:videogame/app_theme.dart';
import 'package:videogame/model/game.dart';
import 'package:videogame/model/list_item.dart';

typedef void MenuClickCallback(int i, Game game);

class LocalGameListView extends StatefulWidget {
  const LocalGameListView({Key? key, this.list, this.onGameClick, this.onMenuClick}) : super(key: key);

  final List<ListItem>? list;

  final Function? onGameClick;
  final MenuClickCallback? onMenuClick;

  @override
  _LocalGameListViewState createState() => _LocalGameListViewState();
}

class _LocalGameListViewState extends State<LocalGameListView> with TickerProviderStateMixin {
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

    return Container(
      height: 192 + (rate - 1) * 30,
      width: double.infinity,
      child: FutureBuilder<bool>(
        future: getData(),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox();
          } else {
            return ListView.builder(
              padding: const EdgeInsets.only(right: 16, left: 16),
              itemCount: widget.list!.length,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemBuilder: (BuildContext context, int index) {
                final int count = widget.list!.length > 10 ? 10 : widget.list!.length;
                final Animation<double> animation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
                    parent: animationController!,
                    curve: Interval((1 / count) * index, 1.0, curve: Curves.fastOutSlowIn)));
                animationController!.forward();
                var listItem = widget.list![index];

                if (listItem is Game) {
                  return Wrap(children: [
                    GameView(
                      game: listItem,
                      animation: animation,
                      animationController: animationController,
                      onClick: () {
                        widget.onGameClick!(widget.list![index]);
                      },
                      onMenuClick: (i, game) {
                        widget.onMenuClick!(i, game);
                      },
                      randomColor: Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0),
                    ),
                  ]);
                } else {
                  // todo 广告
                  return Container();
                }
              },
            );
          }
        },
      ),
    );
  }
}

class GameView extends StatelessWidget {
  const GameView(
      {Key? key, this.game, this.animationController, this.animation, this.onClick, this.randomColor, this.onMenuClick})
      : super(key: key);

  final VoidCallback? onClick;
  final MenuClickCallback? onMenuClick;
  final Game? game;
  final AnimationController? animationController;
  final Animation<dynamic>? animation;
  final Color? randomColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (BuildContext context, Widget? child) {
        var placeHolderImg = Container(
            child: Center(
              child: Text(
                completeTitle(game!.name!),
                style: TextStyle(fontSize: 48, color: AppTheme.white, fontWeight: FontWeight.w300),
              ),
            ),
            decoration: new BoxDecoration(
              color: randomColor,
            ));

        return FadeTransition(
          opacity: animation as Animation<double>,
          child: Transform(
            transform: Matrix4.translationValues(100 * (1.0 - animation!.value), 0.0, 0.0),
            child: Container(
              width: 144,
              margin: const EdgeInsets.only(right: 16.0),
              child: CupertinoContextMenu(
                  previewBuilder: (BuildContext context, Animation<double> animation, Widget child) {
                    return Material(
                      color: Colors.transparent,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        // This ClipRRect rounds the corners of the image when the
                        // CupertinoContextMenu is open, even though it's not rounded when
                        // it's closed. It uses the given animation to animate the corners
                        // in sync with the opening animation.
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0 * animation.value),
                          child: CachedNetworkImage(
                              width: 144,
                              height: 144,
                              placeholder: (context, url) => placeHolderImg,
                              imageUrl: game!.photo!,
                              errorWidget: (context, url, e) => placeHolderImg,
                              fit: BoxFit.cover),
                        ),
                      ),
                    );
                  },
                  actions: [
                    /*CupertinoContextMenuAction(
                      onPressed: () async {
                        Navigator.pop(context);
                        await Future.delayed(new Duration(microseconds: 600));
                        onMenuClick?.call(0, game!);
                      },
                      child: Text(
                        "Favorite",
                        style: TextStyle(color: AppTheme.primary),
                      ),
                    ),*/
                    CupertinoContextMenuAction(
                      onPressed: () async {
                        Navigator.pop(context);
                        await Future.delayed(new Duration(microseconds: 600));
                        onMenuClick?.call(1, game!);
                      },
                      child: Text(
                        "DELETE",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        splashColor: Colors.transparent,
                        onTap: () {
                          onClick?.call();
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius:
                                  const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                              child: CachedNetworkImage(
                                  width: double.infinity,
                                  height: 144,
                                  placeholder: (context, url) => placeHolderImg,
                                  imageUrl: game!.photo!,
                                  errorWidget: (context, url, e) => placeHolderImg,
                                  fit: BoxFit.cover),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    game!.name!,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 14, color: AppTheme.mainText),
                                  ),
                                  SizedBox(
                                    height: 2,
                                  ),
                                  Text(
                                    game!.gameType == null ? "UnSet" : game!.gameType!.name!,
                                    style: TextStyle(fontSize: 12, color: AppTheme.secondText),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  )),
            ),
          ),
        );
      },
    );
  }

  /**
   * private fun computeTitle(game: Game): String {
      val sanitizedName = game.title
      .replace(Regex("\\(.*\\)"), "")

      return sanitizedName.asSequence()
      .filter { it.isDigit() or it.isUpperCase() or (it == '&') }
      .take(3)
      .joinToString("")
      .ifBlank { game.title.first().toString() }
      .capitalize()
      }
   */
  String completeTitle(String s) {

    String t = "";
    s.split('').forEach((ch) {
      if ((isDigit(ch) || (isLetter(ch.codeUnitAt(0)) && isUppercase(ch)) || ch == '&') && t.length < 3) {
        t += ch;
      }
    });

    if (t.isEmpty) {
      t = s[0];
    }
    return t;
  }

  bool isDigit(String s) {
    if (s == null) {
      return false;
    }
    return int.tryParse(s) != null;
  }

  bool isUppercase(String str) {
    return str == str.toUpperCase();
  }

  bool isLetter(int codeUnit) => (codeUnit >= 65 && codeUnit <= 90) || (codeUnit >= 97 && codeUnit <= 122);

  static String getBaseName(String url) => url.substring(url.lastIndexOf("/") + 1, url.lastIndexOf("."));
}
