import 'package:dio/dio.dart';

import 'api_endpoints.dart';
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


  Future<void> download({
    required String url,
    required String savePath,
  }) async {
    final parsedUri = Uri.parse(url);

    final String downloadUrl;

    if (parsedUri.hasScheme) {
      // Full URL already provided.
      downloadUrl = url;
    } else {
      // ERPNext returns relative paths such as:
      // /private/files/Collage%20Image.png
      downloadUrl = Uri.parse(ApiEndpoints.baseUrl)
          .resolve(url)
          .toString();
    }

    print('DOWNLOAD URL: $downloadUrl');

    await dio.download(
      downloadUrl,
      savePath,
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