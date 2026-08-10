import 'package:flutter/foundation.dart';

import '../../../model/task_detail_model.dart';
import '../../../model/task_model.dart';
import '../../../services/task_service.dart';

class TaskDetailsViewModel extends ChangeNotifier {
  TaskDetailsViewModel({required this.taskName, TaskService? taskService})
      : _taskService = taskService ?? TaskService();

  final String taskName;
  final TaskService _taskService;

  bool loading = false;
  bool starting = false;
  String? errorMessage;
  TaskDetailModel? details;

  TaskModel? get task => details?.task;
  bool get canStart => details?.canStart == true;
  bool get canSubmitCompletion => details?.canSubmitCompletion == true;

  Future<void> loadDetails() async {
    if (loading) return;
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      details = await _taskService.getTaskDetails(taskName);
      print("================================");
      print(details?.task?.status);
      print(details?.canStart);
      print(details?.canSubmitCompletion);
      print(details?.canReview);
      print("================================");
    } catch (error) {
      errorMessage = _cleanError(error);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> startTask() async {
    if (starting || !canStart) return false;
    starting = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _taskService.startTask(taskName);
      details = await _taskService.getTaskDetails(taskName);
      return true;
    } catch (error) {
      errorMessage = _cleanError(error);
      return false;
    } finally {
      starting = false;
      notifyListeners();
    }
  }

  static String _cleanError(Object error) {
    final text = error.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }
}
