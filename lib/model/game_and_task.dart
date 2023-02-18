class GameAndTask {
  GameAndTask({
    this.id,
    this.gameId,
    this.taskInfo,
  });

  int? id;
  int? gameId;
  String? taskInfo;

  factory GameAndTask.fromMap(Map<String, dynamic> json) => GameAndTask(
        id: json["id"],
        gameId: json["gameId"],
        taskInfo: json["taskInfo"],
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "gameId": gameId,
        "taskInfo": taskInfo,
      };
}
