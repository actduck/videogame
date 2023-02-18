// To parse this JSON data, do
//
//     final downloadEvent = downloadEventFromMap(jsonString);

import 'dart:convert';

DownloadEvent downloadEventFromMap(String str) => DownloadEvent.fromMap(json.decode(str));

String downloadEventToMap(DownloadEvent data) => json.encode(data.toMap());

class DownloadEvent {
    DownloadEvent({
        required this.downloadState,
        this.downloadTask,
    });

    int downloadState;
    DownloadTask? downloadTask;

    factory DownloadEvent.fromMap(Map<String, dynamic> json) => DownloadEvent(
        downloadState: json["downloadState"],
        downloadTask: DownloadTask.fromMap(json["downloadTask"]),
    );

    Map<String, dynamic> toMap() => {
        "downloadState": downloadState,
        "downloadTask": downloadTask?.toMap(),
    };
}

class DownloadTask {
    DownloadTask({
        this.gameId,
        this.id,
        this.percent,
        this.msg,
        this.file,
    });

    int? gameId;
    String? id;
    int? percent;
    String? msg;
    FileClass? file;

    factory DownloadTask.fromMap(Map<String, dynamic> json) => DownloadTask(
        gameId: json["gameId"],
        id: json["id"],
        percent: json["percent"],
        msg: json["msg"],
        file: json["file"] == null ? null : FileClass.fromMap(json["file"]),
    );

    Map<String, dynamic> toMap() => {
        "gameId": gameId,
        "id": id,
        "percent": percent,
        "msg": msg,
        "file": file?.toMap(),
    };
}

class FileClass {
    FileClass({
        this.path,
    });

    String? path;

    factory FileClass.fromMap(Map<String, dynamic> json) => FileClass(
        path: json["path"],
    );

    Map<String, dynamic> toMap() => {
        "path": path,
    };
}
