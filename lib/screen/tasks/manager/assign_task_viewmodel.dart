import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../model/employee_model.dart';
import '../../../model/task_model.dart';
import '../../../services/task_manager_service.dart';
import '../../../services/task_service.dart';

class AssignTaskViewModel extends ChangeNotifier {
  AssignTaskViewModel({
    required this.taskName,
    TaskManagerService? managerService,
    TaskService? taskService,
  })  : _managerService = managerService ?? TaskManagerService(),
        _taskService = taskService ?? TaskService();

  final String taskName;
  final TaskManagerService _managerService;
  final TaskService _taskService;

  TaskModel? task;
  List<EmployeeModel> employees = const [];
  final Set<String> selectedUsers = <String>{};
  String? fromUser;
  String? toUser;
  String? company;
  String? errorMessage;
  bool loading = false;
  bool assigning = false;
  bool reassigning = false;
  bool _disposed = false;
  Timer? _searchTimer;

  List<TaskAssigneeModel> get assignees => task?.assignees ?? const [];
  bool get canEdit => task != null && !task!.isCompleted && task!.status.toLowerCase() != 'cancelled';

  Future<void> initialise() async {
    if (loading) return;
    loading = true;
    errorMessage = null;
    _notify();
    try {
      final detail = await _taskService.getTaskDetails(taskName);
      final employeeResult = await _managerService.getCompanyEmployees(limit: 200);
      task = detail.task;
      employees = employeeResult.employees;
      company = employeeResult.company;
      if (task == null) throw Exception('Task details were not returned.');
    } catch (error) {
      errorMessage = _cleanError(error);
    } finally {
      loading = false;
      _notify();
    }
  }

  void searchEmployees(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 400), () => loadEmployees(search: value));
  }

  Future<void> loadEmployees({String? search}) async {
    try {
      final result = await _managerService.getCompanyEmployees(search: search, company: company, limit: 200);
      employees = result.employees;
      company = result.company ?? company;
      errorMessage = null;
    } catch (error) {
      errorMessage = _cleanError(error);
    }
    _notify();
  }

  void toggleUser(String userId) {
    selectedUsers.contains(userId) ? selectedUsers.remove(userId) : selectedUsers.add(userId);
    _notify();
  }

  void setFromUser(String? value) {
    fromUser = value;
    if (toUser == value) toUser = null;
    _notify();
  }

  void setToUser(String? value) {
    toUser = value;
    _notify();
  }

  Future<bool> assignSelected() async {
    if (assigning || reassigning) return false;
    if (!canEdit) return _fail('Completed or cancelled tasks cannot be assigned.');
    if (selectedUsers.isEmpty) return _fail('Select at least one employee.');
    assigning = true;
    errorMessage = null;
    _notify();
    try {
      await _managerService.assignTask(taskName: taskName, assignedUsers: selectedUsers.toList());
      selectedUsers.clear();
      await _reloadTask();
      return true;
    } catch (error) {
      errorMessage = _cleanError(error);
      return false;
    } finally {
      assigning = false;
      _notify();
    }
  }

  Future<bool> reassign() async {
    if (assigning || reassigning) return false;
    if (!canEdit) return _fail('Completed or cancelled tasks cannot be reassigned.');
    if (fromUser == null || fromUser!.isEmpty) return _fail('Select the current assignee.');
    if (toUser == null || toUser!.isEmpty) return _fail('Select the new employee.');
    if (fromUser == toUser) return _fail('Current and new employees cannot be the same.');
    reassigning = true;
    errorMessage = null;
    _notify();
    try {
      await _managerService.reassignTask(taskName: taskName, fromUser: fromUser!, toUser: toUser!);
      fromUser = null;
      toUser = null;
      await _reloadTask();
      return true;
    } catch (error) {
      errorMessage = _cleanError(error);
      return false;
    } finally {
      reassigning = false;
      _notify();
    }
  }

  Future<void> _reloadTask() async {
    final detail = await _taskService.getTaskDetails(taskName);
    task = detail.task;
  }

  bool _fail(String message) {
    errorMessage = message;
    _notify();
    return false;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _searchTimer?.cancel();
    super.dispose();
  }
}

String _cleanError(Object error) => error.toString().replaceFirst('Exception: ', '');
