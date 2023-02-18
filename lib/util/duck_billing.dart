import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:videogame/logger.dart';
import 'package:videogame/main.dart';
import 'package:videogame/model/event.dart';
import 'package:videogame/net/app_repo.dart';
import 'package:videogame/pages/main_page.dart';
import 'package:videogame/util/duck_ads.dart';
import 'package:videogame/util/duck_game.dart';
import 'package:videogame/util/duck_kv.dart';

import '../generated/l10n.dart';

class DuckBilling {
  static final String _TAG = "DuckBilling";

  BuildContext? context;

  bool available = false;

  DuckBilling._() {
    initBilling();
    if (navigatorKey.currentContext != null) {
      this.context = navigatorKey.currentContext!;
    }
  }

  static final DuckBilling _instance = DuckBilling._();

  /// Shared instance to initialize the AdMob SDK.
  static DuckBilling get instance => _instance;

  late StreamSubscription<List<PurchaseDetails>> _subscription;

  // ProductDetails? skuPremium;
  // ProductDetails? skuCoins1;
  // ProductDetails? skuCoins2;
  // ProductDetails? skuCoins3;
  // ProductDetails? skuCoins4;
  // ProductDetails? skuCoins5;

  static const Set<String> _kIds = {
    'coins_1',
    'coins_2',
    'coins_3',
    'remove_ad',
    'lifetime_premium',
    'premium',
  };

  List<ProductDetails> productList = [];
  ProductDetails? currentProduct;

  initBilling() {
    LOG.D(_TAG, "initBilling: 初始化DuckBilling");
    final Stream purchaseUpdates = InAppPurchase.instance.purchaseStream;
    _subscription = purchaseUpdates.listen((purchaseDetailsList) {
      LOG.D(_TAG, "initBilling: 开始监听购买流");
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      LOG.D(_TAG, "initBilling: 取消监听购买流");
      _subscription.cancel();
    }, onError: (error) {
      // handle error here.
    }) as StreamSubscription<List<PurchaseDetails>>;
  }

  connectToStore() async {
    available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      // The store cannot be reached or accessed. Update the UI accordingly.
    } else {
      LOG.D(_TAG, "connectToStore: 连接商店成功");
      await loadProduct();
      await restorePurchase();
    }
  }

  bool isBillingAvailable() {
    return available;
  }

  loadProduct() async {
    LOG.D(_TAG, "loadProduct: 开始加载商品详情");
    final ProductDetailsResponse response = await InAppPurchase.instance.queryProductDetails(_kIds);
    if (response.notFoundIDs.isNotEmpty) {
      // Handle the error.
      LOG.D(_TAG, "loadProduct: 加载商品详情错误${response.notFoundIDs}");
    }
    List<ProductDetails> products = response.productDetails;
    if (products.length > 0) {
      productList = products;
      LOG.D(_TAG, "loadProduct: 加载商品详情详情成功：${productList.length}");
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchases) async {
    LOG.D(_TAG, "_listenToPurchaseUpdated: 监听商品变化，个数：${purchases.length}");
    if (purchases.isEmpty) {
      clearPaidSku();
    } else if (purchases.length == 1 &&
        purchases[0].status == PurchaseStatus.restored &&
        purchases[0].productID == 'remove_ad') {
      LOG.D(_TAG, "_listenToPurchaseUpdated: 只买了去广告，干掉会员");
      await setPremium(false);
    }
    purchases.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        showPendingUI();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          handleError(purchaseDetails.error!);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          bool valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            _deliverPurchase(purchaseDetails);
          } else {
            _handleInvalidPurchase(purchaseDetails);
            return;
          }
        }
        if (purchaseDetails.pendingCompletePurchase) {
          LOG.D(_TAG, "_listenToPurchaseUpdated: 完成了付款");
          await InAppPurchase.instance.completePurchase(purchaseDetails);
        }
      }
    });
  }

  makePurchase(String skuId) {
    PurchaseParam purchaseParam;

    var productDetails = getSkuDetail(skuId)!;

    if (Platform.isAndroid) {
      purchaseParam = GooglePlayPurchaseParam(productDetails: productDetails, applicationUserName: null);
    } else {
      purchaseParam = PurchaseParam(
        productDetails: productDetails,
        applicationUserName: null,
      );
    }
    LOG.D(_TAG, "makePurchase: 付款参数: ${purchaseParam.toString()}");
    if (_isConsumable(productDetails)) {
      InAppPurchase.instance.buyConsumable(purchaseParam: purchaseParam);
    } else {
      InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // IMPORTANT!! Always verify a purchase before delivering the product.
    // For the purpose of an example, we directly return true.

    // zdfdzcdshxvbxmgbafdxvdzt.JK-GR58OHRPOGFEFHEGVEACBEIFDAPDH_EFHEWFEHFHPEGVERBWBASZWDAWODPAWD-HDSWCGOEWFP-EFPEQFHPEDHEWYIFEWFUWEFDASCNAQWFDefphFEQUIWEFpofgewpfFEWHFPWEF
    String packageName = purchaseDetails.verificationData.source; //get from verificationData
    String productId = purchaseDetails.productID; //get from verificationData
    String purchaseToken = purchaseDetails.verificationData.serverVerificationData; //get from verificationData

    AppRepo().verifyPurchase(packageName, productId, purchaseToken).listen((data) {
      LOG.D(_TAG, "_verifyPurchase: 验证付款结果${data}");
    });
    return Future<bool>.value(true);
  }

  void _deliverPurchase(PurchaseDetails purchase) async {
    if (purchase.productID == 'premium' || purchase.productID == 'lifetime_premium') {
      // 买了会员
      LOG.D(_TAG, "_deliverPurchase: 买了会员");
      if (!await isPremium()) {
        setPremium(true);
        eventBus.fire(RefreshCoinsEvent());
        Fluttertoast.showToast(
            msg: context == null
                ? "Congratulations! you have unlimited game coins and no more ads"
                : S.of(context!).Congratulations_you_have_unlimited_game_coins_and_no_more_ads);
      }
    } else if (purchase.productID == 'remove_ad') {
      LOG.D(_TAG, "_deliverPurchase: 买了免广告");
      if (!await isAdFree()) {
        setAdFree(true);
        Fluttertoast.showToast(
            msg: context == null ? "Thanks! you won't see ads any more" : S.of(context!).Thanks_no_ads_any_more);
      }
    } else {
      var skuCoins = getSkuCoins(purchase.productID);
      DuckGame.instance.addCoins(skuCoins);
      LOG.D(_TAG, "_deliverPurchase: 买了金币:$skuCoins");
      Fluttertoast.showToast(
          msg: context == null
              ? "Congratulations! you get game coins +$skuCoins"
              : S.of(context!).Congratulations_you_get_game_coins(skuCoins));
    }
  }

  /// 订阅是不可消费的，其余都可消费
  bool _isConsumable(ProductDetails productDetails) {
    if (productDetails.id == "premium" || productDetails.id == "remove_ad" || productDetails.id == "lifetime_premium") {
      return false;
    } else {
      return true;
    }
  }

  Future<bool> isPremium() async {
    bool? isPremium = await DuckKV.readKey("is_premium");
    if (isPremium == null) {
      isPremium = false;
    }
    LOG.D(_TAG, "isPremium: 是会员吗$isPremium");
    return isPremium;
  }

  Future<bool> isAdFree() async {
    bool? isAdFree = await DuckKV.readKey("is_ad_free");
    if (isAdFree == null) {
      isAdFree = false;
    }
    LOG.D(_TAG, "isAdFree: 是免广告吗$isAdFree");
    return isAdFree;
  }

  Future<void> setPremium(bool isPremium) async {
    LOG.D(_TAG, "setPremium 设置会员 开始: $isPremium");
    await DuckKV.saveKey("is_premium", isPremium);
    await DuckAds.instance.refreshShowAdsFlag();
  }

  Future<void> setAdFree(bool adFree) async {
    LOG.D(_TAG, "setAdFree 设置去广告 开始: $adFree");
    await DuckKV.saveKey("is_ad_free", adFree);
    await DuckAds.instance.refreshShowAdsFlag();
  }

  void handleError(IAPError error) {
    Fluttertoast.showToast(msg: error.message);
  }

  void _handleInvalidPurchase(PurchaseDetails purchaseDetails) {
    Fluttertoast.showToast(
        msg: context == null
            ? "InvalidPurchase: ${purchaseDetails.productID}"
            : S.of(context!).InvalidPurchase_productID(purchaseDetails.productID));
  }

  void showPendingUI() {
    Fluttertoast.showToast(msg: context == null ? "paying" : S.of(context!).paying);
  }

  ProductDetails? getSkuDetail(String skuId) {
    for (var value in productList) {
      if (value.id == skuId) {
        return value;
      }
    }
    return null;
  }

  int getSkuCoins(String productID) {
    var skuDetail = getSkuDetail(productID);

    String num = skuDetail!.description.replaceAll(new RegExp(r'[a-zA-Z]+'), '');
    LOG.D(_TAG, "getSkuCoins: sku金币: $num");
    return int.parse(num);
  }

  Future<void> clearPaidSku() async {
    LOG.D(_TAG, "clearPremium: 开始清除会员和免广告");
    await setPremium(false);
    await setAdFree(false);
    LOG.D(_TAG, "clearPremium: 清除会员和免广告成功");
  }

  Future<void> restorePurchase() async {
    LOG.D(_TAG, "restorePurchases 开始恢复购买");
    await InAppPurchase.instance.restorePurchases();
    LOG.D(_TAG, "restorePurchases 恢复购买成功");
  }
}
