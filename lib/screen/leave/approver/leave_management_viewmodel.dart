import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../model/leaves/leave_application_model.dart';
import '../../../model/leaves/leave_summary_model.dart';
import '../../../services/leave_service.dart';

class LeaveManagementViewModel extends ChangeNotifier {
  LeaveManagementViewModel({LeaveService? service})
      : _service = service ?? LeaveService();

  final LeaveService _service;
  static const int pageLength = 20;

  LeaveAccessModel? access;
  LeaveManagementSummaryModel? summary;
  final List<LeaveApplicationModel> applications = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = false;
  String search = '';
  String? error;
  int _nextStart = 0;
  Timer? _searchTimer;
  bool _disposed = false;

  bool get isApprover => access?.isLeaveApprover == true;
  String get company => summary?.company ?? access?.company ?? '';
  int get pendingCount => summary?.counts.open ?? applications.length;

  Future<void> initialize() async {
    if (isLoading) return;
    isLoading = true;
    error = null;
    _notify();
    try {
      access = await _service.getLeaveAccess();
      if (!isApprover) {
        applications.clear();
        summary = null;
        hasMore = false;
        return;
      }
      await Future.wait([_loadSummary(), _loadFirstPage()]);
    } catch (e) {
      error = _cleanError(e);
    } finally {
      isLoading = false;
      _notify();
    }
  }

  Future<void> refresh() async {
    if (!isApprover && access != null) return initialize();
    error = null;
    _notify();
    try {
      await Future.wait([_loadSummary(), _loadFirstPage()]);
    } catch (e) {
      error = _cleanError(e);
      _notify();
    }
  }

  void updateSearch(String value) {
    search = value.trim();
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 450), () async {
      try {
        await _loadFirstPage(showLoader: true);
      } catch (e) {
        error = _cleanError(e);
        _notify();
      }
    });
  }

  Future<void> clearSearch() async {
    if (search.isEmpty) return;
    search = '';
    _searchTimer?.cancel();
    await _loadFirstPage(showLoader: true);
  }

  Future<void> loadMore() async {
    if (!hasMore || isLoading || isLoadingMore || !isApprover) return;
    isLoadingMore = true;
    _notify();
    try {
      final page = await _service.getPendingLeaveApplications(
        search: search,
        start: _nextStart,
        pageLength: pageLength,
      );
      final known = applications.map((e) => e.name).toSet();
      applications.addAll(page.applications.where((e) => !known.contains(e.name)));
      _nextStart = page.limitStart + page.applications.length;
      hasMore = page.hasMore;
    } catch (e) {
      error = _cleanError(e);
    } finally {
      isLoadingMore = false;
      _notify();
    }
  }

  Future<void> _loadSummary() async {
    summary = await _service.getLeaveManagementSummary();
  }

  Future<void> _loadFirstPage({bool showLoader = false}) async {
    if (showLoader) {
      isLoading = true;
      error = null;
      _notify();
    }
    try {
      final page = await _service.getPendingLeaveApplications(
        search: search,
        start: 0,
        pageLength: pageLength,
      );
      applications
        ..clear()
        ..addAll(page.applications);
      _nextStart = page.limitStart + page.applications.length;
      hasMore = page.hasMore;
    } finally {
      if (showLoader) {
        isLoading = false;
        _notify();
      }
    }
  }

  String _cleanError(Object e) =>
      e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

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
