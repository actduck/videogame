import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:videogame/generated/l10n.dart';
import 'package:videogame/model/ad_analytics.dart';
import 'package:videogame/net/app_repo.dart';
import 'package:videogame/util/duck_ads.dart';
import 'package:videogame/util/duck_analytics.dart';

import '../constants.dart';

class AboutPage extends StatefulWidget {
  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String appName = "";
  String packageName = "";
  String version = "";
  String buildNumber = "";

  @override
  void initState() {
    super.initState();
    DuckAnalytics.analytics.setCurrentScreen(
      screenName: 'AboutPage',
    );

    buildAppInfo();
    DuckAds.instance.loadBannerAd(onAdShow: (ad) {
      AppRepo().reportAds(AdAnalytics.ad(ad, 1));
    }, onAdClick: (ad) {
      AppRepo().reportAds(AdAnalytics.ad(ad, 2));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).About),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: new Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 32, bottom: 8.0),
                    child: SizedBox(width: 64, height: 64, child: new Image.asset("assets/images/logo.png")),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      appName,
                      style: Theme.of(context).textTheme.headline5,
                    ),
                  ),
                  Text(
                    "ver. $version",
                    style: Theme.of(context).textTheme.caption,
                  ),
                  InkWell(
                    onTap: () {
                      launchURL(policy);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Text(
                          S.of(context).sign_in_hint4,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          DuckAds.instance.BannerAdWidget()
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  buildAppInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    setState(() {
      appName = packageInfo.appName;
      packageName = packageInfo.packageName;
      version = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    });
  }
}

launchURL(url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}
