import 'dart:convert';

import 'package:dio/dio.dart';

import '../model/my_work_model.dart';
import 'api_endpoints.dart';
import 'api_service.dart';

class MyWorkService {
  final ApiService _api;

  MyWorkService({ApiService? api}) : _api = api ?? ApiService();

  Future<MyWorkResponseModel> getMyWork({
    bool includeCompleted = true,
    int completedLimit = 100,
  }) async {
    try {
      final response = await _api.get(
        url: ApiEndpoints.myWork,
        queryParameters: {
          'include_completed': includeCompleted ? 1 : 0,
          'completed_limit': completedLimit.clamp(1, 200),
        },
      );
      final result = MyWorkResponseModel.fromJson(_rootMap(response.data));
      _ensureSuccess(result.success, result.message, 'Unable to fetch My Work.');
      return result;
    } on DioException catch (error) {
      throw Exception(_dioMessage(error, 'Unable to fetch My Work.'));
    }
  }

  Future<DashboardWorkResponseModel> getDashboardWork({int limit = 5}) async {
    try {
      final response = await _api.get(
        url: ApiEndpoints.dashboardWork,
        queryParameters: {'limit': limit.clamp(1, 20)},
      );
      final result =
          DashboardWorkResponseModel.fromJson(_rootMap(response.data));
      _ensureSuccess(
        result.success,
        result.message,
        'Unable to fetch dashboard work.',
      );
      return result;
    } on DioException catch (error) {
      throw Exception(_dioMessage(error, 'Unable to fetch dashboard work.'));
    }
  }

  /// Only ordinary ToDos can use this method. Task-linked ToDos must use the
  /// Task start/submission/review workflow exposed by TaskService.
  Future<CompleteTodoResultModel> completeTodo(String todoName) async {
    final cleanName = todoName.trim();
    if (cleanName.isEmpty) throw Exception('ToDo ID is required.');

    try {
      final response = await _api.post(
        url: ApiEndpoints.completeEmployeeTodo,
        data: {'todo': cleanName},
      );
      final result =
          CompleteTodoResultModel.fromJson(_rootMap(response.data));
      _ensureSuccess(
        result.success,
        result.message,
        'Unable to complete ToDo.',
      );
      return result;
    } on DioException catch (error) {
      throw Exception(_dioMessage(error, 'Unable to complete ToDo.'));
    }
  }

  Future<CompleteTodoResultModel> completeWorkItem(
    MyWorkItemModel item,
  ) async {
    if (!item.isTodo || !item.canCompleteDirectly) {
      throw Exception(
        'This work item must be completed through its own workflow.',
      );
    }
    final todoName = item.todoName;
    if (todoName == null) throw Exception('ToDo ID is missing.');
    return completeTodo(todoName);
  }
}

Map<String, dynamic> _rootMap(dynamic value) {
  return value is Map
      ? Map<String, dynamic>.from(value)
      : <String, dynamic>{};
}

void _ensureSuccess(bool success, String message, String fallback) {
  if (!success) {
    throw Exception(message.trim().isNotEmpty ? message : fallback);
  }
}

String _dioMessage(DioException error, String fallback) {
  final data = error.response?.data;
  if (data is Map) {
    final root = Map<String, dynamic>.from(data);
    final wrapped = root['message'];
    if (wrapped is Map) {
      final text = wrapped['message'] ?? wrapped['exception'];
      if (text != null && text.toString().trim().isNotEmpty) {
        return text.toString();
      }
    }

    final direct = root['message'] ?? root['exception'];
    if (direct != null && direct.toString().trim().isNotEmpty) {
      return direct.toString();
    }

    final serverMessages = root['_server_messages'];
    if (serverMessages != null) {
      try {
        final decoded = serverMessages is String
            ? jsonDecode(serverMessages)
            : serverMessages;
        if (decoded is List && decoded.isNotEmpty) {
          final first = decoded.first is String
              ? jsonDecode(decoded.first as String)
              : decoded.first;
          if (first is Map && first['message'] != null) {
            return first['message'].toString();
          }
        }
      } catch (_) {
        // Fall through to Dio's message.
      }
    }
  }

  final dioMessage = error.message?.trim();
  return dioMessage?.isNotEmpty == true ? dioMessage! : fallback;
}
