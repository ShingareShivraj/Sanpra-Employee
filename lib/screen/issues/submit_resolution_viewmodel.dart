import 'package:flutter/foundation.dart';

import '../../model/issue_model.dart';
import '../../services/issue_service.dart';

class SubmitResolutionViewModel extends ChangeNotifier {
  SubmitResolutionViewModel(this.issueName, {IssueService? service})
      : _service = service ?? IssueService();

  final String issueName;
  final IssueService _service;
  IssueDetailsModel? _details;
  bool _loading = false;
  bool _submitting = false;
  String? _errorMessage;

  IssueDetailsModel? get details => _details;
  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get errorMessage => _errorMessage;
  bool get canSubmit => _details?.canSubmitResolution == true;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _details = await _service.getIssueDetails(issueName);
    } catch (error) {
      _errorMessage = _clean(error);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> resolve(String remarks) => _submit(() async {
        if (remarks.trim().isEmpty) {
          throw Exception('Resolution remark is required.');
        }
        await _service.submitResolution(
          issueName: issueName,
          remarks: remarks.trim(),
        );
      });

  Future<bool> unableToResolve(String remarks) => _submit(() async {
        if (remarks.trim().isEmpty) {
          throw Exception('Please explain why the issue cannot be resolved.');
        }
        await _service.submitUnresolvedRemark(
          issueName: issueName,
          remarks: remarks.trim(),
        );
      });

  Future<bool> _submit(Future<void> Function() action) async {
    if (_submitting) return false;
    _submitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (error) {
      _errorMessage = _clean(error);
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  String _clean(Object error) =>
      error.toString().replaceFirst('Exception: ', '').trim();
}
