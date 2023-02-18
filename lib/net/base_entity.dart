class BaseEntity<T> {
  int? code;
  String? msg;
  T? data;

  BaseEntity(this.code, this.msg, this.data);

  BaseEntity.fromMap(Map<String, dynamic> json) {
    code = json["code"];
    msg = json["msg"];
    data = json["data"] as T?;
  }
}
