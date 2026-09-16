import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../model/knowledge_hub/knowledge_resource_model.dart';
import '../../model/knowledge_hub/knowledge_resource_type.dart';
import '../../services/knowledge_hub_service.dart';

class KnowledgeHubViewModel extends ChangeNotifier {
  final KnowledgeHubService _service;
  final String? _detailResourceName;

  KnowledgeHubViewModel({KnowledgeHubService? service})
      : _service = service ?? KnowledgeHubService(),
        _detailResourceName = null;

  KnowledgeHubViewModel.detail({
    required String resourceName,
    KnowledgeHubService? service,
  })  : _service = service ?? KnowledgeHubService(),
        _detailResourceName = resourceName;

  final List<KnowledgeResourceModel> _resources = [];
  KnowledgeAccessModel? _access;
  KnowledgeResourceModel? _detail;
  KnowledgeResourceType? _selectedType;
  KnowledgeResourceStatus? _selectedStatus;
  Timer? _searchTimer;
  String _search = '';
  bool _mineOnly = false;
  bool _initialLoading = false;
  bool _contentLoading = false;
  bool _loadingMore = false;
  bool _refreshing = false;
  bool _detailLoading = false;
  bool _actionLoading = false;
  String? _error;
  int _total = 0;
  bool _hasMore = false;
  int _requestGeneration = 0;

  List<KnowledgeResourceModel> get resources => List.unmodifiable(_resources);
  KnowledgeAccessModel? get access => _access;
  KnowledgeResourceModel? get detail => _detail;
  KnowledgeResourceType? get selectedType => _selectedType;
  KnowledgeResourceStatus? get selectedStatus => _selectedStatus;
  bool get mineOnly => _mineOnly;
  bool get initialLoading => _initialLoading;
  bool get contentLoading => _contentLoading;
  bool get loadingMore => _loadingMore;
  bool get refreshing => _refreshing;
  bool get detailLoading => _detailLoading;
  bool get actionLoading => _actionLoading;
  String? get error => _error;
  int get total => _total;
  bool get hasMore => _hasMore;
  bool get isKnowledgeManager => _access?.isKnowledgeManager ?? false;
  bool get isDetailMode => _detailResourceName != null;

  Future<void> initialise() async {
    if (_initialLoading || isDetailMode) return;
    _initialLoading = true;
    _error = null;
    notifyListeners();
    try {
      _access = await _service.getAccess();
      await _fetchResources(reset: true);
    } catch (error) {
      _error = _message(error);
    } finally {
      _initialLoading = false;
      notifyListeners();
    }
  }

  Future<void> initialiseDetail() async {
    if (!isDetailMode || _detailLoading) return;
    _detailLoading = true;
    _error = null;
    notifyListeners();
    try {
      _detail = await _service.getResource(_detailResourceName!);
    } catch (error) {
      _error = _message(error);
    } finally {
      _detailLoading = false;
      notifyListeners();
    }
  }

  void searchResources(String value) {
    _search = value.trim();
    _searchTimer?.cancel();
    _searchTimer = Timer(
      const Duration(milliseconds: 400),
      () => loadResources(reset: true),
    );
  }

  Future<void> setType(KnowledgeResourceType? value) async {
    if (_selectedType == value) return;
    _selectedType = value;
    notifyListeners();
    await loadResources(reset: true);
  }

  Future<void> setStatus(KnowledgeResourceStatus? value) async {
    if (_selectedStatus == value) return;
    _selectedStatus = value;
    notifyListeners();
    await loadResources(reset: true);
  }

  Future<void> setMineOnly(bool value) async {
    if (_mineOnly == value) return;
    _mineOnly = value;
    notifyListeners();
    await loadResources(reset: true);
  }

  Future<void> clearFilters() async {
    if (_selectedType == null && _selectedStatus == null && !_mineOnly) return;
    _selectedType = null;
    _selectedStatus = null;
    _mineOnly = false;
    notifyListeners();
    await loadResources(reset: true);
  }

  Future<void> loadResources({required bool reset}) async {
    if (isDetailMode ||
        (reset && _contentLoading) ||
        (!reset && (_loadingMore || !_hasMore))) return;
    if (reset) {
      _contentLoading = true;
      _error = null;
    } else {
      _loadingMore = true;
    }
    notifyListeners();
    try {
      await _fetchResources(reset: reset);
    } catch (error) {
      _error = _message(error);
    } finally {
      _contentLoading = false;
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> _fetchResources({required bool reset}) async {
    final generation = reset ? ++_requestGeneration : _requestGeneration;
    final response = await _service.getResources(
      search: _search,
      resourceType: _selectedType,
      status: _selectedStatus,
      mineOnly: _mineOnly,
      start: reset ? 0 : _resources.length,
    );
    if (generation != _requestGeneration) return;
    if (reset) _resources.clear();
    final names = _resources.map((resource) => resource.name).toSet();
    _resources.addAll(
      response.resources.where((resource) => names.add(resource.name)),
    );
    _total = response.pagination.total;
    _hasMore = response.pagination.hasMore;
  }

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    _error = null;
    notifyListeners();
    try {
      if (isDetailMode) {
        _detail = await _service.getResource(_detailResourceName!);
      } else {
        await _fetchResources(reset: true);
      }
    } catch (error) {
      _error = _message(error);
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  Future<bool> publishDetail() => _runDetailAction(
        () => _service.publishResource(_detailResourceName!),
      );

  Future<bool> rejectDetail() => _runDetailAction(
        () => _service.rejectResource(_detailResourceName!),
      );

  Future<bool> submitDetailForReview() => _runDetailAction(
        () => _service.submitForReview(_detailResourceName!),
      );

  Future<bool> deleteDetail() async {
    if (!isDetailMode || _actionLoading) return false;
    _actionLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteResource(_detailResourceName!);
      return true;
    } catch (error) {
      _error = _message(error);
      return false;
    } finally {
      _actionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _runDetailAction(
    Future<KnowledgeResourceModel> Function() action,
  ) async {
    if (!isDetailMode || _actionLoading) return false;
    _actionLoading = true;
    _error = null;
    notifyListeners();
    try {
      _detail = await action();
      return true;
    } catch (error) {
      _error = _message(error);
      return false;
    } finally {
      _actionLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  String _message(Object error) =>
      error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}
