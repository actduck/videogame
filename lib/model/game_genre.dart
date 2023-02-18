// To parse this JSON data, do
//
//     final gameGenre = gameGenreFromJson(jsonString);

import 'dart:convert';

List<GameGenre> gameGenreFromJson(String str) =>
    List<GameGenre>.from(json.decode(str).map((x) => GameGenre.fromMap(x)));

String gameGenreToJson(List<GameGenre> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class GameGenre {
  int? id;
  String? name;
  String? photo;

  GameGenre({
    this.id,
    this.name,
    this.photo,
  });

  GameGenre.title({this.name});

  factory GameGenre.fromMap(Map<String, dynamic>? json) {
    if (json == null) {
      return GameGenre();
    }
    return GameGenre(
      id: json["id"],
      name: json["name"],
      photo: json["photo"],
    );
  }

  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
        "photo": photo,
      };
}
