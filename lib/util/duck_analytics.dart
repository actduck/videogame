import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:videogame/db/db.dart';
import 'package:videogame/net/app_repo.dart';

import '../logger.dart';

class DuckAnalytics {
  static final String _TAG = "DuckAnalytics";
  static String? userPseudoId = null;
  static String? localId = null;

  DuckAnalytics._();

  static final DuckAnalytics _instance = DuckAnalytics._();

  static DuckAnalytics get instance => _instance;

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: analytics);

  void setUp() async {
    var instanceId = await analytics.appInstanceId;
    LOG.D(_TAG, "获取到的userPseudoId$instanceId");
    userPseudoId = instanceId;

    var ipAddress = await getLocalIpAddress();
    LOG.D(_TAG, "获取到的ip$ipAddress");
    localId = ipAddress;

    AppRepo().reportHistory1DayAds();

  }

  static Future<String?> getLocalIpAddress() async {
    final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4, includeLinkLocal: true);

    try {
      // Try VPN connection first
      NetworkInterface vpnInterface = interfaces.firstWhere((element) => element.name == "tun0");
      return vpnInterface.addresses.first.address;
    } on StateError {
      // Try wlan connection next
      try {
        NetworkInterface interface = interfaces.firstWhere((element) => element.name == "wlan0");
        return interface.addresses.first.address;
      } catch (ex) {
        // Try any other connection next
        try {
          NetworkInterface interface =
              interfaces.firstWhere((element) => !(element.name == "tun0" || element.name == "wlan0"));
          return interface.addresses.first.address;
        } catch (ex) {
          return null;
        }
      }
    }
  }
}
