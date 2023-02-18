// To parse this JSON data, do
//
//     final gameType = gameTypeFromJson(jsonString);

import 'dart:convert';

import 'package:flutter/cupertino.dart';

List<GameType> gameTypeFromJson(String str) => List<GameType>.from(json.decode(str).map((x) => GameType.fromMap(x)));

String gameTypeToJson(List<GameType> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class GameType {
  int? id;
  String? name;
  IconData? icon;
  String? photo;
  bool? hasNew;
  int? total;

  GameType({this.id, this.name, this.icon, this.photo, this.hasNew, this.total});

  GameType.title({this.name});

  factory GameType.fromMap(Map<String, dynamic> json) => GameType(
        id: json["id"],
        name: json["name"],
        photo: json["photo"],
        hasNew: json["hasNew"],
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
        "photo": photo,
        "hasNew": hasNew,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameType && runtimeType == other.runtimeType && id == other.id && name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
