import 'package:flutter/foundation.dart';

import '../../model/issue_model.dart';
import '../../services/issue_service.dart';

class CompanyIssuesViewModel extends ChangeNotifier {
  CompanyIssuesViewModel({IssueService? service})
      : _service = service ?? IssueService();

  final IssueService _service;
  final List<IssueModel> _issues = [];
  List<String> _issueTypes = [];
  String _status = 'Open';
  String _priority = 'All';
  String? _issueType;
  String _search = '';
  int _total = 0;
  bool _loading = false;
  bool _loadingMore = false;
  bool _isManager = false;
  String? _errorMessage;

  List<IssueModel> get issues => List.unmodifiable(_issues);
  List<String> get issueTypes => List.unmodifiable(_issueTypes);
  String get status => _status;
  String get priority => _priority;
  String? get issueType => _issueType;
  String get search => _search;
  int get total => _total;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get isManager => _isManager;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _issues.length < _total;
  bool get hasFilters => _status != 'All' || _priority != 'All' ||
      _issueType != null || _search.isNotEmpty;

  Future<void> initialize() async {
    _loading = true;
    notifyListeners();
    try {
      final counts = await _service.getDashboardCounts();
      _isManager = counts.isIssueManager;
      if (!_isManager) throw Exception('Issue Manager permission is required.');
      _issueTypes = await _service.getIssueTypes();
      await _fetch(reset: true, notify: false);
    } catch (error) {
      _errorMessage = _clean(error);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> load() => _fetch(reset: true);

  Future<void> loadMore() async {
    if (_loading || _loadingMore || !hasMore || !_isManager) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final result = await _request(_issues.length);
      _issues.addAll(result.items);
      _total = result.total;
    } catch (error) {
      _errorMessage = _clean(error);
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> setStatus(String value) async {
    if (_status == value) return;
    _status = value;
    await load();
  }

  Future<void> setPriority(String value) async {
    if (_priority == value) return;
    _priority = value;
    await load();
  }

  Future<void> setIssueType(String? value) async {
    final normalized = value?.trim().isEmpty == true ? null : value;
    if (_issueType == normalized) return;
    _issueType = normalized;
    await load();
  }

  Future<void> setSearch(String value) async {
    final normalized = value.trim();
    if (_search == normalized) return;
    _search = normalized;
    await load();
  }

  Future<void> clearFilters() async {
    _status = 'All';
    _priority = 'All';
    _issueType = null;
    _search = '';
    await load();
  }

  Future<void> _fetch({required bool reset, bool notify = true}) async {
    if (!_isManager) return;
    if (notify) {
      _loading = true;
      _errorMessage = null;
      notifyListeners();
    }
    try {
      final result = await _request(0);
      if (reset) _issues.clear();
      _issues.addAll(result.items);
      _total = result.total;
    } catch (error) {
      _errorMessage = _clean(error);
    } finally {
      if (notify) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<IssueListResult> _request(int start) => _service.getCompanyIssues(
        status: _status == 'All' ? null : _status,
        priority: _priority == 'All' ? null : _priority,
        issueType: _issueType,
        search: _search.isEmpty ? null : _search,
        start: start,
      );

  String _clean(Object error) =>
      error.toString().replaceFirst('Exception: ', '').trim();
}
