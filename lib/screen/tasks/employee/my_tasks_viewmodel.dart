import 'package:flutter/foundation.dart';

import '../../../model/task_model.dart';
import '../../../services/task_service.dart';

class MyTasksViewModel extends ChangeNotifier {
  MyTasksViewModel({TaskService? taskService})
      : _taskService = taskService ?? TaskService();

  final TaskService _taskService;

  bool _loading = false;
  bool _refreshing = false;
  String? _errorMessage;
  EmployeeTasksResponseModel? _response;

  bool get loading => _loading;
  bool get refreshing => _refreshing;
  String? get errorMessage => _errorMessage;

  List<TaskModel> get overdue => _response?.overdue ?? const [];
  List<TaskModel> get today => _response?.today ?? const [];
  List<TaskModel> get upcoming => _response?.upcoming ?? const [];
  List<TaskModel> get pendingReview => _response?.pendingReview ?? const [];
  List<TaskModel> get completed => _response?.completed ?? const [];

  int get openCount => overdue.length + today.length + upcoming.length;
  int get pendingReviewCount => pendingReview.length;
  bool get hasTasks =>
      overdue.isNotEmpty ||
      today.isNotEmpty ||
      upcoming.isNotEmpty ||
      pendingReview.isNotEmpty ||
      completed.isNotEmpty;

  Future<void> loadTasks({bool force = false}) async {
    if (_loading || _refreshing) return;
    if (!force && _response != null) return;
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    await _fetch();
    _loading = false;
    notifyListeners();
  }

  Future<void> refreshTasks() async {
    if (_loading || _refreshing) return;
    _refreshing = true;
    _errorMessage = null;
    notifyListeners();
    await _fetch();
    _refreshing = false;
    notifyListeners();
  }

  Future<void> _fetch() async {
    try {
      _response = await _taskService.getEmployeeTasks();
    } catch (error) {
      _errorMessage = _cleanError(error);
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  static String _cleanError(Object error) {
    final text = error.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }
}
