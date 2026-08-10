import 'dart:convert';

import 'package:dio/dio.dart';

import '../model/employee_model.dart';
import '../model/task_model.dart';
import 'api_endpoints.dart';
import 'api_service.dart';

/// Manager-only task APIs. Backend permissions remain authoritative.
class TaskManagerService {
  final ApiService _api;

  TaskManagerService({ApiService? api}) : _api = api ?? ApiService();

  Future<EmployeeListResponseModel> getCompanyEmployees({
    String? search,
    String? company,
    int limit = 50,
  }) async {
    try {
      final response = await _api.get(
        url: ApiEndpoints.companyEmployees,
        queryParameters: {
          if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
          if (company?.trim().isNotEmpty == true) 'company': company!.trim(),
          'limit': limit.clamp(1, 200),
        },
      );
      final result = EmployeeListResponseModel.fromJson(_rootMap(response.data));
      _ensureSuccess(result.success, result.message, 'Unable to fetch employees.');
      return result;
    } on DioException catch (error) {
      throw Exception(_dioMessage(error, 'Unable to fetch employees.'));
    }
  }

  Future<CompanyTasksResult> getCompanyTasks({
    String? status,
    String? project,
    String? assignedTo,
    String? search,
    String? company,
    int start = 0,
    int pageLength = 20,
  }) async {
    try {
      final response = await _api.get(
        url: ApiEndpoints.companyTasks,
        queryParameters: {
          if (status?.trim().isNotEmpty == true) 'status': status!.trim(),
          if (project?.trim().isNotEmpty == true) 'project': project!.trim(),
          if (assignedTo?.trim().isNotEmpty == true) 'assigned_to': assignedTo!.trim(),
          if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
          if (company?.trim().isNotEmpty == true) 'company': company!.trim(),
          'start': start < 0 ? 0 : start,
          'page_length': pageLength.clamp(1, 100),
        },
      );
      final result = CompanyTasksResult.fromJson(_rootMap(response.data));
      _ensureSuccess(result.success, result.message, 'Unable to fetch company tasks.');
      return result;
    } on DioException catch (error) {
      throw Exception(_dioMessage(error, 'Unable to fetch company tasks.'));
    }
  }

  Future<TaskModel> createTask({
    required String subject,
    String? description,
    String priority = 'Medium',
    DateTime? expectedStartDate,
    DateTime? expectedEndDate,
    String? project,
    List<String> assignedUsers = const [],
    String? company,
  }) async {
    _requireText(subject, 'Task subject is required.');
    if (expectedStartDate != null && expectedEndDate != null && expectedEndDate.isBefore(expectedStartDate)) {
      throw Exception('Expected end date cannot be before start date.');
    }
    return _taskAction(
      ApiEndpoints.createTask,
      {
        'subject': subject.trim(),
        if (description?.trim().isNotEmpty == true) 'description': description!.trim(),
        'priority': priority,
        if (expectedStartDate != null) 'expected_start_date': _date(expectedStartDate),
        if (expectedEndDate != null) 'expected_end_date': _date(expectedEndDate),
        if (project?.trim().isNotEmpty == true) 'project': project!.trim(),
        'assigned_users': jsonEncode(assignedUsers),
        if (company?.trim().isNotEmpty == true) 'company': company!.trim(),
      },
      'Unable to create task.',
    );
  }

  Future<List<TaskAssigneeModel>> assignTask({
    required String taskName,
    required List<String> assignedUsers,
  }) async {
    _requireText(taskName, 'Task name is required.');
    if (assignedUsers.isEmpty) throw Exception('Select at least one employee.');
    return _assignmentAction(ApiEndpoints.assignTask, {
      'task_name': taskName.trim(),
      'assigned_users': jsonEncode(assignedUsers),
    }, 'Unable to assign task.');
  }

  Future<List<TaskAssigneeModel>> reassignTask({
    required String taskName,
    required String fromUser,
    required String toUser,
  }) async {
    _requireText(taskName, 'Task name is required.');
    _requireText(fromUser, 'Current assigned user is required.');
    _requireText(toUser, 'New assigned user is required.');
    if (fromUser.trim() == toUser.trim()) {
      throw Exception('Current and new assigned users cannot be the same.');
    }
    return _assignmentAction(ApiEndpoints.reassignTask, {
      'task_name': taskName.trim(),
      'from_user': fromUser.trim(),
      'to_user': toUser.trim(),
    }, 'Unable to reassign task.');
  }

  Future<List<TaskModel>> getPendingReviewTasks({String? company}) async {
    try {
      final response = await _api.get(
        url: ApiEndpoints.pendingReviewTasks,
        queryParameters: {
          if (company?.trim().isNotEmpty == true) 'company': company!.trim(),
        },
      );
      final data = _messageMap(response.data);
      _ensureSuccess(_bool(data['success']), data['message']?.toString() ?? '', 'Unable to fetch pending-review tasks.');
      return _taskList(data['tasks']);
    } on DioException catch (error) {
      throw Exception(_dioMessage(error, 'Unable to fetch pending-review tasks.'));
    }
  }

  Future<TaskModel> reviewTask({
    required String taskName,
    required String action,
    String? reviewRemarks,
  }) async {
    _requireText(taskName, 'Task name is required.');
    final cleanAction = action.trim().toLowerCase();
    if (cleanAction != 'approve' && cleanAction != 'reject') {
      throw Exception('Action must be approve or reject.');
    }
    if (cleanAction == 'reject' && reviewRemarks?.trim().isNotEmpty != true) {
      throw Exception('Review remarks are required for rejection.');
    }
    return _taskAction(ApiEndpoints.reviewTask, {
      'task_name': taskName.trim(),
      'action': cleanAction,
      if (reviewRemarks?.trim().isNotEmpty == true) 'review_remarks': reviewRemarks!.trim(),
    }, 'Unable to review task.');
  }

  Future<TaskModel> _taskAction(String url, Map<String, dynamic> body, String fallback) async {
    try {
      final response = await _api.post(url: url, data: body);
      final data = _messageMap(response.data);
      _ensureSuccess(_bool(data['success']), data['message']?.toString() ?? '', fallback);
      if (data['task'] is! Map) throw Exception(fallback);
      return TaskModel.fromJson(Map<String, dynamic>.from(data['task']));
    } on DioException catch (error) {
      throw Exception(_dioMessage(error, fallback));
    }
  }

  Future<List<TaskAssigneeModel>> _assignmentAction(String url, Map<String, dynamic> body, String fallback) async {
    try {
      final response = await _api.post(url: url, data: body);
      final data = _messageMap(response.data);
      _ensureSuccess(_bool(data['success']), data['message']?.toString() ?? '', fallback);
      final rows = data['assignees'];
      return rows is List
          ? rows.whereType<Map>().map((row) => TaskAssigneeModel.fromJson(Map<String, dynamic>.from(row))).toList()
          : <TaskAssigneeModel>[];
    } on DioException catch (error) {
      throw Exception(_dioMessage(error, fallback));
    }
  }
}

class CompanyTasksResult {
  final bool success;
  final String message;
  final String? company;
  final int total;
  final int start;
  final int pageLength;
  final bool hasMore;
  final List<TaskModel> tasks;

  const CompanyTasksResult({required this.success, this.message = '', this.company, this.total = 0, this.start = 0, this.pageLength = 20, this.hasMore = false, this.tasks = const []});

  factory CompanyTasksResult.fromJson(Map<String, dynamic> json) {
    final data = _messageMap(json);
    return CompanyTasksResult(
      success: _bool(data['success']),
      message: data['message']?.toString() ?? '',
      company: data['company']?.toString(),
      total: _int(data['total']),
      start: _int(data['start']),
      pageLength: _int(data['page_length'], 20),
      hasMore: _bool(data['has_more']),
      tasks: _taskList(data['tasks']),
    );
  }
}

List<TaskModel> _taskList(dynamic value) => value is List
    ? value.whereType<Map>().map((row) => TaskModel.fromJson(Map<String, dynamic>.from(row))).toList()
    : <TaskModel>[];
Map<String, dynamic> _rootMap(dynamic value) => value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
Map<String, dynamic> _messageMap(dynamic value) { final root = _rootMap(value); final message = root['message']; return message is Map ? Map<String, dynamic>.from(message) : root; }
void _ensureSuccess(bool success, String message, String fallback) { if (!success) throw Exception(message.trim().isNotEmpty ? message : fallback); }
void _requireText(String value, String message) { if (value.trim().isEmpty) throw Exception(message); }
bool _bool(dynamic value) => value == true || value == 1 || value == '1' || value == 'true';
int _int(dynamic value, [int fallback = 0]) => value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? fallback;
String _date(DateTime value) => value.toIso8601String().split('T').first;

String _dioMessage(DioException error, String fallback) {
  final data = error.response?.data;
  if (data is Map) {
    final root = Map<String, dynamic>.from(data);
    final wrapped = root['message'];
    if (wrapped is Map && wrapped['message'] != null) return wrapped['message'].toString();
    final direct = root['message'] ?? root['exception'];
    if (direct != null && direct.toString().trim().isNotEmpty) return direct.toString();
    final serverMessages = root['_server_messages'];
    if (serverMessages != null) {
      try {
        final decoded = serverMessages is String ? jsonDecode(serverMessages) : serverMessages;
        if (decoded is List && decoded.isNotEmpty) {
          final first = decoded.first is String ? jsonDecode(decoded.first) : decoded.first;
          if (first is Map && first['message'] != null) return first['message'].toString();
        }
      } catch (_) {}
    }
  }
  return error.message?.trim().isNotEmpty == true ? error.message! : fallback;
}
