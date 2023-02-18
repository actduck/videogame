class SearchGame {
  SearchGame({this.id, this.keywords, this.lastSearchTime});

  int? id;
  String? keywords;
  String? lastSearchTime;

  factory SearchGame.fromMap(Map<String, dynamic> json) => SearchGame(
        id: json["id"],
        keywords: json["keywords"],
        lastSearchTime: json["lastSearchTime"],
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "keywords": keywords,
        "lastSearchTime": lastSearchTime,
      };
}
