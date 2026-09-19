import 'package:dio/dio.dart';

import 'api_service.dart';
import 'api_endpoints.dart';

class SettingsService {
  final ApiService _apiService = ApiService();

  /// Changes the password of the currently authenticated user.
  ///
  /// Returns null on success, or an error message when the request fails.
  Future<String?> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await _apiService.post(
        url: ApiEndpoints.changePassword,
        data: {
          'new_password': newPassword,
          'old_password': currentPassword,
          'logout_all_sessions': 1,
        },
      );

      final data = response.data;
      final message = data is Map ? data['message'] : null;

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        if (message is Map && message['success'] == false) {
          return _readMessage(message) ?? 'Unable to change password.';
        }

        return null;
      }

      return _readMessage(data) ?? 'Unable to change password.';
    } on DioException catch (error) {
      return _readDioError(error);
    } catch (_) {
      return 'Unable to change password. Please try again.';
    }
  }

  String? _readDioError(DioException error) {
    final responseData = error.response?.data;
    final message = _readMessage(responseData);

    if (message != null && message.isNotEmpty) return message;

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Request timed out. Please try again.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Unable to connect to the server.';
    }

    return 'Unable to change password. Please try again.';
  }

  String? _readMessage(dynamic data) {
    if (data is String && data.trim().isNotEmpty) return data.trim();

    if (data is Map) {
      final message = data['message'];

      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }

      if (message is Map) {
        final nested = message['message'];
        if (nested is String && nested.trim().isNotEmpty) {
          return nested.trim();
        }
      }

      final exception = data['exception'];
      if (exception is String && exception.trim().isNotEmpty) {
        return exception.split(':').last.trim();
      }

      final exc = data['_server_messages'];
      if (exc is String && exc.trim().isNotEmpty) {
        return exc;
      }
    }

    return null;
  }
}
