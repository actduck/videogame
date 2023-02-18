import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:videogame/util/duck_billing.dart';

class BuyCoinRadioButton extends StatefulWidget {
  String defaultSkuId;

  BuyCoinRadioButton(this.defaultSkuId, this.callBack);

  final Function(String) callBack;

  @override
  createState() {
    return new BuyCoinRadioButtonState();
  }
}

class BuyCoinRadioButtonState extends State<BuyCoinRadioButton> {
  List<RadioModel?> RadioData = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    List<ProductDetails> productList = DuckBilling.instance.productList;

    // for (var value in productList) {
    //
    //   sampleData.add(new RadioModel(true, '60C', value.price, showHot: true));
    //   sampleData.add(new RadioModel(false, '200C', value.price));    // 20  2
    //   sampleData.add(new RadioModel(false, '360C', value.price));    // 60  4
    //   sampleData.add(new RadioModel(false, '800C', value.price));    // 200 9
    //   sampleData.add(new RadioModel(false, '1800C', value.price));  // 600 19
    //   sampleData.add(new RadioModel(false, '9999+C', value.price, showPremium: true));
    // }

    for (var value in productList) {
      var radioModel = RadioModel(value.id, false, getSkuTitle(value.id), value.price);
      if (value.id == "coins_1") {
        radioModel.showHot = true;
      }
      if (value.id == "premium") {
        radioModel.showPremium = true;
        radioModel.money += '/month';
      }
      if (value.id == "lifetime_premium") {
        radioModel.showPremium = true;
      }
      if (value.id == "remove_ad") {
        radioModel.showNoAds = true;
      }
      if(value.id == widget.defaultSkuId){
        radioModel.isSelected = true;
        DuckBilling.instance.currentProduct = value;
      }

      RadioData.add(radioModel);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildBuyCoinItem(0),
              buildBuyCoinItem(1),
              buildBuyCoinItem(2),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildBuyCoinItem(3),
              buildBuyCoinItem(4),
              buildBuyCoinItem(5),
            ],
          ),
        )
      ],
    );
  }

  Widget buildBuyCoinItem(int index) {
    var radioData;
    try {
      radioData = RadioData[index];
    } catch (e) {}

    return radioData != null
        ? Flexible(
            fit: FlexFit.tight,
            child: new InkWell(
              splashColor: Colors.transparent,
              onTap: () {
                setState(() {
                  RadioData.forEach((element) => element!.isSelected = false);
                  radioData!.isSelected = true;
                  widget.callBack(radioData!.skuId);
                });
              },
              child: new RadioItem(radioData!),
            ),
          )
        : Container();
  }

  String getSkuTitle(String id) {
    switch (id) {
      case "coins_1":
        return "60C";
      case "coins_2":
        return "200C";
      case "coins_3":
        return "360C";
      case "coins_4":
        return "800C";
      case "coins_5":
        return "1800C";
      case "premium":
        return "999+C\nNo Ads";
      case "lifetime_premium":
        return "Lifetime\nPremium";
      case "remove_ad":
        return "Remove Ads";
    }
    return "";
  }
}

class RadioItem extends StatelessWidget {
  final RadioModel _item;

  RadioItem(this._item);

  @override
  Widget build(BuildContext context) {
    return new Stack(
      children: <Widget>[
        new Container(
          height: 60.0,
          margin: const EdgeInsets.only(top: 8, left: 8, right: 8),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: Center(
              child: Text(_item.coins,
                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14.0)),
            ),
          ),
          decoration: BoxDecoration(
            // color: _item.isSelected ? Colors.blueAccent : Colors.transparent,
            image: DecorationImage(
              image: _item.isSelected
                  ? AssetImage("assets/images/bg_buy_coin_select.png")
                  : AssetImage("assets/images/bg_buy_coin_normal.png"),
              fit: BoxFit.fill,
            ),
            // border: new Border.all(
            //     width: 1.0,
            //     color: _item.isSelected ? Colors.blueAccent : Colors.grey),
            // borderRadius: const BorderRadius.all(const Radius.circular(2.0)),
          ),
        ),
        if (_item.showHot)
          Positioned(
            top: 3,
            left: 8,
            child: Container(width: 30, child: Image.asset("assets/images/ic_buy_coin_hot.png")),
          ),
        if (_item.showPremium)
          Positioned(
            child: Container(width: 24, child: Image.asset("assets/images/ic_buy_premium.png")),
          ),
        if (_item.showNoAds)
          Positioned(
            child: Container(width: 22, child: Image.asset("assets/images/ic_no_ads.png")),
          ),
        Positioned.fill(
          bottom: 2,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: new Container(
              child: new Text(
                _item.money,
                style: TextStyle(color: _item.isSelected ? Colors.white : Colors.black87, fontSize: 10),
              ),
            ),
          ),
        )
      ],
    );
  }
}

class RadioModel {
  String skuId;
  bool isSelected;
  String coins;
  String money;
  bool showHot;
  bool showPremium;
  bool showNoAds;

  RadioModel(this.skuId, this.isSelected, this.coins, this.money,
      {this.showHot = false, this.showPremium = false, this.showNoAds = false});
}
