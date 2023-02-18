import 'package:videogame/constants.dart';

class LOG {
  static void D(String tag, dynamic message) {
    if (!isReleaseMode()) {
      print(tag + " " + message);
    }
  }

  static void W(String tag, String message) {
    if (!isReleaseMode()) {
      print(tag + " " + message);
    }
  }

  static void E(String tag, String message) {
    if (!isReleaseMode()) {
      print(tag + " " + message);
    }
  }
}
