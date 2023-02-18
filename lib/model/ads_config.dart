class AdsConfig {
  int? adIndex;
  int? maxAd;
  int? clickTimes;
  bool? enable;
  int? interval;

  AdsConfig(
      {this.adIndex, this.maxAd, this.clickTimes, this.enable, this.interval});

  AdsConfig.fromJson(Map<String, dynamic> json) {
    adIndex = json['adIndex'];
    maxAd = json['maxAd'];
    clickTimes = json['clickTimes'];
    enable = json['enable'];
    interval = json['interval'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['adIndex'] = this.adIndex;
    data['maxAd'] = this.maxAd;
    data['clickTimes'] = this.clickTimes;
    data['enable'] = this.enable;
    data['interval'] = this.interval;
    return data;
  }
}
