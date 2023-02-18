// The base class for the different types of items the list can contain.
import 'package:google_mobile_ads/google_mobile_ads.dart';

abstract class ListItem {
  toMap() {}
}

//// A ListItem that contains data to display a message.
//class LoadingItem implements ListItem {
//  final bool last;
//
//  LoadingItem(this.last);
//}

class AdItem implements ListItem {
  NativeAd? nativeAd;

  AdItem(this.nativeAd);

  @override
  toMap() {

  }
}
