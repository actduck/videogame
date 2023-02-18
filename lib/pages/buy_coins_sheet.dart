import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:videogame/app_theme.dart';
import 'package:videogame/generated/l10n.dart';
import 'package:videogame/logger.dart';
import 'package:videogame/util/duck_ads.dart';
import 'package:videogame/util/duck_analytics.dart';
import 'package:videogame/util/duck_billing.dart';
import 'package:videogame/util/duck_game.dart';
import 'package:videogame/widget/buy_coin_radio_button.dart';

import '../model/ad_analytics.dart';
import '../net/app_repo.dart';

class BuyCoinSheet extends StatefulWidget {
  String defaultSkuId = "coins_1";

  BuyCoinSheet({String? sku}) {
    if (sku != null) {
      this.defaultSkuId = sku;
    }
  }

  @override
  _BuyCoinSheetState createState() => _BuyCoinSheetState();
}

class _BuyCoinSheetState extends State<BuyCoinSheet> {
  bool isLoadingAd = false;
  late String skuId;
  bool isBillingAvailable = false;
  bool? isPremium;

  static final String _TAG = "_BuyCoinSheetState";

  @override
  void initState() {
    super.initState();
    skuId = widget.defaultSkuId; // 默认选择

    initBilling();

    DuckAnalytics.analytics.setCurrentScreen(
      screenName: 'BuyCoinSheet',
    );
  }

  Future<void> initBilling() async {
    isBillingAvailable = DuckBilling.instance.isBillingAvailable();

    isPremium = await DuckBilling.instance.isPremium();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    String btText = '';

    var skuDetail = DuckBilling.instance.getSkuDetail(skuId);
    // if (skuId == "premium") {
    //   btText = "Upgrade To Premium";
    // } else {
    btText = skuDetail == null ? 'BUY' : skuDetail.description;
    // }
    return Container(
      child: Column(
        children: [
          /// 标题
          Container(
            height: 50,
            child: Stack(
              children: [
                Center(
                  child: Text(
                    S.of(context).Get_Coins,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: Icon(Icons.close_rounded))),
                )
              ],
            ),
          ),
          Container(
              child: Column(
            children: [
              // Row(
              //   children: [Text(S.of(context).Free), buildAdButton()],
              // ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  border: new Border.all(color: AppTheme.white, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Image.asset(
                              "assets/images/video_flower_icon.webp",
                              width: 30,
                              height: 30,
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Text(
                              S.of(context).Free_Coins,
                              style: TextStyle(color: Color(0xffd0d4e3), fontSize: 18),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 4,
                        ),
                        Text(
                          S.of(context).Watch_ad_5_coins,
                          style: TextStyle(color: Color(0xff666977), fontSize: 14),
                        ),
                      ],
                    ),
                    buildAdButton()
                  ],
                ),
              ),
              if (isBillingAvailable)
                BuyCoinRadioButton(skuId, (id) {
                  setState(() {
                    skuId = id;
                  });
                }),
              if (isBillingAvailable)
                Container(
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 8,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          S.of(context).TIPS,
                          style: TextStyle(color: Color(0xffe0e0e0), fontSize: 12),
                        ),
                      ),
                      SizedBox(
                        height: 4,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          S.of(context).TIPS_detail,
                          style: TextStyle(color: Color(0xff636363), fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          )),

          /// 按钮
          if (isBillingAvailable)
            Container(
                height: 36,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFd5b876),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(24.0),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    splashColor: AppTheme.primary,
                    borderRadius: BorderRadius.all(
                      Radius.circular(24),
                    ),
                    child: Center(
                        child: Text(
                      btText,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        letterSpacing: 0.0,
                        color: Colors.black87,
                      ),
                    )),
                    onTap: () => {DuckBilling.instance.makePurchase(skuId)},
                  ),
                ))
        ],
      ),
    );
  }

  buildAdButton() {
    return ElevatedButton.icon(
      onPressed: isLoadingAd
          ? null
          : () {
              setState(() {
                isLoadingAd = true;
              });

              DuckAnalytics.analytics.logEvent(
                name: "clickWatchAd",
              );

              DuckAds.instance.createRewardAd(onSuccess: () {
                setState(() {
                  isLoadingAd = false;
                });

                DuckAds.instance.showRewardAd((ad, reward) async {
                  LOG.D(_TAG, 'onUserEarnedReward 用户开始激励${reward.amount}');
                  await DuckGame.instance.addCoins(5);

                  DuckAnalytics.analytics
                      .logEvent(name: "userEarnedReward", parameters: <String, dynamic>{'amount': reward.amount});

                  Fluttertoast.showToast(msg: S.of(context).Coins_add_5, toastLength: Toast.LENGTH_LONG);
                }, onAdShow: (ad) {
                  AppRepo().reportAds(AdAnalytics.ad(ad, 1));
                }, onAdClick: (ad) {
                  AppRepo().reportAds(AdAnalytics.ad(ad, 2));
                });
              }, onFailed: () {
                setState(() {
                  isLoadingAd = false;
                  Fluttertoast.showToast(msg: S.of(context).Ads_load_error_try_again_later);
                });
              });
            },
      style: ElevatedButton.styleFrom(
          shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(30.0),
          ),
          primary: Color(0xFFd5b876)),
      label: Text(isLoadingAd ? S.of(context).Hold_on : S.of(context).FREE_COIN, style: TextStyle(color: Colors.black)),
      icon: Icon(
        Icons.play_circle_rounded,
        color: AppTheme.black,
      ),
    );
  }
}
