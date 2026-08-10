import 'package:flutter/foundation.dart';

import '../../model/issue_model.dart';
import '../../services/issue_service.dart';

class IssueDetailsViewModel extends ChangeNotifier {
  IssueDetailsViewModel(this.issueName, {IssueService? service})
      : _service = service ?? IssueService();

  final String issueName;
  final IssueService _service;
  IssueDetailsModel? _details;
  List<CompanyEmployeeModel> _employees = [];
  bool _loading = false;
  bool _processing = false;
  String? _errorMessage;

  IssueDetailsModel? get details => _details;
  List<CompanyEmployeeModel> get employees => List.unmodifiable(_employees);
  bool get loading => _loading;
  bool get processing => _processing;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _details = await _service.getIssueDetails(issueName);
    } catch (error) {
      _errorMessage = _cleanError(error);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadEmployees({String? search}) async {
    if (_details?.canManage != true) return;
    try {
      _employees = await _service.getCompanyEmployees(search: search);
      notifyListeners();
    } catch (error) {
      _errorMessage = _cleanError(error);
      notifyListeners();
    }
  }

  Future<bool> submitResolution(String remarks) => _run(() async {
        if (remarks.trim().isEmpty) throw Exception('Resolution remark is required.');
        await _service.submitResolution(issueName: issueName, remarks: remarks.trim());
      });

  Future<bool> submitUnableRemark(String remarks) => _run(() async {
        if (remarks.trim().isEmpty) throw Exception('Please explain why it cannot be resolved.');
        await _service.submitUnresolvedRemark(issueName: issueName, remarks: remarks.trim());
      });

  Future<bool> addManagerRemark(String remarks) => _run(() async {
        if (remarks.trim().isEmpty) throw Exception('Remark is required.');
        await _service.addRemark(issueName, remarks.trim());
      });

  Future<bool> updateStatus(String status, {String? remarks}) => _run(() =>
      _service.updateStatus(issueName, status, remarks: remarks?.trim()));

  Future<bool> resolveAsManager(String remarks) => _run(() async {
        if (remarks.trim().isEmpty) throw Exception('Resolution remark is required.');
        await _service.resolveIssue(issueName, remarks.trim());
      });

  Future<bool> closeIssue({String? remarks}) =>
      _run(() => _service.closeIssue(issueName, remarks: remarks?.trim()));

  Future<bool> assignEmployees(List<String> ids) => _run(() async {
        if (ids.isEmpty) throw Exception('Select at least one employee.');
        await _service.assignIssue(issueName, ids);
      });

  Future<bool> reassign({required String fromId, required String toId}) => _run(() =>
      _service.reassignIssue(issueName: issueName, fromEmployee: fromId, toEmployee: toId));

  Future<bool> _run(Future<void> Function() action) async {
    if (_processing) return false;
    _processing = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      _details = await _service.getIssueDetails(issueName);
      return true;
    } catch (error) {
      _errorMessage = _cleanError(error);
      return false;
    } finally {
      _processing = false;
      notifyListeners();
    }
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst('Exception: ', '').trim();
}
