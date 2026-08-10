import 'package:flutter/foundation.dart';

import '../../../model/task_model.dart';
import '../../../services/task_manager_service.dart';
import '../../../services/task_service.dart';

class ReviewTaskViewModel extends ChangeNotifier {
  ReviewTaskViewModel({
    required TaskModel task,
    TaskManagerService? managerService,
    TaskService? taskService,
  })
      : _task = task,
        _managerService = managerService ?? TaskManagerService(),
        _taskService = taskService ?? TaskService();

  final TaskManagerService _managerService;
  final TaskService _taskService;
  TaskModel _task;
  String? errorMessage;
  bool loading = false;
  bool submitting = false;
  bool _disposed = false;
  bool _backendCanReview = false;

  TaskModel get task => _task;
  bool get canReview => _task.isPendingReview && _backendCanReview;

  Future<void> load() async {
    if (loading) return;
    loading = true;
    errorMessage = null;
    _notify();
    try {
      final result = await _taskService.getTaskDetails(_task.name);
      if (result.task == null) {
        throw Exception('Task details were not returned by the server.');
      }
      _task = result.task!;
      _backendCanReview = result.canReview;
    } catch (error) {
      errorMessage = _cleanError(error);
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<bool> approve({String? remarks}) => _review(action: 'approve', remarks: remarks);

  Future<bool> reject({required String remarks}) async {
    if (remarks.trim().isEmpty) {
      errorMessage = 'Review remarks are required for rejection.';
      _notify();
      return false;
    }
    return _review(action: 'reject', remarks: remarks);
  }

  Future<bool> _review({required String action, String? remarks}) async {
    if (submitting) return false;
    if (!canReview) {
      errorMessage = 'Only tasks pending review can be reviewed.';
      _notify();
      return false;
    }
    submitting = true;
    errorMessage = null;
    _notify();
    try {
      _task = await _managerService.reviewTask(
        taskName: _task.name,
        action: action,
        reviewRemarks: remarks,
      );
      _backendCanReview = false;
      return true;
    } catch (error) {
      errorMessage = _cleanError(error);
      return false;
    } finally {
      submitting = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

String _cleanError(Object error) => error.toString().replaceFirst('Exception: ', '');
