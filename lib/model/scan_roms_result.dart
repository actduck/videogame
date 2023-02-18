import 'game.dart';

class ScanRomResult {
  List<Game>? games;
  bool? searchSingleFile;

  ScanRomResult({this.games, this.searchSingleFile});

  ScanRomResult.fromJson(Map<String, dynamic> json) {
    if (json['games'] != null) {
      games = <Game>[];
      json['games'].forEach((v) {
        games!.add(new Game.fromMap(v));
      });
    }
    searchSingleFile = json['searchSingleFile'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.games != null) {
      data['games'] = this.games!.map((v) => v.toMap()).toList();
    }
    data['searchSingleFile'] = this.searchSingleFile;
    return data;
  }
}
