const DOWNLOAD_STATE_START = 0; // 下载开始
const DOWNLOAD_STATE_PROGRESS = 1; // 下载中
const DOWNLOAD_STATE_FINISH = 2; // 下载完成
const DOWNLOAD_STATE_UNZIPPING = 3; // 解压缩
const DOWNLOAD_STATE_UNKNOWN = 4; // 未知
const DOWNLOAD_STATE_ERROR = 5; // 出错
const DOWNLOAD_STATE_MERGING = 6; // 合并文件
const DOWNLOAD_STATE_PAUSE = 7; // 暂停

class DuckDownloader {
  DuckDownloader._() {}

  static final DuckDownloader _instance = DuckDownloader._();

  /// Shared instance to initialize the AdMob SDK.
  static DuckDownloader get instance => _instance;
}
