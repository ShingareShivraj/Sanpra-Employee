import 'dart:convert';

import 'package:dio/dio.dart';

import '../model/actions_needed_model.dart';
import 'api_endpoints.dart';
import 'api_service.dart';

class ActionsNeededService {
  final ApiService _api;

  ActionsNeededService({ApiService? api}) : _api = api ?? ApiService();

  Future<ActionsNeededResponseModel> getActionsNeeded({int limit = 50}) async {
    try {
      final response = await _api.get(
        url: ApiEndpoints.actionsNeeded,
        queryParameters: {
          'limit': limit.clamp(1, 100),
        },
      );
      final data = _unwrapMessage(response.data);
      if (data['success'] == false) {
        throw ActionsNeededServiceException(
          _messageFromData(
            data,
            fallback: 'Unable to load actions needed.',
          ),
        );
      }
      return ActionsNeededResponseModel.fromJson(data);
    } on DioException catch (error) {
      throw ActionsNeededServiceException(_dioMessage(error));
    } on ActionsNeededServiceException {
      rethrow;
    } catch (error) {
      throw ActionsNeededServiceException(_cleanError(error));
    }
  }

  static Map<String, dynamic> _unwrapMessage(dynamic value) {
    final root = _map(value);
    return root['message'] is Map ? _map(root['message']) : root;
  }

  static Map<String, dynamic> _map(dynamic value) {
    return value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};
  }

  static String _messageFromData(
    Map<String, dynamic> data, {
    required String fallback,
  }) {
    final value = data['message'];
    if (value is String && value.trim().isNotEmpty) {
      return _stripHtml(value);
    }
    if (value is Map && value['message'] != null) {
      return _stripHtml(value['message'].toString());
    }
    return fallback;
  }

  static String _dioMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final serverMessages = data['_server_messages'];
      if (serverMessages is String && serverMessages.isNotEmpty) {
        try {
          final decoded = jsonDecode(serverMessages);
          if (decoded is List && decoded.isNotEmpty) {
            final first = jsonDecode(decoded.first.toString());
            if (first is Map && first['message'] != null) {
              return _stripHtml(first['message'].toString());
            }
          }
        } catch (_) {}
      }

      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return _stripHtml(message);
      }
      if (message is Map && message['message'] != null) {
        return _stripHtml(message['message'].toString());
      }
      if (data['exception'] != null) {
        return data['exception']
            .toString()
            .split('\n')
            .first
            .replaceFirst(RegExp(r'^[\w.]+:\s*'), '');
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The request timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to the server.';
      default:
        return error.message ?? 'Unable to load actions needed.';
    }
  }

  static String _stripHtml(String value) {
    return value.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  static String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst(RegExp(r'^ActionsNeededServiceException:\s*'), '');
  }
}

class ActionsNeededServiceException implements Exception {
  final String message;

  const ActionsNeededServiceException(this.message);

  @override
  String toString() => message;
}
