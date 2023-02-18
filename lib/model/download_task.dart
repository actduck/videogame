import 'dart:core';
import 'dart:io';

class DownloadTask {}

class Progress {
  String? id;
  int? gameId;
  int? percent;
}

class Finished {
  String? id;
  int? gameId;
  File? file;
}
