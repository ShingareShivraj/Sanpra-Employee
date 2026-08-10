import 'package:flutter/foundation.dart';

import '../../model/issue_model.dart';
import '../../services/issue_service.dart';

enum IssueListScope { mine, assigned, company }

class IssueViewModel extends ChangeNotifier {
  IssueViewModel({IssueService? service}) : _service = service ?? IssueService();

  final IssueService _service;
  final List<IssueModel> _issues = [];
  IssueListScope _scope = IssueListScope.mine;
  String _status = 'Open';
  String _search = '';
  bool _loading = false;
  bool _loadingMore = false;
  String? _errorMessage;
  int _total = 0;
  bool _isManager = false;

  List<IssueModel> get issues => List.unmodifiable(_issues);
  IssueListScope get scope => _scope;
  String get status => _status;
  String get search => _search;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get errorMessage => _errorMessage;
  int get total => _total;
  bool get isManager => _isManager;
  bool get hasMore => _issues.length < _total;

  Future<void> initialize() async {
    try {
      final counts = await _service.getDashboardCounts();
      _isManager = counts.isIssueManager;
    } catch (_) {
      _isManager = false;
    }
    await load();
  }

  Future<void> setScope(IssueListScope value) async {
    if (_scope == value || (value == IssueListScope.company && !_isManager)) return;
    _scope = value;
    await load();
  }

  Future<void> setStatus(String value) async {
    if (_status == value) return;
    _status = value;
    await load();
  }

  Future<void> setSearch(String value) async {
    final normalized = value.trim();
    if (_search == normalized) return;
    _search = normalized;
    if (_scope == IssueListScope.company) await load();
  }

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _fetch(start: 0);
      _issues
        ..clear()
        ..addAll(result.items);
      _total = result.total;
    } catch (error) {
      _errorMessage = _cleanError(error);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_loading || _loadingMore || !hasMore) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final result = await _fetch(start: _issues.length);
      _issues.addAll(result.items);
      _total = result.total;
    } catch (error) {
      _errorMessage = _cleanError(error);
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<IssueListResult> _fetch({required int start}) {
    final statusFilter = _status == 'All' ? null : _status;
    switch (_scope) {
      case IssueListScope.mine:
        return _service.getMyIssues(status: statusFilter, start: start);
      case IssueListScope.assigned:
        return _service.getAssignedIssues(status: statusFilter, start: start);
      case IssueListScope.company:
        return _service.getCompanyIssues(
          status: statusFilter,
          search: _search.isEmpty ? null : _search,
          start: start,
        );
    }
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst('Exception: ', '').trim();
}
