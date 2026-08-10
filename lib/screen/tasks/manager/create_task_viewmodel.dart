import 'package:flutter/foundation.dart';

import '../../../model/employee_model.dart';
import '../../../model/task_model.dart';
import '../../../services/task_manager_service.dart';

class CreateTaskViewModel extends ChangeNotifier {
  CreateTaskViewModel({TaskManagerService? service}) : _service = service ?? TaskManagerService();
  final TaskManagerService _service;
  List<EmployeeModel> employees = const [];
  final Set<String> selectedUsers = {};
  String priority = 'Medium';
  DateTime? startDate, endDate;
  String? company, errorMessage;
  bool loadingEmployees = false, submitting = false;
  bool _disposed = false;
  static const priorities = ['Low', 'Medium', 'High', 'Urgent'];

  Future<void> loadEmployees({String? search}) async {
    if (loadingEmployees) return;
    loadingEmployees = true; errorMessage = null; _notify();
    try {
      final result = await _service.getCompanyEmployees(search: search, limit: 200);
      employees = result.employees; company = result.company;
    } catch (error) { errorMessage = _cleanError(error); }
    finally { loadingEmployees = false; _notify(); }
  }

  void setPriority(String? value) { if (value != null) { priority = value; _notify(); } }
  void setStartDate(DateTime? value) { startDate = value; if (endDate != null && value != null && endDate!.isBefore(value)) endDate = null; _notify(); }
  void setEndDate(DateTime? value) { endDate = value; _notify(); }
  void toggleEmployee(String userId) { selectedUsers.contains(userId) ? selectedUsers.remove(userId) : selectedUsers.add(userId); _notify(); }

  String? validate({required String subject}) {
    if (subject.trim().isEmpty) return 'Task subject is required.';
    if (!priorities.contains(priority)) return 'Select a valid priority.';
    if (startDate != null && endDate != null && endDate!.isBefore(startDate!)) return 'End date cannot be before start date.';
    if (selectedUsers.isEmpty) return 'Select at least one employee.';
    return null;
  }

  Future<TaskModel?> create({required String subject, String? description, String? project}) async {
    final validation = validate(subject: subject);
    if (validation != null) { errorMessage = validation; _notify(); return null; }
    if (submitting) return null;
    submitting = true; errorMessage = null; _notify();
    try {
      return await _service.createTask(
        subject: subject, description: description, priority: priority,
        expectedStartDate: startDate, expectedEndDate: endDate,
        project: project, assignedUsers: selectedUsers.toList(), company: company,
      );
    } catch (error) { errorMessage = _cleanError(error); return null; }
    finally { submitting = false; _notify(); }
  }

  void _notify() { if (!_disposed) notifyListeners(); }
  @override
  void dispose() { _disposed = true; super.dispose(); }
}
String _cleanError(Object error) => error.toString().replaceFirst('Exception: ', '');
