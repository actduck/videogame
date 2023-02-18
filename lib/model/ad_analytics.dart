class AdAnalytics {
  int? id = null;
  int? userId = null;
  String? userPseudoId = null;
  String? userIP = null;
  int? adFormat = null;
  int? event = null; // 显示还是点击 1 显示 2 点击
  DateTime? date = null;
  bool? uploaded = false; // 已上传服务器

  factory AdAnalytics.fromMap(Map<String, dynamic> json) {
    return AdAnalytics(
      id: json["id"],
      userId: json["userId"],
      userPseudoId: json["userPseudoId"],
      userIP: json["userIP"],
      adFormat: json["adFormat"],
      event: json["event"],
      date: DateTime.parse(json["date"]),
      uploaded: json["uploaded"] == 1,
    );
  }

  Map<String, dynamic> toMap() => {
        "id": id,
        "userId": userId,
        "userPseudoId": userPseudoId,
        "userIP": userIP,
        "adFormat": adFormat,
        "event": event,
        "date": date.toString(),
        "uploaded": uploaded,
      };

  AdAnalytics(
      {this.id, this.userId, this.userPseudoId, this.userIP, this.adFormat, this.event, this.date, this.uploaded});

  factory AdAnalytics.ad(int adFormat, int event) => AdAnalytics(adFormat: adFormat, event: event, uploaded: false);
}
