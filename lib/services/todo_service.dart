import 'package:dio/dio.dart';
import '../model/todo_model.dart';
import 'api_endpoints.dart';
import 'api_service.dart';

class TodoService {
  final ApiService _api;
  TodoService({ApiService? api}) : _api = api ?? ApiService();

  Future<EmployeeTodosResponseModel> getEmployeeTodos() async {
    try {
      final response = await _api.get(url: ApiEndpoints.employeeTodos);
      final result = EmployeeTodosResponseModel.fromJson(_message(response.data));
      if (!result.success) throw Exception(result.message.isEmpty
          ? 'Unable to fetch ToDos.' : result.message);
      return result;
    } on DioException catch (e) { throw Exception(_dioMessage(e)); }
  }

  Future<DashboardTodosResponseModel> getDashboardTodos() async {
    try {
      final response = await _api.get(url: ApiEndpoints.dashboardTodos);
      final result = DashboardTodosResponseModel.fromJson(_message(response.data));
      if (!result.success) throw Exception(result.message.isEmpty
          ? 'Unable to fetch dashboard ToDos.' : result.message);
      return result;
    } on DioException catch (e) { throw Exception(_dioMessage(e)); }
  }

  Future<void> completeTodo(String todoName) async {
    try {
      final response = await _api.post(url: ApiEndpoints.completeEmployeeTodo,
        data: {'todo': todoName});
      final data = _message(response.data);
      if (data['success'] != true) throw Exception(
          data['message']?.toString() ?? 'Unable to complete ToDo.');
    } on DioException catch (e) { throw Exception(_dioMessage(e)); }
  }

  Map<String, dynamic> _message(dynamic value) {
    final root = value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
    return root['message'] is Map
        ? Map<String, dynamic>.from(root['message']) : root;
  }
  String _dioMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final root = data['message'];
      if (root is Map && root['message'] != null) return root['message'].toString();
      final text = data['exception'] ?? data['message'];
      if (text != null) return text.toString();
    }
    return e.message ?? 'Unable to process ToDo request.';
  }
}
