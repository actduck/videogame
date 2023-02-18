// To parse this JSON data, do
//
//     final gamePage = gamePageFromJson(jsonString);

import 'dart:convert';

import 'package:videogame/model/game_genre.dart';
import 'package:videogame/model/game_type.dart';
import 'package:videogame/model/list_item.dart';

GamePage gamePageFromJson(String str) => GamePage.fromJson(json.decode(str));

String gamePageToJson(GamePage data) => json.encode(data.toMap());

class GamePage {
  List<ListItem>? content;
  Pageable? pageable;
  int? totalPages;
  int? totalElements;
  bool? last;
  int? number;
  int? size;
  bool? first;
  Sort? sort;
  int? numberOfElements;
  bool? empty;

  GamePage({
    this.content,
    this.pageable,
    this.totalPages,
    this.totalElements,
    this.last,
    this.number,
    this.size,
    this.first,
    this.sort,
    this.numberOfElements,
    this.empty,
  });

  factory GamePage.fromJson(Map<String, dynamic> map) => GamePage(
        content: List<Game>.from(map["content"].map((x) => Game.fromMap(x))),
        pageable: Pageable.fromJson(map["pageable"]),
        totalPages: map["totalPages"],
        totalElements: map["totalElements"],
        last: map["last"],
        number: map["number"],
        size: map["size"],
        first: map["first"],
        sort: Sort.fromJson(map["sort"]),
        numberOfElements: map["numberOfElements"],
        empty: map["empty"],
      );

  Map<String, dynamic> toMap() => {
        "content": List<dynamic>.from(content!.map((x) => x.toMap())),
        "pageable": pageable!.toJson(),
        "totalPages": totalPages,
        "totalElements": totalElements,
        "last": last,
        "number": number,
        "size": size,
        "first": first,
        "sort": sort!.toJson(),
        "numberOfElements": numberOfElements,
        "empty": empty,
      };
}

class Game implements ListItem {
  int? id;
  DateTime? createTime;
  String? createBy;
  DateTime? updateTime;
  String? updateBy;
  String? name;
  String? boxArt;
  String? photo;
  String? summary;
  String? url;
  String? zipUrl;
  String? size;
  GameType? gameType;
  int? starCount;
  bool? enable;
  String? romLocalPath;
  bool? favorite;
  String? lastPlayTime;
  bool? isUnziping; // 是否正在解压
  int? heat; //热度
  GameGenre? gameGenre; //种类
  bool? localGame; //本地游戏

  Game(
      {this.id,
      this.createTime,
      this.createBy,
      this.updateTime,
      this.updateBy,
      this.name,
      this.boxArt,
      this.photo,
      this.summary,
      this.url,
      this.zipUrl,
      this.size,
      this.gameType,
      this.starCount,
      this.enable,
      this.romLocalPath,
      this.favorite,
      this.lastPlayTime,
      this.isUnziping,
      this.heat,
      this.gameGenre,
      this.localGame});

  factory Game.fromMap(Map<String, dynamic> map) => Game(
        id: map["id"],
        createTime: DateTime.parse(map["createTime"]),
        createBy: map["createBy"],
        updateTime: DateTime.parse(map["updateTime"]),
        updateBy: map["updateBy"],
        name: map["name"],
        boxArt: map["boxArt"],
        photo: map["photo"],
        summary: map["summary"],
        url: map["url"],
        zipUrl: map["zipUrl"],
        size: map["size"],
        gameType: map["gameType"] == null ? null : GameType.fromMap(map["gameType"]),
        starCount: map["starCount"],
        enable: map["enable"],
        favorite: map["favorite"],
        lastPlayTime: map["lastPlayTime"],
        romLocalPath: map["romLocalPath"],
        heat: map["heat"],
        gameGenre: map["gameGenre"] == null ? null : GameGenre.fromMap(map["gameGenre"]),
        localGame: map["localGame"],
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "createTime": createTime!.toString(),
        "createBy": createBy,
        "updateTime": updateTime!.toString(),
        "updateBy": updateBy,
        "name": name,
        "boxArt": boxArt,
        "photo": photo,
        "summary": summary,
        "url": url,
        "zipUrl": zipUrl,
        "size": size,
        "gameType": gameType?.toMap(),
        "starCount": starCount,
        "enable": enable,
        "romLocalPath": romLocalPath,
        "favorite": favorite,
        "lastPlayTime": lastPlayTime,
        "heat": heat,
        "gameGenre": gameGenre?.toMap(),
        "localGame": localGame,
      };
}

class Pageable {
  Sort? sort;
  int? offset;
  int? pageNumber;
  int? pageSize;
  bool? unpaged;
  bool? paged;

  Pageable({
    this.sort,
    this.offset,
    this.pageNumber,
    this.pageSize,
    this.unpaged,
    this.paged,
  });

  factory Pageable.fromJson(Map<String, dynamic> json) => Pageable(
        sort: Sort.fromJson(json["sort"]),
        offset: json["offset"],
        pageNumber: json["pageNumber"],
        pageSize: json["pageSize"],
        unpaged: json["unpaged"],
        paged: json["paged"],
      );

  Map<String, dynamic> toJson() => {
        "sort": sort!.toJson(),
        "offset": offset,
        "pageNumber": pageNumber,
        "pageSize": pageSize,
        "unpaged": unpaged,
        "paged": paged,
      };
}

class Sort {
  bool? sorted;
  bool? unsorted;
  bool? empty;

  Sort({
    this.sorted,
    this.unsorted,
    this.empty,
  });

  factory Sort.fromJson(Map<String, dynamic> json) => Sort(
        sorted: json["sorted"],
        unsorted: json["unsorted"],
        empty: json["empty"],
      );

  Map<String, dynamic> toJson() => {
        "sorted": sorted,
        "unsorted": unsorted,
        "empty": empty,
      };
}
