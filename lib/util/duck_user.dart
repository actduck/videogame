import 'package:games_services/games_services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:videogame/logger.dart';
import 'package:videogame/model/duck_account.dart';
import 'package:videogame/model/event.dart';
import 'package:videogame/net/app_repo.dart';
import 'package:videogame/pages/main_page.dart';
import 'package:videogame/util/duck_analytics.dart';
import 'package:videogame/util/duck_game.dart';

class DuckUser {
  static final String _TAG = "UserAccount";

  DuckUser._() {}

  static final DuckUser _instance = DuckUser._();

  /// Shared instance to initialize the AdMob SDK.
  static DuckUser get instance => _instance;

  DuckAccount? userInfo;
  bool isPlayGameSignIn = false;

  Future<void> signInSilently() async {
    LOG.D(_TAG, "signInSilently: 开始谷歌静静登录");
    var googleSignInAccount = await GoogleSignIn().signInSilently();
    LOG.D(_TAG, "signInSilently: 谷歌静静登录结果：$googleSignInAccount");
    if (googleSignInAccount != null) {
      vgLogin(googleSignInAccount);
    }
  }

  Future<void> signIn() async {
    LOG.D(_TAG, "signIn: 开始谷歌登录");
    DuckAnalytics.analytics.logEvent(name: "google_login_start");
    var googleSignInAccount = await GoogleSignIn().signIn();
    LOG.D(_TAG, "signInSilently: 谷歌登录结果：$googleSignInAccount");
    if (googleSignInAccount != null) {
      vgLogin(googleSignInAccount);
    }
  }

  /// 登录我自己的服务器，用于同步信息等
  void vgLogin(GoogleSignInAccount? googleSignInAccount) {
    LOG.D(_TAG, "vgLogin: 开始vg登录");
    DuckAnalytics.analytics.logLogin(loginMethod: "google");
    DuckAccount account = DuckAccount.google(googleSignInAccount!);

    AppRepo().getUserInfo(account).listen((data) {
      userInfo = DuckAccount.google(googleSignInAccount);
      userInfo?.id = data["id"];
      userInfo?.coins = data["coins"];
      userInfo?.highScore = data["highScore"];

      DuckAnalytics.analytics.setUserId(id: userInfo?.id.toString());
      LOG.D(_TAG, "vgLogin: 登录成功 $userInfo");
      eventBus.fire(RefreshUserInfoEvent());
      DuckAnalytics.analytics.logLogin(loginMethod: "videogame");
    }, onError: (e) {
      DuckAnalytics.analytics.logEvent(name: 'video_game_login_error');
    });
  }

  Future<void> signInGameService() async {
    bool playServices = await DuckGame.instance.checkPlayServices();
    if (playServices) {
      final result = await GamesServices.signIn();
      isPlayGameSignIn = result == "success";
      if (isPlayGameSignIn) {
        DuckAnalytics.analytics.logLogin(loginMethod: "gameservice");
      } else {
        DuckAnalytics.analytics.logEvent(name: 'error_game_services_login');
      }
    } else {
      DuckAnalytics.analytics.logEvent(name: 'error_no_play_services');
    }
  }

  Future<void> signOut() async {
    LOG.D(_TAG, "signOut: 开始退出登录");
    DuckAnalytics.analytics.logEvent(name: "google_logout_start");
    var googleSignInAccount = await GoogleSignIn().signOut();
    LOG.D(_TAG, "signInSilently: 谷歌退出结果：$googleSignInAccount");
    userInfo = null;
    eventBus.fire(RefreshUserInfoEvent());
  }

// void vgDeviceLogin() async {
//   LOG.D(_TAG, "vgDeviceLogin: 开始vgDevice登录");
//   DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
//   AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
//   DuckAccount account = DuckAccount.device(androidInfo);
//
//   AppRepo().getUserInfo(account).listen((data) {
//     userInfo = DuckAccount.device(androidInfo);
//     LOG.D(_TAG, "vgDeviceLogin: 登录成功 $userInfo");
//     DuckAnalytics.analytics.logLogin(loginMethod: "videogame_device");
//   }, onError: (e) {
//     LOG.D(_TAG, "vgDeviceLogin: 登录失败 $e");
//     DuckAnalytics.analytics.logEvent(name: 'error_videogame_device_login');
//   });
// }
}
