import 'package:dio/dio.dart';

import 'secure_storage_service.dart';

class ApiService {
  late Dio dio;

  ApiService() {
    dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      ),
    );

    // Automatically attach Authorization Header
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {

          final apiKey =
          await SecureStorageService.instance.getApiKey();

          final apiSecret =
          await SecureStorageService.instance.getApiSecret();

          if (apiKey != null &&
              apiSecret != null &&
              apiKey.isNotEmpty &&
              apiSecret.isNotEmpty) {

            options.headers["Authorization"] =
            "token $apiKey:$apiSecret";
          }

          return handler.next(options);
        },
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
      ),
    );
  }

  Future<Response> get({
    required String url,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {

    return await dio.get(
      url,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> post({
    required String url,
    dynamic data,
    Options? options,
  }) async {

    return await dio.post(
      url,
      data: data,
      options: options,
    );
  }


  // =============================================================
// MULTIPART POST
// =============================================================

  Future<Response> postMultipart({
    required String url,
    required FormData data,
  }) async {
    return await dio.post(
      url,
      data: data,
      options: Options(
        contentType:
        Headers.multipartFormDataContentType,
      ),
    );
  }

  Future<Response> put({
    required String url,
    dynamic data,
    Options? options,
  }) async {

    return await dio.put(
      url,
      data: data,
      options: options,
    );
  }

  Future<Response> delete({
    required String url,
    dynamic data,
    Options? options,
  }) async {

    return await dio.delete(
      url,
      data: data,
      options: options,
    );
  }
}