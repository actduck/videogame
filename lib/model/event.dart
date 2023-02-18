import 'package:videogame/model/game.dart';

class RefreshFavoriteEvent {
  RefreshFavoriteEvent();
}

class RefreshRecentEvent {
  RefreshRecentEvent();
}

class RefreshDownloadsEvent {
  RefreshDownloadsEvent();
}

class RefreshLocalEvent {
  RefreshLocalEvent();
}

class DisableAdEvent {
  final int adFormat;

  DisableAdEvent(this.adFormat);
}

// class DownloadFileTask {
//   final TaskInfo taskInfo;
//
//   DownloadFileTask(this.taskInfo);
// }

class UnzipGameEvent {
  final Game game;
  final int progress;
  final int state; // 0:未开始 1：解压中 2：完成 3 失败

  UnzipGameEvent(this.game, this.progress, this.state);
}

class RefreshCoinsEvent {
  RefreshCoinsEvent();
}

class RefreshUserInfoEvent {
  RefreshUserInfoEvent();
}
