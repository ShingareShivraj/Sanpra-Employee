import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../model/dashboard_task_model.dart';
import '../model/task_detail_model.dart';
import '../model/task_model.dart';
import 'api_endpoints.dart';
import 'api_service.dart';


/// Employee-facing task APIs.
class TaskService {
  final ApiService _api;

  TaskService({ApiService? api}) : _api = api ?? ApiService();

  Future<EmployeeTasksResponseModel> getEmployeeTasks() async {
    try {
      final response = await _api.get(url: ApiEndpoints.employeeTasks);
      final result = EmployeeTasksResponseModel.fromJson(_rootMap(response.data));
      _ensureSuccess(result.success, result.message, 'Unable to fetch tasks.');
      return result;
    } on DioException catch (error) {
      throw Exception(_dioMessage(error, 'Unable to fetch tasks.'));
    }
  }

  Future<DashboardTaskModel> getDashboardTasks({int limit = 5}) async {
    try {
      final response = await _api.get(
        url: ApiEndpoints.dashboardTasks,
        queryParameters: {'limit': limit.clamp(1, 20)},
      );
      final result = DashboardTaskModel.fromJson(_rootMap(response.data));
      _ensureSuccess(
        result.success,
        result.message,
        'Unable to fetch dashboard tasks.',
      );
      return result;
    } on DioException catch (error) {
      throw Exception(_dioMessage(error, 'Unable to fetch dashboard tasks.'));
    }
  }

  Future<TaskDetailModel> getTaskDetails(String taskName) async {
    _requireText(taskName, 'Task name is required.');
    try {
      final response = await _api.get(
        url: ApiEndpoints.taskDetails,
        queryParameters: {'task_name': taskName.trim()},
      );
      final result = TaskDetailModel.fromJson(_rootMap(response.data));
      _ensureSuccess(result.success, result.message, 'Unable to fetch task details.');
      return result;
    } on DioException catch (error) {
      throw Exception(_dioMessage(error, 'Unable to fetch task details.'));
    }
  }

  Future<TaskModel> startTask(String taskName) async {
    _requireText(taskName, 'Task name is required.');
    try {
      final response = await _api.post(
        url: ApiEndpoints.startEmployeeTask,
        data: {'task_name': taskName.trim()},
      );
      return _taskFromAction(response.data, 'Unable to start task.');
    } on DioException catch (error) {
      throw Exception(_dioMessage(error, 'Unable to start task.'));
    }
  }

  Future<String> uploadTaskProof({
    required String taskName,
    required String localPath,
  }) async {
    _requireText(taskName, 'Task name is required.');
    _requireText(localPath, 'Proof file is required.');

    try {
      final fileName = path.basename(localPath);

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          localPath,
          filename: fileName,
        ),
        'is_private': 1,
        'doctype': 'Task',
        'docname': taskName.trim(),
        'fieldname': 'custom_completion_photo',
      });

      final response = await _api.postMultipart(
        url: ApiEndpoints.uploadFile,
        data: formData,
      );

      final data = _messageMap(response.data);
      final fileUrl = data['file_url']?.toString().trim() ?? '';

      if (fileUrl.isEmpty) {
        throw Exception('Server did not return the uploaded file URL.');
      }

      return fileUrl;
    } on DioException catch (error) {
      throw Exception(
        _dioMessage(error, 'Unable to upload proof file.'),
      );
    }
  }

  Future<String> downloadTaskProof(String fileUrl) async {
    _requireText(fileUrl, 'Proof file URL is required.');

    try {
      final uri = Uri.parse(fileUrl);
      var fileName = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last
          : 'task-proof';

      if (fileName.trim().isEmpty) {
        fileName = 'task-proof';
      }

      final directory = await getTemporaryDirectory();
      final savePath = path.join(directory.path, fileName);

      await _api.download(
        url: fileUrl,
        savePath: savePath,
      );

      return savePath;
    } on DioException catch (error) {
      throw Exception(
        _dioMessage(error, 'Unable to download proof file.'),
      );
    }
  }

  /// Submits employee work for manager review. It does not complete the Task.
  Future<TaskModel> submitTaskCompletion({
    required String taskName,
    required String completionRemarks,
    String? completionPhoto,
    double? latitude,
    double? longitude,
  }) async {
    _requireText(taskName, 'Task name is required.');
    _requireText(completionRemarks, 'Completion remarks are required.');
    if (latitude != null && (latitude < -90 || latitude > 90)) {
      throw Exception('Latitude must be between -90 and 90.');
    }
    if (longitude != null && (longitude < -180 || longitude > 180)) {
      throw Exception('Longitude must be between -180 and 180.');
    }

    try {
      final response = await _api.post(
        url: ApiEndpoints.submitTaskCompletion,
        data: {
          'task_name': taskName.trim(),
          'completion_remarks': completionRemarks.trim(),
          if (completionPhoto?.trim().isNotEmpty == true)
            'completion_photo': completionPhoto!.trim(),
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        },
      );
      return _taskFromAction(
        response.data,
        'Unable to submit task completion.',
      );
    } on DioException catch (error) {
      throw Exception(_dioMessage(error, 'Unable to submit task completion.'));
    }
  }
}

TaskModel _taskFromAction(dynamic responseData, String fallback) {
  final data = _messageMap(responseData);
  final success = _bool(data['success']);
  final message = data['message']?.toString() ?? '';
  _ensureSuccess(success, message, fallback);
  final task = data['task'];
  if (task is! Map) throw Exception(message.isNotEmpty ? message : fallback);
  return TaskModel.fromJson(Map<String, dynamic>.from(task));
}

Map<String, dynamic> _rootMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

Map<String, dynamic> _messageMap(dynamic value) {
  final root = _rootMap(value);
  final message = root['message'];
  return message is Map ? Map<String, dynamic>.from(message) : root;
}

void _ensureSuccess(bool success, String message, String fallback) {
  if (!success) throw Exception(message.trim().isNotEmpty ? message : fallback);
}

void _requireText(String value, String message) {
  if (value.trim().isEmpty) throw Exception(message);
}

bool _bool(dynamic value) =>
    value == true || value == 1 || value == '1' || value == 'true';

String _dioMessage(DioException error, String fallback) {
  final data = error.response?.data;
  if (data is Map) {
    final root = Map<String, dynamic>.from(data);
    final wrapped = root['message'];
    if (wrapped is Map) {
      final text = wrapped['message'] ?? wrapped['exception'];
      if (text != null && text.toString().trim().isNotEmpty) return text.toString();
    }
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
