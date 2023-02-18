import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:videogame/app_theme.dart';
import 'package:videogame/db/db.dart';
import 'package:videogame/model/game.dart';
import 'package:videogame/model/game_and_task.dart';

import '../generated/l10n.dart';
import '../logger.dart';
import '../model/download_event.dart';
import '../pages/main_page.dart';
import '../util/duck_downloader.dart';
import '../util/duck_game.dart';
import '../util/utils.dart';

class GameStartButton extends StatefulWidget {
  late final Game game;

  // late final DownloadEvent event;

  GameStartButton(this.game);

  @override
  State<StatefulWidget> createState() {
    return _GameStartButtonState();
  }
}

class _GameStartButtonState extends State<GameStartButton> {
  static final String _TAG = "GameStartButton";
  late DownloadEvent event;

  @override
  void initState() {
    super.initState();
    event = new DownloadEvent(downloadState: DOWNLOAD_STATE_UNKNOWN);
    _initDownloading();
  }

  /// 下载进度
  void _initDownloading() async {
    LOG.D(_TAG, "initDownloading：初始化");
    eventBus.on<DownloadEvent>().listen((event) {
      if (mounted) {
        LOG.D(_TAG, "initDownloading：收到");
        if (event.downloadTask!.gameId == widget.game.id) {
          this.event = event;
          setState(() {
            switch (event.downloadState) {
              case DOWNLOAD_STATE_UNKNOWN:
                break;
              case DOWNLOAD_STATE_START:
                break;
              case DOWNLOAD_STATE_PROGRESS:
                var val = event.downloadTask!.percent! / 100;
                LOG.D(_TAG, "下载进度：$val");
                // _updateProgress(val);
                break;
              case DOWNLOAD_STATE_MERGING:
                break;
              case DOWNLOAD_STATE_UNZIPPING:
                break;
              case DOWNLOAD_STATE_FINISH:
                break;
            }
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return uiBottomBtns(context);
  }

  Widget uiProgressBar() {
    return InkWell(
      onTap: () => {DuckGame.instance.pauseDownload(widget.game)},
      child: Stack(
        children: [
          Container(
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(20.0)),
              border: new Border.all(color: AppTheme.primary, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(24)),
              child: LinearProgressIndicator(
                value: event.downloadTask!.percent! / 100,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green[300]!),
                backgroundColor: Colors.green[50]!,
              ),
            ),
          ),
          Container(
            height: double.infinity,
            child: Center(
              child: Text(
                Utils.getDownloadSpeed(widget.game, event.downloadTask!.percent!),
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 0.0,
                  color: AppTheme.primaryContainer,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _uiPlayGame() {
    return InkWell(
      onTap: () {
        DuckGame.instance.onPlayGame(context, widget.game);
      },
      child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: const BorderRadius.all(Radius.circular(20.0)),
            boxShadow: <BoxShadow>[
              BoxShadow(color: AppTheme.grey.withOpacity(0.4), offset: const Offset(2, 2), blurRadius: 4),
            ],
          ),
          child: new Icon(
            Icons.videogame_asset_rounded,
            color: AppTheme.white,
          )),
    );
  }

  /// 下载游戏rom
  void _requestDownload(Game game) async {
    var canPlay = await DuckGame.instance.canPlayGame(context, game);
    DuckGame.instance.prepareSthByGameType(game.gameType);
    if (canPlay) {
      DuckGame.instance.legalDownloadRom(context, () async {
        DuckGame.instance.downloadRoms(game);
      });
    }
  }

  uiContinueDownloadGame() {

    return InkWell(
        onTap: () => {_requestDownload(widget.game)},
        child: Container(
            height: double.infinity,
            color: Colors.orange[50],
            child: FutureBuilder<GameAndTask?>(
              future: DuckDao.getGameAndTask(widget.game.id!),
              builder: (context, existData) {
                if (existData.data == null) {
                  return Container(
                    height: double.infinity,
                    child: Center(
                      child: Text(
                        S.of(context).Continue,
                        style: TextStyle(
                            fontSize: 12, letterSpacing: 0.0, color: AppTheme.nearlyWhite, fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                } else {
                  var event = downloadEventFromMap(existData.data!.taskInfo!);
                  LOG.D(_TAG, "下载任务" + event.toString());

                  return Stack(
                    children: [
                      Container(
                        height: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(Radius.circular(20.0)),
                          border: new Border.all(color: Colors.orange, width: 1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                          child: LinearProgressIndicator(
                            value: event.downloadTask!.percent! / 100,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[300]!),
                            backgroundColor: Colors.orange[50]!,
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          S.of(context).Continue,
                          style: TextStyle(
                              fontSize: 12, letterSpacing: 0.0, color: Colors.orange[800], fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  );
                }
              },
            )));
  }

  uiDownloadGame() {
    return InkWell(
      onTap: () => {_requestDownload(widget.game)},
      child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(20.0)),
            border: new Border.all(color: AppTheme.white, width: 1),
            boxShadow: <BoxShadow>[
              BoxShadow(color: AppTheme.primary.withOpacity(0.2), offset: const Offset(2, 2), blurRadius: 2),
            ],
          ),
          child: new Icon(
            Icons.cloud_download_rounded,
          )),
    );
  }

  Widget uiStartOrDownloadOrContinue() {
    return FutureBuilder<bool>(
        future: DuckGame.instance.isRomExist(widget.game),
        builder: (context, existData) {
          if (existData.data == null) {
            return Container(color: Colors.green[50],);
          } else if (existData.data!) {
            return _uiPlayGame();
          } else {
            return uiDownloadButton();
          }
        });
  }

  Widget uiDownloadButton() {
    return FutureBuilder<bool>(
      future: DuckGame.instance.isTmpFileExist(widget.game),
      builder: (context, existData) {
        if (existData.data == null) {
          return Container(color: Colors.orange[50],);
        } else if (existData.data!) {
          return uiContinueDownloadGame();
        } else {
          return uiDownloadGame();
        }
      },
    );
  }

  Widget uiMergingOrUnzipping(String s) {
    return Container(
        color: Colors.green[300]!,
        child: Center(
          child: AnimatedTextKit(
            repeatForever: true,
            animatedTexts: [
              WavyAnimatedText(
                s,
                textStyle: const TextStyle(fontSize: 12.0, color: AppTheme.nearlyWhite),
              ),
            ],
          ),
        ));
  }

  Container uiBottomBtns(BuildContext context) {
    Widget child = Container();

    switch (event.downloadState) {
      case DOWNLOAD_STATE_START:
      case DOWNLOAD_STATE_PROGRESS:
        child = uiProgressBar();
        break;
      case DOWNLOAD_STATE_MERGING:
        child = uiMergingOrUnzipping(S.of(context).Loading);
        break;
      case DOWNLOAD_STATE_UNZIPPING:
        child = uiMergingOrUnzipping(S.of(context).Loading);
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
      width: 56,
      height: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: child,
            ),
          )
        ],
      ),
    );
  }
}
