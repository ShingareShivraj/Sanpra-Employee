import 'package:flutter/foundation.dart';

import '../../model/issue_model.dart';
import '../../services/issue_service.dart';

class RaiseIssueViewModel extends ChangeNotifier {
  RaiseIssueViewModel({IssueService? service}) : _service = service ?? IssueService();
  final IssueService _service;

  List<String> _issueTypes = [];
  bool _loadingTypes = false;
  bool _submitting = false;
  String? _errorMessage;

  List<String> get issueTypes => List.unmodifiable(_issueTypes);
  bool get loadingTypes => _loadingTypes;
  bool get submitting => _submitting;
  String? get errorMessage => _errorMessage;

  Future<void> loadIssueTypes() async {
    _loadingTypes = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _issueTypes = await _service.getIssueTypes();
    } catch (error) {
      _errorMessage = _cleanError(error);
    } finally {
      _loadingTypes = false;
      notifyListeners();
    }
  }

  Future<IssueModel?> submit({
    required String subject,
    required String description,
    required String priority,
    String? issueType,
  }) async {
    if (subject.trim().length < 3) {
      _errorMessage = 'Enter a clear subject with at least 3 characters.';
      notifyListeners();
      return null;
    }
    if (description.trim().length < 5) {
      _errorMessage = 'Describe the issue with at least 5 characters.';
      notifyListeners();
      return null;
    }
    _submitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await _service.createIssue(
        subject: subject.trim(),
        description: description.trim(),
        priority: priority,
        issueType: issueType?.trim().isEmpty == true ? null : issueType,
      );
    } catch (error) {
      _errorMessage = _cleanError(error);
      return null;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst('Exception: ', '').trim();
}
