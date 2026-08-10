import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../model/employee_model.dart';
import '../../../model/task_model.dart';
import '../../../services/task_manager_service.dart';

class CompanyTasksViewModel extends ChangeNotifier {
  CompanyTasksViewModel({TaskManagerService? service, String? initialStatus})
      : _service = service ?? TaskManagerService(), status = initialStatus;
  final TaskManagerService _service;
  final List<TaskModel> tasks = [];
  List<EmployeeModel> employees = const [];
  String? status, project, assignedTo, company, errorMessage;
  String search = '';
  int total = 0;
  bool loading = false, refreshing = false, loadingMore = false, hasMore = false;
  bool _disposed = false;
  Timer? _searchTimer;
  static const int pageLength = 20;

  Future<void> initialise() async {
    await Future.wait([loadTasks(), loadEmployees()]);
  }

  Future<void> loadEmployees() async {
    try {
      final result = await _service.getCompanyEmployees(limit: 200);
      employees = result.employees;
      company ??= result.company;
      _notify();
    } catch (error) {
      errorMessage ??= _cleanError(error);
      _notify();
    }
  }

  Future<void> loadTasks({bool refresh = false}) async {
    if (loading || refreshing) return;
    refresh ? refreshing = true : loading = true;
    errorMessage = null;
    _notify();
    try {
      final result = await _service.getCompanyTasks(
        status: status, project: project, assignedTo: assignedTo,
        search: search, company: company, pageLength: pageLength,
      );
      tasks..clear()..addAll(result.tasks);
      total = result.total; hasMore = result.hasMore; company ??= result.company;
    } catch (error) { errorMessage = _cleanError(error); }
    finally { loading = false; refreshing = false; _notify(); }
  }

  Future<void> loadMore() async {
    if (!hasMore || loadingMore || loading || refreshing) return;
    loadingMore = true; _notify();
    try {
      final result = await _service.getCompanyTasks(
        status: status, project: project, assignedTo: assignedTo,
        search: search, company: company, start: tasks.length, pageLength: pageLength,
      );
      final existing = tasks.map((e) => e.name).toSet();
      tasks.addAll(result.tasks.where((e) => existing.add(e.name)));
      total = result.total; hasMore = result.hasMore;
    } catch (error) { errorMessage = _cleanError(error); }
    finally { loadingMore = false; _notify(); }
  }

  void updateSearch(String value) {
    search = value.trim(); _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 450), () => loadTasks(refresh: true));
  }
  Future<void> setStatus(String? value) async { status = _emptyToNull(value); await loadTasks(refresh: true); }
  Future<void> setAssignedTo(String? value) async { assignedTo = _emptyToNull(value); await loadTasks(refresh: true); }
  Future<void> setProject(String value) async { project = _emptyToNull(value); await loadTasks(refresh: true); }
  Future<void> clearFilters() async { status = null; project = null; assignedTo = null; search = ''; await loadTasks(refresh: true); }
  Future<void> refresh() => loadTasks(refresh: true);
  void _notify() { if (!_disposed) notifyListeners(); }
  @override
  void dispose() { _searchTimer?.cancel(); _disposed = true; super.dispose(); }
}

String? _emptyToNull(String? value) => value == null || value.trim().isEmpty ? null : value.trim();
String _cleanError(Object error) => error.toString().replaceFirst('Exception: ', '');
