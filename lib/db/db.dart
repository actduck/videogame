import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:videogame/logger.dart';
import 'package:videogame/model/ad_analytics.dart';
import 'package:videogame/model/game.dart';
import 'package:videogame/model/game_and_task.dart';
import 'package:videogame/model/game_genre.dart';
import 'package:videogame/model/game_type.dart';
import 'package:videogame/model/search_game.dart';

const String dbName = "video_game.db";
const PAGE_SIZE = 20;

class DuckDao {
  static final String _TAG = "DuckDao";

  DuckDao._();

  ///创建游戏表sql
  static final String _sqlCreateTableGame = '''
            CREATE TABLE IF NOT EXISTS game (
              id INTEGER PRIMARY KEY,
              createTime TEXT,
              createBy TEXT,
              updateTime TEXT,
              updateBy TEXT,
              name TEXT,
              boxArt TEXT,
              photo TEXT,
              summary TEXT,
              url TEXT,
              zipUrl TEXT,
              size TEXT,
              gameTypeId INTEGER NOT NULL,
              starCount INTEGER NOT NULL,
              enable INTEGER NOT NULL,
              romLocalPath TEXT,
              favorite INTEGER NOT NULL,
              lastPlayTime TEXT,
              gameGenreId INTEGER NOT NULL,
              heat INTEGER NOT NULL,
              localGame INTEGER NOT NULL
            );
            ''';

  ///创建游戏表sql
  static final String _sqlCreateTableLocalGame = '''
            CREATE TABLE IF NOT EXISTS local_game (
              id INTEGER PRIMARY KEY,
              createTime TEXT,
              createBy TEXT,
              updateTime TEXT,
              updateBy TEXT,
              name TEXT,
              boxArt TEXT,
              photo TEXT,
              summary TEXT,
              url TEXT,
              zipUrl TEXT,
              size TEXT,
              gameTypeId INTEGER NOT NULL,
              starCount INTEGER NOT NULL,
              enable INTEGER NOT NULL,
              romLocalPath TEXT,
              favorite INTEGER NOT NULL,
              lastPlayTime TEXT,
              gameGenreId INTEGER NOT NULL,
              heat INTEGER NOT NULL,
              localGame INTEGER NOT NULL
            );
            ''';

  ///创建游戏类型表sql
  static final String _sqlCreateTableGameType = '''
            CREATE TABLE IF NOT EXISTS game_type (
              id INTEGER PRIMARY KEY,
              name TEXT,
              photo TEXT,
              hasNew INTEGER NOT NULL
            );
            ''';

  ///创建游戏种类表sql
  static final String _sqlCreateTableGameGenre = '''
            CREATE TABLE IF NOT EXISTS game_genre (
              id INTEGER PRIMARY KEY,
              name TEXT,
              photo TEXT
            );
            ''';

  ///创建游戏和下载信息表
  static final String _sqlCreateTableGameAndTask = '''
            CREATE TABLE IF NOT EXISTS game_and_task (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              gameId INTEGER NOT NULL,
              taskInfo VARCHAR ( 256 )
            );
            ''';

  ///创建游戏id搜索记录表关系表
  static final String _sqlCreateTableSearchGame = '''
            CREATE TABLE IF NOT EXISTS search_game (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              lastSearchTime TEXT,
              keywords TEXT
            );
            ''';

  ///游戏表添加最近玩的字段
  static final String _sqlUpdateTableGameAddLastPlatTime = '''
            ALTER TABLE game ADD lastPlayTime TEXT;
            ''';

  ///游戏表添加最近玩的字段
  static final String _sqlUpdateTableGameAddGameGenre = '''
            ALTER TABLE game ADD gameGenreId INTEGER NOT NULL DEFAULT 0;
            ''';

  ///游戏表添加最近玩的字段
  static final String _sqlUpdateTableGameAddHeat = '''
            ALTER TABLE game ADD heat INTEGER NOT NULL DEFAULT 0;
            ''';

  ///游戏表添加大小字段
  static final String _sqlUpdateTableGameAddSize = '''
            ALTER TABLE game ADD size TEXT;
            ''';

  ///游戏表添加本地游戏字段
  static final String _sqlUpdateTableGameAddLocalGame = '''
            ALTER TABLE game ADD LocalGame INTEGER NOT NULL DEFAULT 0;
            ''';

  ///游戏表添加压缩Url字段
  static final String _sqlUpdateTableGameAddZipUrl = '''
            ALTER TABLE game ADD zipUrl TEXT;
            ''';

  ///游戏表添加压缩Url字段
  static final String _sqlUpdateTableGameAndTaskAddTaskInfo = '''
            ALTER TABLE game_and_task ADD taskInfo TEXT;
            ALTER TABLE game_and_task DROP COLUMN taskId
            ''';

  ///创建游戏类型表sql
  static final String _sqlCreateTableAdAnalytics = '''
            CREATE TABLE IF NOT EXISTS ad_analytics (
              id INTEGER PRIMARY KEY,
              userId INTEGER,
              userPseudoId TEXT,
              userIP TEXT,
              adFormat INTEGER,
              event INTEGER,
              date INTEGER,
              uploaded INTEGER NOT NULL
            );
            ''';

  ///游戏表添加BoxArt
  static final String _sqlUpdateTableGameAddBoxArt = '''
            ALTER TABLE game ADD boxArt TEXT;
            ''';

  ///本地游戏表添加BoxArt
  static final String _sqlUpdateTableLocalGameAddBoxArt = '''
            ALTER TABLE local_game ADD boxArt TEXT;
            ''';
  static late Database _db;

  static Future init() async {
    String path = join(await getDatabasesPath(), dbName);
    LOG.D(_TAG, '数据库存储路径path:' + path);

    try {
      _db = await openDatabase(
        path,
        onCreate: (db, version) {
          LOG.D(_TAG, "onCreate: 当前数据库版本:$version");

          db.execute(
            _sqlCreateTableGame,
          );
          db.execute(
            _sqlCreateTableGameType,
          );
          db.execute(
            _sqlCreateTableGameAndTask,
          );
          db.execute(
            _sqlCreateTableSearchGame,
          );
          db.execute(
            _sqlCreateTableGameGenre,
          );
          db.execute(
            _sqlCreateTableLocalGame,
          );
          db.execute(
            _sqlCreateTableAdAnalytics,
          );
        },
        onUpgrade: (Database db, int oldVersion, int newVersion) {
          LOG.D(_TAG, "onUpgrade: 当前数据库版本:$oldVersion, 新数据库版本:$newVersion");
          int version = oldVersion;

          if (version == 3) {
            db.execute(
              _sqlUpdateTableGameAddLastPlatTime,
            );
            version++;
          }
          if (version == 4) {
            db.execute(
              _sqlUpdateTableGameAddSize,
            );
            version++;
          }
          if (version == 5) {
            db.execute(
              _sqlCreateTableSearchGame,
            );
            version++;
          }
          if (version == 6) {
            db.execute(
              _sqlUpdateTableGameAddGameGenre,
            );
            db.execute(
              _sqlUpdateTableGameAddHeat,
            );
            db.execute(
              _sqlCreateTableGameGenre,
            );
            version++;
          }
          if (version == 7) {
            db.execute(
              _sqlUpdateTableGameAddLocalGame,
            );
            version++;
          }
          if (version == 8) {
            db.execute(
              _sqlUpdateTableGameAddZipUrl,
            );
            version++;
          }
          if (version == 9) {
            db.execute(
              _sqlUpdateTableGameAndTaskAddTaskInfo,
            );
            db.execute(
              _sqlCreateTableLocalGame,
            );
            version++;
          }
          if (version == 10) {
            db.execute(
              _sqlCreateTableAdAnalytics,
            );
            db.execute(
              _sqlUpdateTableGameAddBoxArt,
            );
            version++;
          }
          if (version == 11) {
            db.execute(
              _sqlUpdateTableLocalGameAddBoxArt,
            );
            version++;
          }
        },
        // Set the version. This executes the onCreate function and provides a
        // path to perform database upgrades and downgrades.
        version: 12,
      );
      LOG.D(_TAG, '数据库打开成功');
    } catch (e) {
      LOG.D(_TAG, 'CreateTables init Error $e');
    }
  }

  ///=============================游戏搜索START========================
  /// 插入搜索游戏
  static Future<SearchGame> insertOrUpdateSearchGame(SearchGame searchGame) async {
    var oldSG = await getSearchGame(searchGame.keywords);
    if (oldSG != null) {
      searchGame.id = oldSG.id;
    }

    var id = await _db.update('search_game', searchGame.toMap(), where: 'id = ?', whereArgs: [searchGame.id]);

    if (id == 0) {
      searchGame.id = await _db.insert('search_game', searchGame.toMap());
    }

    LOG.D(_TAG, "插入搜索游戏关键字$searchGame");
    return searchGame;
  }

  ///查找搜索记录
  static Future<SearchGame?> getSearchGame(String? keywords) async {
    List<Map> maps = await _db.query('search_game', where: 'keywords = ?', whereArgs: [keywords]);
    if (maps.length > 0) {
      return SearchGame.fromMap(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  ///查找搜索记录
  static Future<List<SearchGame>> getLastSearch4() async {
    List<Map> maps = await _db.query('search_game', orderBy: 'lastSearchTime desc', limit: 4);

    List<SearchGame> list = [];
    for (var map in maps) {
      list.add(SearchGame.fromMap(map as Map<String, dynamic>));
    }
    return list;
  }

  ///=============================游戏下载相关START===============================

  /// 插入游戏和下载进度关系
  static Future<GameAndTask> insertOrUpdateGameAndTask(GameAndTask gameAndTask) async {
    var oldGAT = await getGameAndTask(gameAndTask.gameId);
    if (oldGAT != null) {
      gameAndTask.id = oldGAT.id;
    }

    var id = await _db.update('game_and_task', gameAndTask.toMap(), where: 'id = ?', whereArgs: [gameAndTask.id]);

    if (id == 0) {
      gameAndTask.id = await _db.insert('game_and_task', gameAndTask.toMap());
    }

    LOG.D(_TAG, "插入游戏id和taskId: ${gameAndTask.toString()}");
    return gameAndTask;
  }

  ///查找游戏和下载进度
  static Future<GameAndTask?> getGameAndTask(int? gameId) async {
    List<Map> maps = await _db.query('game_and_task', where: 'gameId = ?', whereArgs: [gameId]);
    if (maps.length > 0) {
      return GameAndTask.fromMap(maps.first as Map<String, dynamic>);
    }
    return null;
  }

  // ///查找游戏和下载进度
  // static Future<GameAndTask?> getGameAndTaskByTaskId(String? taskId) async {
  //   List<Map> maps = await _db.query('game_and_task', where: 'taskId = ?', whereArgs: [taskId]);
  //   if (maps.length > 0) {
  //     LOG.D(_TAG, "查找游戏id和taskId getGameAndTaskByTaskId 找到了 $maps");
  //     return GameAndTask.fromMap(maps.first as Map<String, dynamic>);
  //   }
  //   return null;
  // }

  ///查找所有游戏和下载进度
  static Future<List<GameAndTask>> getAllGameAndTask() async {
    List<Map> maps = await _db.query('game_and_task');
    List<GameAndTask> list = [];
    for (var map in maps) {
      list.add(GameAndTask.fromMap(map as Map<String, dynamic>));
    }
    return list;
  }

  ///删除
  static Future<int> deleteGameAndTask(id) async {
    var i = await _db.delete('game_and_task', where: 'id = ?', whereArgs: [id]);
    return i;
  }

  ///=============================游戏相关START===================================

  /// 插入游戏列表
  static void insertOrUpdateGames(List<Game> games) {
    for (var game in games) {
      insertOrUpdateGame(game);
    }
  }

  /// 插入游戏
  static Future<Game> insertOrUpdateGame(Game game) async {
    // LOG.D(_TAG, "insertOrUpdateGame: 插入游戏：" + game.name!);
    var map = game.toMap();
    map.remove("gameType");
    map.remove("gameGenre");
    map["gameTypeId"] = game.gameType?.id == null ? 0 : game.gameType?.id;
    map["gameGenreId"] = game.gameGenre?.id == null ? 0 : game.gameGenre?.id;
    map["localGame"] = false;

    var dbGame = await getGame(game.id);
    if (dbGame != null) {
      if (game.romLocalPath == null && dbGame.romLocalPath != null) {
        map["romLocalPath"] = dbGame.romLocalPath;
      }
      if (game.favorite == null) {
        map["favorite"] = dbGame.favorite;
      }
      if (game.lastPlayTime == null && dbGame.lastPlayTime != null) {
        map["lastPlayTime"] = dbGame.lastPlayTime;
      }
      // LOG.D(_TAG, "insertOrUpdateGame: 更新老游戏：" + game.name!);
      var id = await _db.update('game', map, where: 'id = ?', whereArgs: [game.id]);
      if (id == 0) {
        await _db.insert('game', map);
      }
    } else {
      map["favorite"] = game.favorite == null ? false : game.favorite;
      // LOG.D(_TAG, "insertOrUpdateGame: 插入新游戏：" + game.name!);
      await _db.insert('game', map);
    }
    return game;
  }

  static Future<Game> processGame(Map map) async {
    Map<String, dynamic> gameMap = {...map as Map<String, dynamic>};
    var gameTypeId = gameMap["gameTypeId"];
    var gameGenreId = gameMap["gameGenreId"];

    GameType? gameType = await getGameType(gameTypeId);
    GameGenre? gameGenre = await getGameGenre(gameGenreId);

    if (gameType != null) {
      gameMap["gameType"] = gameType.toMap();
    }
    if (gameGenre != null) {
      gameMap["gameGenre"] = gameGenre.toMap();
    }
    gameMap.remove("gameTypeId");
    gameMap.remove("gameGenreId");

    gameMap["enable"] = map["enable"] == 1;
    gameMap["favorite"] = map["favorite"] == 1;
    gameMap["localGame"] = map["localGame"] == 1;

    return Game.fromMap(gameMap);
  }

  ///查找游戏
  static Future<Game?> getGame(int? id) async {
    List<Map> maps = await _db.query('game', where: 'id = ?', whereArgs: [id]);
    if (maps.length > 0) {
      return await processGame(maps.first);
    }
    return null;
  }

  ///查找游戏by名字
  static Future<List<Game>> getGamesByTypeId(int page, int? typeId) async {
    List<Map> maps = await _db.query('game',
        where: 'gameTypeId = ?', whereArgs: [typeId], limit: PAGE_SIZE, offset: page - 1 * PAGE_SIZE);
    List<Game> list = [];
    for (var map in maps) {
      list.add(await processGame(map));
    }
    return list;
  }

  ///查找收藏游戏
  static Future<List<Game>> getFavoriteGames() async {
    List<Map> maps = await _db.query('game', where: 'favorite = ?', whereArgs: [1]);

    List<Game> list = [];
    for (var map in maps) {
      list.add(await processGame(map));
    }

    // await Future.forEach(maps, (Map map) async {
    //   list.add(await processGame(map));
    // });

    return list;
  }

  ///查找最近玩的游戏
  static Future<List<Game>> getRecentGames() async {
    List<Map> maps =
        await _db.query('game', where: 'lastPlayTime IS NOT NULL AND localGame = 0', orderBy: "lastPlayTime desc");

    List<Game> list = [];
    for (var map in maps) {
      // LOG.D(_TAG,"getRecentGames: 获取最近游戏: 名称：${map.name} 时间：${map["lastPlayTime"]}");
      list.add(await processGame(map));
    }
    return list;
  }

  ///点击过下载的游戏获取
  static Future<List<Game>> getDownloadsGames() async {
    var allGameAndTask = await getAllGameAndTask();

    List<Game> list = [];
    for (var gat in allGameAndTask.reversed.toList()) {
      var game = await getGame(gat.gameId);
      if (game != null) list.add(game);
    }
    return list;
  }

  ///=============================本地游戏类型START===================================

  /// 插入游戏
  static Future<Game> insertOrUpdateLocalGame(Game game) async {
    LOG.D(_TAG, "insertOrUpdateLocalGame: 插入游戏：" + game.name! + "${game.id}");
    var map = game.toMap();
    map.remove("gameType");
    map.remove("gameGenre");
    map["gameTypeId"] = game.gameType?.id == null ? 0 : game.gameType?.id;
    map["gameGenreId"] = game.gameGenre?.id == null ? 0 : game.gameGenre?.id;
    map["localGame"] = true;
    map["favorite"] = false;

    var dbGame = await getLocalGame(game.id);
    if (dbGame != null) {
      if (game.romLocalPath == null && dbGame.romLocalPath != null) {
        map["romLocalPath"] = dbGame.romLocalPath;
      }

      if (game.lastPlayTime == null && dbGame.lastPlayTime != null) {
        map["lastPlayTime"] = dbGame.lastPlayTime;
      }
      // LOG.D(_TAG, "insertOrUpdateGame: 更新老游戏：" + game.name!);
      await _db.update('local_game', map, where: 'id = ?', whereArgs: [game.id]);
    } else {
      // LOG.D(_TAG, "insertOrUpdateGame: 插入新游戏：" + game.name!);
      await _db.insert('local_game', map);
    }
    return game;
  }

  ///查找游戏by名字
  static Future<Game?> getLocalGameByName(String? name) async {
    List<Map> maps = await _db.query('local_game', where: 'name = ?', whereArgs: [name]);
    if (maps.length > 0) {
      return await processGame(maps.first);
    }
    return null;
  }

  ///查找游戏
  static Future<Game?> getLocalGame(int? id) async {
    List<Map> maps = await _db.query('local_game', where: 'id = ?', whereArgs: [id]);
    if (maps.length > 0) {
      return await processGame(maps.first);
    }
    return null;
  }

  ///查找最近玩的本地游戏
  static Future<List<Game>> getRecentLocalGames() async {
    List<Map> maps = await _db.query('local_game',
        where: 'lastPlayTime IS NOT NULL AND localGame = ?', whereArgs: [1], orderBy: "lastPlayTime desc");

    List<Game> list = [];
    for (var map in maps) {
      // LOG.D(_TAG,"getRecentGames: 获取最近游戏: 名称：${map.name} 时间：${map["lastPlayTime"]}");
      list.add(await processGame(map));
    }
    return list;
  }

  ///本地游戏获取
  static Future<List<Game>> getLocalGames() async {
    List<Map> maps = await _db.query('local_game', where: 'localGame = ?', whereArgs: [1], orderBy: "name asc");

    List<Game> list = [];
    for (var map in maps) {
      // LOG.D(_TAG,"getRecentGames: 获取最近游戏: 名称：${map.name} 时间：${map["lastPlayTime"]}");
      list.add(await processGame(map));
    }
    return list;
  }

  ///本地游戏删除
  static Future<int> deleteLocalGame(id) async {
    var i = await _db.delete('local_game', where: 'id = ?', whereArgs: [id]);
    return i;
  }

  ///=============================本地游戏类型END===================================

  ///=============================游戏类型START===================================

  ///插入游戏类型
  static Future<GameType> insertOrUpdateGameType(GameType gameType) async {
    var id = await _db.update('game_type', gameType.toMap(), where: 'id = ?', whereArgs: [gameType.id]);

    if (id == 0) {
      gameType.id = await _db.insert('game_type', gameType.toMap());
    }

    return gameType;
  }

  ///查找游戏类型
  static Future<GameType?> getGameType(int? id) async {
    List<Map> maps = await _db.query('game_type', where: 'id = ?', whereArgs: [id]);
    if (maps.length > 0) {
      Map<String, dynamic> gameTypeMap = {...maps.first as Map<String, dynamic>};
      gameTypeMap["hasNew"] = maps.first["hasNew"] == 1;

      return GameType.fromMap(gameTypeMap);
    }
    return null;
  }

  ///查找所有类型
  static Future<List<GameType>> getGameTypes() async {
    List<Map> maps = await _db.query('game_type');
    List<GameType> list = [];
    for (var map in maps) {
      Map<String, dynamic> gameTypeMap = {...map as Map<String, dynamic>};
      gameTypeMap["hasNew"] = maps.first["hasNew"] == 1;
      list.add(GameType.fromMap(gameTypeMap));
    }
    return list;
  }

  ///查找游戏类型by名字
  static Future<GameType?> getGameTypeByName(String? name) async {
    List<Map> maps = await _db.query('game_type', where: 'name = ?', whereArgs: [name]);
    if (maps.length > 0) {
      Map<String, dynamic> gameTypeMap = {...maps.first as Map<String, dynamic>};
      gameTypeMap["hasNew"] = maps.first["hasNew"] == 1;

      return GameType.fromMap(gameTypeMap);
    }
    return null;
  }

  ///=============================游戏种类START===================================

  ///插入游戏种类
  static Future<GameGenre> insertOrUpdateGameGenre(GameGenre gameGenre) async {
    var id = await _db.update('game_genre', gameGenre.toMap(), where: 'id = ?', whereArgs: [gameGenre.id]);

    if (id == 0) {
      gameGenre.id = await _db.insert('game_genre', gameGenre.toMap());
    }

    return gameGenre;
  }

  ///查找游戏种类
  static Future<GameGenre?> getGameGenre(int? id) async {
    List<Map> maps = await _db.query('game_genre', where: 'id = ?', whereArgs: [id]);
    if (maps.length > 0) {
      Map<String, dynamic> gameGenreMap = {...maps.first as Map<String, dynamic>};

      return GameGenre.fromMap(gameGenreMap);
    }
    return null;
  }

  ///查找所有种类
  static Future<List<GameGenre?>> getGameGenres() async {
    List<Map> maps = await _db.query('game_genre');
    List<GameGenre> list = [];
    for (var map in maps) {
      Map<String, dynamic> gameGenreMap = {...map as Map<String, dynamic>};
      list.add(GameGenre.fromMap(gameGenreMap));
    }
    return list;
  }

  ///=============================广告分析START===================================

  static Future<AdAnalytics> insertOrUpdateAdAnalytics(AdAnalytics analytics) async {
    var id = await _db.update('ad_analytics', analytics.toMap(), where: 'id = ?', whereArgs: [analytics.id]);
    if (id == 0) {
      analytics.id = await _db.insert('ad_analytics', analytics.toMap());
    }
    return analytics;
  }

  //     "SELECT * FROM AdAnalytics WHERE adFormat == :adFormat and event == 2 and date > :toDayZeroTime"
  static Future<List<AdAnalytics>> getAdsClickTimes(int adFormat, DateTime toDayZeroTime) async {
    List<Map> maps = await _db.query('ad_analytics',
        where: 'adFormat = ? and event = ? and date > ?', whereArgs: [adFormat, 2, toDayZeroTime.millisecondsSinceEpoch]);

    List<AdAnalytics> list = [];
    for (var map in maps) {
      Map<String, dynamic> m = {...map as Map<String, dynamic>};
      list.add(AdAnalytics.fromMap(m));
    }
    return list;
  }

  //  @Query("SELECT * FROM AdAnalytics WHERE uploaded == 0 and date > :date")
  static Future<List<AdAnalytics>> getNotUploadedReports(DateTime dateTime) async {
    List<Map> maps = await _db.query('ad_analytics', where: 'uploaded == ? and date > ?', whereArgs: [0, dateTime.millisecondsSinceEpoch]);

    List<AdAnalytics> list = [];
    for (var map in maps) {
      Map<String, dynamic> m = {...map as Map<String, dynamic>};
      list.add(AdAnalytics.fromMap(m));
    }
    return list;
  }

  // static Future<int> delete(int id) async {
  //   return await db.delete(tableGame, where: '$id = ?', whereArgs: [id]);
  // }
  //
  // static Future<int> update(Game game) async {
  //   return await db
  //       .update(tableGame, game.toMap(), where: 'id = ?', whereArgs: [game.id]);
  // }

  static Future close() async => _db.close();
}
