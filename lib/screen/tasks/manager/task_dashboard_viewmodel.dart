import 'package:flutter/foundation.dart';

import '../../../model/task_model.dart';
import '../../../services/task_manager_service.dart';

class TaskDashboardViewModel extends ChangeNotifier {
  TaskDashboardViewModel({TaskManagerService? service})
      : _service = service ?? TaskManagerService();

  final TaskManagerService _service;
  bool loading = false;
  bool refreshing = false;
  String? errorMessage;
  String? company;
  int totalTasks = 0;
  int openTotal = 0;
  int workingTotal = 0;
  int completedTotal = 0;
  List<TaskModel> recentTasks = const [];
  List<TaskModel> pendingReviews = const [];
  bool _disposed = false;

  int get pendingReviewCount => pendingReviews.length;
  int get openCount => openTotal;
  int get workingCount => workingTotal;
  int get completedCount => completedTotal;
  bool get hasData => totalTasks > 0 || pendingReviews.isNotEmpty;

  Future<void> load({bool refresh = false}) async {
    if (loading || refreshing) return;
    refresh ? refreshing = true : loading = true;
    errorMessage = null;
    _notify();
    try {
      final results = await Future.wait<dynamic>([
        _service.getCompanyTasks(pageLength: 5),
        _service.getCompanyTasks(status: 'Open', pageLength: 1),
        _service.getCompanyTasks(status: 'Working', pageLength: 1),
        _service.getCompanyTasks(status: 'Completed', pageLength: 1),
        _service.getPendingReviewTasks(),
      ]);
      final companyResult = results[0] as CompanyTasksResult;
      company = companyResult.company;
      totalTasks = companyResult.total;
      recentTasks = companyResult.tasks;
      openTotal = (results[1] as CompanyTasksResult).total;
      workingTotal = (results[2] as CompanyTasksResult).total;
      completedTotal = (results[3] as CompanyTasksResult).total;
      pendingReviews = results[4] as List<TaskModel>;
    } catch (error) {
      errorMessage = _cleanError(error);
    } finally {
      loading = false;
      refreshing = false;
      _notify();
    }
  }

  Future<void> refresh() => load(refresh: true);
  void clearError() { errorMessage = null; _notify(); }
  void _notify() { if (!_disposed) notifyListeners(); }
  @override
  void dispose() { _disposed = true; super.dispose(); }
}

String _cleanError(Object error) => error.toString().replaceFirst('Exception: ', '');
