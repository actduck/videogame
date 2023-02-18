import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:package_info/package_info.dart';
import 'package:videogame/constants.dart';
import 'package:videogame/logger.dart';
import 'package:videogame/net/api.dart';
import 'package:videogame/net/base_entity.dart';

class ApiService {
  static final String _TAG = "ApiService";

  static final ApiService _singleton = ApiService._internal();

  factory ApiService() {
    return _singleton;
  }

  late Dio _dio;

  Dio get dio => _dio;

  bool showLog = false;

  ApiService._internal() {
    var options = BaseOptions(
      baseUrl: Api.BASE_URL,
      connectTimeout: 60000,
      receiveTimeout: 60000,
    );
    _dio = Dio(options);

    dio.interceptors.add(RetryInterceptor(
      dio: dio,
      logPrint: print, // specify log function (optional)
      retries: 3, // retry count (optional)
      retryDelays: const [
        // set delays between retries (optional)
        Duration(seconds: 1), // wait 1 sec before first retry
        Duration(seconds: 2), // wait 2 sec before second retry
        Duration(seconds: 3), // wait 3 sec before third retry
      ],
    ));

    if (isMobile) {
      _dio.options.headers["App-Name"] = "Video Game Mobile";

      PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
        String appName = packageInfo.appName;
        String packageName = packageInfo.packageName;
        String version = packageInfo.version;
        String buildNumber = packageInfo.buildNumber;

        _dio.options.headers["App-Version"] = buildNumber;
      });
    }

    if (isWeb) {
      _dio.options.headers["App-Name"] = "Video Game Web";
    }
  }

  Future<T> get<T>(String url, {Map<String, dynamic>? params}) async {
    if (showLog) {
      LOG.D(_TAG, "get: ${Api.BASE_URL + url} ${params == null ? '' : 'params: ' + params.toString()}");
    }

    var resp = await _dio.get<T>(
      url,
      queryParameters: params,
    );
    return _handleResponse(resp);
  }

  Future<T> post<T>(String url, {Map<String, dynamic>? params, Map<String, dynamic>? data}) async {
    if (showLog) {
      LOG.D(_TAG, "post: ${Api.BASE_URL + url} data：${data.toString()} params：${params.toString()}");
    }

    var resp = await _dio.post(
      url,
      data: data,
      queryParameters: params,
    );
    return _handleResponse(resp);
  }

  /// delete
  Future<T> delete<T>(String url, {Map<String, dynamic>? params}) async {
    if (showLog) {
      LOG.D(_TAG, "post: ${Api.BASE_URL + url} params：${params.toString()}");
    }

    var resp = await _dio.delete(
      url,
      queryParameters: params,
    );
    return _handleResponse(resp);
  }

  // Stream download(String url, String savePath, {ProgressCallback? processCallback}) {
  //   if (showLog) {
  //     LOG.D(_TAG, "download: $url");
  //   }
  //   return Stream.fromFuture(_dio.download(url, savePath, onReceiveProgress: processCallback)).asBroadcastStream();
  // }

  T _handleResponse<T>(Response r) {
    try {
      if (showLog) {
        LOG.D(_TAG, "resp: ${r.toString()}");
      }
      var baseEntity = BaseEntity.fromMap(r.data);
      return baseEntity.data;
    } catch (e) {
      LOG.E(_TAG, e.toString());
      throw ApiException(e.toString());
    }
  }
}

class ApiException implements Exception {
  final String message;

  ApiException(this.message);
}
