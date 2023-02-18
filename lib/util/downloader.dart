// import 'dart:io';
// import 'dart:isolate';
// import 'dart:ui';
//
// import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
// import 'package:flutter_downloader/flutter_downloader.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:videogame/db/db.dart';
// import 'package:videogame/generated/l10n.dart';
// import 'package:videogame/logger.dart';
// import 'package:videogame/model/event.dart';
// import 'package:videogame/model/game.dart';
// import 'package:videogame/model/game_and_task.dart';
// import 'package:videogame/net/api.dart';
// import 'package:videogame/pages/main_page.dart';
// import 'package:videogame/util/duck_analytics.dart';
// import 'package:videogame/util/duck_game.dart';
// import 'package:wakelock/wakelock.dart';
//
// class Downloader {
//   static final String _TAG = "Downloader";
//
//   // static const maxDownloadRetryTimes = 3;
//   // var downloadRetryTimes = 0;
//
//   Downloader._() {
//     _bindBackgroundIsolate();
//     LOG.D(_TAG, 'registerCallback START: 开始注册进度');
//     FlutterDownloader.registerCallback(downloadCallback, step: 1);
//   }
//
//   static final Downloader _instance = Downloader._();
//
//   /// Shared instance to initialize the AdMob SDK.
//   static Downloader get instance => _instance;
//
//   // static late String _localPath;
//   ReceivePort _port = ReceivePort();
//
//   static final List<TaskInfo?> _tasks = []; // 下载任务列表
//   bool isGetTaskFromDb = false; // 避免回调太快
//
//   // List<Game> _games = []; // 下载游戏列表
//   static String getFileName(String url) => url.substring(url.lastIndexOf("/") + 1);
//
//   static String getBaseName(String url) => url.substring(url.lastIndexOf("/") + 1, url.lastIndexOf("."));
//
//   /// 去掉后缀
//   static String removeExt(String url) => url.substring(0, url.lastIndexOf("."));
//
//   static Future<String> getDownloadDirByGame(Game game) async {
//     return (await _findLocalPath()) + Platform.pathSeparator + 'rom' + Platform.pathSeparator + game.gameType!.name!;
//   }
//
//   ///初始化下载器，下载游戏rom用
//   static Future _prepare(Game game) async {
//     var downloadDir = await getDownloadDirByGame(game);
//     final savedDir = Directory(downloadDir);
//     LOG.D(_TAG, '文件下载路径: downloadDir: $downloadDir');
//     bool hasExisted = await savedDir.exists();
//     if (!hasExisted) {
//       await savedDir.create(recursive: true);
//     }
//   }
//
//   /// 看路径是否在
//   static Future<String> _findLocalPath() async {
//     final directory =
//         Platform.isAndroid ? await getExternalStorageDirectory() : await getApplicationDocumentsDirectory();
//     return directory!.path;
//   }
//
//   ///下载进度监听
//   @pragma('vm:entry-point')
//   static void downloadCallback(String id, DownloadTaskStatus status, int progress) {
//     LOG.D(_TAG, '下载进度回调: task ($id) is in status ($status) and process ($progress)');
//     final SendPort send = IsolateNameServer.lookupPortByName('downloader_send_port')!;
//     send.send([id, status, progress]);
//   }
//
//   void _bindBackgroundIsolate() {
//     LOG.D(_TAG, "_bindBackgroundIsolate: 绑定");
//     bool isSuccess = IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
//     if (!isSuccess) {
//       _unbindBackgroundIsolate();
//       _bindBackgroundIsolate();
//       return;
//     }
//     _port.listen((dynamic data) async {
//       LOG.D(_TAG, '_bindBackgroundIsolate 回调 UI Isolate Callback: $data');
//       String? id = data[0];
//       DownloadTaskStatus? status = data[1];
//       int? progress = data[2];
//
//       TaskInfo? task;
//       if (_tasks.length == 0 && !isGetTaskFromDb) {
//         isGetTaskFromDb = true;
//         // 重启后 要从数据库取一下
//         var runningList = await loadRunningTasks();
//         LOG.D(_TAG, '_bindBackgroundIsolate runningList size：${runningList?.length}');
//         for (var downloadTask in runningList!) {
//           var t = await downloadTask2MyTask(downloadTask);
//           if (t != null) {
//             _tasks.add(t);
//           }
//         }
//         isGetTaskFromDb = false;
//         LOG.D(_TAG, '_bindBackgroundIsolate 重新获取下载task 长度： ${_tasks.length}');
//       }
//
//       if (_tasks.length > 0) {
//         task = _tasks.firstWhere((task) => task!.taskId == id);
//       }
//
//       if (task != null) {
//         task.status = status;
//         task.progress = progress;
//         if (task.status == DownloadTaskStatus.complete) {
//           // downloadRetryTimes = 0;
//           await onDownloadComplete(task);
//         } else if (task.status == DownloadTaskStatus.failed) {
//           // downloadRetryTimes++;
//           // LOG.D(_TAG, "_bindBackgroundIsolate: 下载失败 重试次数：$downloadRetryTimes");
//           // if (downloadRetryTimes <= maxDownloadRetryTimes) {
//           //   retryDownload(task);
//           //   DuckAnalytics.analytics.logEvent(name: "retry_download", parameters: <String, dynamic>{
//           //     'task_link': task.link,
//           //     'retry_times': downloadRetryTimes,
//           //   });
//           // }
//           DuckAnalytics.analytics.logEvent(name: "download_failed", parameters: <String, dynamic>{
//             'task_link': task.link,
//           });
//         }
//         LOG.D(_TAG, "_bindBackgroundIsolate: 发射下载进度：" + task.link!);
//         eventBus.fire(DownloadFileTask(task));
//       }
//       await tryDisableWakelock();
//     });
//   }
//
//   Future<void> tryDisableWakelock() async {
//     var runningList = await loadRunningTasks();
//     if (runningList?.isEmpty == true) {
//       LOG.D(_TAG, "_bindBackgroundIsolate: 关闭屏幕常亮");
//       Wakelock.disable();
//     }
//   }
//
//   /// 下载方法===================================
//
//   /// 下载游戏rom
//   Future requestDownload(Game game) async {
//     newRequestDownload(game);
//   }
//
//   /// 新的分片下载
//   Future newRequestDownload(Game game) async {
//     DuckGame.instance.tryInstallPlugin(game.gameType!);
//     // 使用原生来下载吧
//     DuckGame.instance.nativeDownloadRoms(game);
//   }
//
//   // /// 旧的单文件下载
//   // @Deprecated("旧下载文件不用了")
//   // Future<String?> oldRequestDownload(Game game) async {
//   //   DuckGame.instance.tryInstallPlugin(game.gameType!);
//   //   // 保持亮屏
//   //   Wakelock.enable();
//   //   await _prepare(game);
//   //
//   //   DuckAnalytics.analytics.logEvent(name: "request_download", parameters: <String, dynamic>{
//   //     'game_name': game.name,
//   //   });
//   //
//   //   DuckAnalytics.analytics.logEvent(name: "download_start", parameters: <String, dynamic>{
//   //     'task_link': game.zipUrl,
//   //   });
//   //
//   //   String fileName = getFileName(game.zipUrl!) + ".crdownload";
//   //   String link = Api.HOST + game.zipUrl!;
//   //   LOG.D(_TAG, "requestDownload 下载链接是" + link);
//   //   var saveDir = await getDownloadDirByGame(game);
//   //   game.task = TaskInfo(link, game.gameType?.name);
//   //
//   //   game.task!.taskId = await FlutterDownloader.enqueue(
//   //     url: link,
//   //     savedDir: saveDir,
//   //     fileName: fileName,
//   //     // showNotification: Utils.getNumberSize(game.size) > 50 * 1024 * 1024,
//   //     showNotification: true,
//   //     // 大于50m显示进度
//   //     // show download progress in status bar (for Android)
//   //     openFileFromNotification: false, // click on notification to open downloaded file (for Android)
//   //   );
//   //
//   //   // 数据库的操作
//   //   var gameAndTask = new GameAndTask(id: null, gameId: game.id, taskId: game.task!.taskId);
//   //   await DuckDao.insertOrUpdateGameAndTask(gameAndTask);
//   //   // 这里要添加游戏到数据库否则下载找不到
//   //   var localGame = await DuckDao.getGame(game.id);
//   //   LOG.D(_TAG, 'requestDownload 本地数据库游戏: $localGame');
//   //
//   //   if (localGame == null) {
//   //     game.favorite = false;
//   //     await DuckDao.insertOrUpdateGame(game);
//   //   }
//   //   eventBus.fire(RefreshDownloadsEvent());
//   //
//   //   _tasks.add(game.task);
//   //   LOG.D(_TAG, '新增任务列表: ${_tasks.hashCode} ${_tasks.length}');
//   //
//   //   return game.task!.taskId;
//   // }
//
//   Future<List<DownloadTask>?> loadAllTasks() async {
//     final tasks = await FlutterDownloader.loadTasks();
//     return tasks;
//   }
//
//   Future<List<DownloadTask>?> loadRunningTasks() async {
//     final tasks = await FlutterDownloader.loadTasksWithRawQuery(query: 'SELECT * FROM task WHERE status=2');
//     return tasks;
//   }
//
//   void _unbindBackgroundIsolate() {
//     IsolateNameServer.removePortNameMapping('downloader_send_port');
//   }
//
//   void cancelDownload(TaskInfo task) async {
//     await FlutterDownloader.cancel(taskId: task.taskId!);
//   }
//
//   void pauseDownload(TaskInfo task) async {
//     await FlutterDownloader.pause(taskId: task.taskId!);
//   }
//
//   Future<String?> resumeDownload(TaskInfo task) async {
//     var gat = await DuckDao.getGameAndTaskByTaskId(task.taskId);
//     String? newTaskId = await FlutterDownloader.resume(taskId: task.taskId!);
//     task.taskId = newTaskId;
//     _tasks.add(task);
//
//     // 刷新数据库
//     gat?.taskId = newTaskId;
//     if (gat != null) {
//       DuckDao.insertOrUpdateGameAndTask(gat);
//     }
//     return newTaskId;
//   }
//
//   void delete(TaskInfo task) async {
//     await FlutterDownloader.remove(taskId: task.taskId!, shouldDeleteContent: true);
//   }
//
//   Future<String?> retryDownload(TaskInfo task) async {
//     var gat = await DuckDao.getGameAndTaskByTaskId(task.taskId);
//     String? newTaskId = await FlutterDownloader.retry(taskId: task.taskId!);
//     task.taskId = newTaskId;
//     _tasks.add(task);
//
//     // 刷新数据库
//     gat?.taskId = newTaskId;
//     if (gat != null) {
//       DuckDao.insertOrUpdateGameAndTask(gat);
//     }
//     return newTaskId;
//   }
//
//   static Future _renameFile(TaskInfo task) async {
//     var saveDir =
//         (await _findLocalPath()) + Platform.pathSeparator + 'rom' + Platform.pathSeparator + task.gameTypeName!;
//     var tempFileName = getFileName(task.link!) + ".crdownload";
//     var file = File(saveDir + Platform.pathSeparator + tempFileName);
//     LOG.D(_TAG, '_renameFile 修改名字 url：${task.link} task的目录 $saveDir');
//     if (file.existsSync()) {
//       await file.rename(saveDir + Platform.pathSeparator + getFileName(task.link!));
//     } else {
//       LOG.E(_TAG, '_renameFile 出错了：${task.link} 文件不存在');
//     }
//   }
//
//   static Future<bool> _deleteFile(TaskInfo task) async {
//     LOG.D(_TAG, '_deleteFile 删除下载的文件 url：${task.link}');
//     var saveDir =
//         (await _findLocalPath()) + Platform.pathSeparator + 'rom' + Platform.pathSeparator + task.gameTypeName!;
//
//     File zipFile = File(saveDir + Platform.pathSeparator + getFileName(task.link!));
//     var exist = await zipFile.exists();
//     if (exist) {
//       zipFile.delete(recursive: false);
//       LOG.D(_TAG, '_deleteFile 删除下载的文件成功');
//       return true;
//     } else {
//       return false;
//     }
//   }
//
//   static onDownloadComplete(TaskInfo task) async {
//     LOG.D(_TAG, 'onDownloadComplete 下载完成：${task.link}');
//     DuckAnalytics.analytics.logEvent(name: "download_complete", parameters: <String, dynamic>{
//       'task_link': task.link,
//     });
//
//     await _renameFile(task);
//     var gat = await DuckDao.getGameAndTaskByTaskId(task.taskId);
//
//     if (gat != null) {
//       var game = await DuckDao.getGame(gat.gameId);
//       LOG.D(_TAG, 'onDownloadComplete 找到游戏：$game');
//       if (game != null && game.url != game.zipUrl) {
//         await DuckGame.instance.unzipFile(game);
//         await _deleteFile(task);
//         // 重新赋值url，不然扫描不到
//         task = TaskInfo(game.url, task.gameTypeName);
//       }
//     }
//
//     DuckGame.instance.nativeOnDownloadComplete(task);
//   }
//
//   void onCancelDownload(BuildContext context, TaskInfo task, Function() onDeleted) {
//     showDialog(
//         context: context,
//         builder: (BuildContext context) => AlertDialog(
//               title: Text(S.of(context).Cancel_Downloading),
//               content: Text(
//                 S.of(context).Cancel_Downloading_detail,
//                 style: TextStyle(height: 1.5),
//               ),
//               actions: <Widget>[
//                 TextButton(
//                   child: Text(S.of(context).CANCEL, style: TextStyle(color: Colors.white54)),
//                   onPressed: () => Navigator.of(context).pop(), //关闭对话框
//                 ),
//                 TextButton(
//                   child: Text(S.of(context).OK, style: TextStyle(color: Colors.red)),
//                   onPressed: () async {
//                     onDeleted.call();
//                     LOG.D(_TAG, "onCancelDownload: 取消下载");
//                     delete(task);
//                     Navigator.of(context).pop();
//                   },
//                 ),
//               ],
//             ));
//   }
//
//   static Future<TaskInfo?> downloadTask2MyTask(DownloadTask downloadTask) async {
//     var gat = await DuckDao.getGameAndTaskByTaskId(downloadTask.taskId);
//     if (gat != null) {
//       var game = await DuckDao.getGame(gat.gameId);
//       LOG.D(_TAG, '_bindBackgroundIsolate 找到游戏：$game');
//       if (game != null) {
//         var t = TaskInfo(game.zipUrl, game.gameType?.name);
//         t.taskId = downloadTask.taskId;
//         t.progress = downloadTask.progress;
//         t.status = downloadTask.status;
//         return t;
//       }
//     }
//     return null;
//   }
// }
