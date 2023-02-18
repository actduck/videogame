import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:videogame/app_theme.dart';
import 'package:videogame/model/game_type.dart';

import '../generated/l10n.dart';

class GameSystemView extends StatelessWidget {
  const GameSystemView({
    Key? key,
    this.gameType,
    this.onClick,
    this.randomColor,
  }) : super(key: key);

  final VoidCallback? onClick;
  final GameType? gameType;
  final Color? randomColor;

  @override
  Widget build(BuildContext context) {
    var placeHolderImg = Container(
        child: Center(
          child: Text(
            gameType!.name!,
            style: TextStyle(fontSize: 48, color: AppTheme.white, fontWeight: FontWeight.w300),
          ),
        ),
        decoration: new BoxDecoration(
          color: randomColor,
        ));

    return Card(
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
              AspectRatio(
                aspectRatio: 10.5 / 8,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                  child: CachedNetworkImage(
                      width: double.infinity,
                      placeholder: (context, url) => placeHolderImg,
                      imageUrl: gameType!.photo!,
                      errorWidget: (context, url, e) => placeHolderImg,
                      fit: BoxFit.cover),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      gameType!.name!,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16, color: AppTheme.mainText),
                    ),
                    SizedBox(
                      height: 2,
                    ),
                    Text(
                      S.of(context).game_library_count(gameType!.total.toString()),
                      style: TextStyle(fontSize: 13, color: AppTheme.secondText),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
