import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:videogame/model/game.dart';

import '../logger.dart';

class Utils {
  ///Generates a positive random integer uniformly distributed on the range
  ///from [min], inclusive, to [max], exclusive.
  ///包括最小不包括最大
  static int randomInt(int min, int max) {
    final _random = new Random();

    var i = min + _random.nextInt(max - min);
    return i;
  }

  /*
  * Base64加密
  */
  static String encodeBase64(String data) {
    var content = utf8.encode(data);
    var digest = base64Encode(content);
    return digest;
  }

  /*
  * Base64解密
  */
  static String decodeBase64(String data) {
    return String.fromCharCodes(base64Decode(data));
  }

  /*
  * 通过图片路径将图片转换成Base64字符串
  */
  static Future image2Base64(String path) async {
    File file = new File(path);
    List<int> imageBytes = await file.readAsBytes();
    return base64Encode(imageBytes);
  }

  static HashMap<int?, SpeedInfo?> speedMap = new HashMap<int, SpeedInfo?>();

  static String getDownloadSpeed(Game game, int percent) {
    var info = speedMap[game.id];
    int thisTime = DateTime.now().millisecondsSinceEpoch;

    if (info == null || thisTime - info.startTime > 10000) {
      info = new SpeedInfo();
      info.startTime = DateTime.now().millisecondsSinceEpoch;
      info.percent = percent;
      speedMap[game.id] = info;
    }

    String sizeNum = game.size!.replaceAll(new RegExp(r'[a-zA-Z]+'), '');

    double size = double.parse(sizeNum);
    var thisSize = size * percent / 100;
    var lastSize = size * info.percent / 100;

    var speed = 0.0;
    if (thisTime == info.startTime) {
      speed = 0.0;
    } else {
      speed = (thisSize - lastSize) * 1000 / (thisTime - info.startTime);
    }

    var unit = game.size!.replaceAll(new RegExp(r'[1-9]+'), '');

    if (speed < 1 && unit == "M") {
      speed = speed * 1024;
      unit = "K";
    }
    LOG.D("下载速度", "${game.name} ： Size间隔: ${thisSize - lastSize} 耗时: ${thisTime - info.startTime}");
    LOG.D("下载速度2", " ： speed $speed$unit/s");

    return "${speed.toStringAsFixed(1)}$unit/s";
  }

  static String getDownloadPercent(Game game, int percent) {
    String sizeNum = game.size!.replaceAll(new RegExp(r'[a-zA-Z]+'), '');

    double size = double.parse(sizeNum);
    // var d = size * 45 / 100;
    var thisSize = size * percent / 100;
    return "${thisSize.toStringAsFixed(0)}/${game.size}";
  }

  ///传1MB 返回1*1024*1024
  static double getNumberSize(String? sizeString) {
    if (sizeString == null || sizeString.isEmpty) {
      return 0;
    }

    String sizeNum = sizeString.replaceAll(new RegExp(r'[a-zA-Z]+'), '');

    double size = double.parse(sizeNum);

    if (sizeString.contains("GB")) {
      return size * 1024 * 1024 * 1024;
    } else if (sizeString.contains("MB")) {
      return size * 1024 * 1024;
    } else if (sizeString.contains("KB")) {
      return size * 1024;
    } else {
      return size;
    }
  }
}

class SpeedInfo {
  int startTime = 0;
  int percent = 0;
}
