import 'package:flutter/foundation.dart';

import '../../model/issue_model.dart';
import '../../services/issue_service.dart';

class AssignIssueViewModel extends ChangeNotifier {
  AssignIssueViewModel(this.issueName, {IssueService? service})
      : _service = service ?? IssueService();

  final String issueName;
  final IssueService _service;
  IssueDetailsModel? _details;
  List<CompanyEmployeeModel> _employees = [];
  bool _loading = false;
  bool _processing = false;
  String _search = '';
  String? _errorMessage;

  IssueDetailsModel? get details => _details;
  List<CompanyEmployeeModel> get employees {
    final query = _search.toLowerCase();
    final assignedIds = _details?.issue.assignees.map((e) => e.employeeId).toSet() ?? {};
    return _employees.where((employee) {
      if (assignedIds.contains(employee.name)) return false;
      if (query.isEmpty) return true;
      return employee.employeeName.toLowerCase().contains(query) ||
          employee.name.toLowerCase().contains(query) ||
          (employee.department?.toLowerCase().contains(query) ?? false) ||
          (employee.designation?.toLowerCase().contains(query) ?? false);
    }).toList(growable: false);
  }

  bool get loading => _loading;
  bool get processing => _processing;
  String get search => _search;
  String? get errorMessage => _errorMessage;
  bool get canManage => _details?.canManage == true;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _details = await _service.getIssueDetails(issueName);
      if (_details?.canManage != true) {
        throw Exception('Issue Manager permission is required.');
      }
      _employees = await _service.getCompanyEmployees();
    } catch (error) {
      _errorMessage = _clean(error);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setSearch(String value) {
    _search = value.trim();
    notifyListeners();
  }

  Future<bool> assign(List<String> employeeIds) => _run(() async {
        if (employeeIds.isEmpty) throw Exception('Select at least one employee.');
        await _service.assignIssue(issueName, employeeIds);
      });

  Future<bool> reassign({
    required String fromEmployee,
    required String toEmployee,
  }) =>
      _run(() async {
        if (fromEmployee.isEmpty || toEmployee.isEmpty) {
          throw Exception('Select both current and new employee.');
        }
        if (fromEmployee == toEmployee) {
          throw Exception('Select a different employee.');
        }
        await _service.reassignIssue(
          issueName: issueName,
          fromEmployee: fromEmployee,
          toEmployee: toEmployee,
        );
      });

  Future<bool> _run(Future<void> Function() action) async {
    if (_processing) return false;
    _processing = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      _details = await _service.getIssueDetails(issueName);
      _employees = await _service.getCompanyEmployees();
      return true;
    } catch (error) {
      _errorMessage = _clean(error);
      return false;
    } finally {
      _processing = false;
      notifyListeners();
    }
  }

  String _clean(Object error) =>
      error.toString().replaceFirst('Exception: ', '').trim();
}
