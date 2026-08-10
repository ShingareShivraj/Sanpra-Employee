import 'package:flutter/foundation.dart';

import '../../../model/leaves/leave_application_model.dart';
import '../../../model/leaves/leave_summary_model.dart';
import '../../../services/leave_service.dart';

class LeaveViewModel extends ChangeNotifier {
  LeaveViewModel({LeaveService? service}) : _service = service ?? LeaveService();

  final LeaveService _service;
  static const int _pageSize = 15;

  LeaveSummaryModel? summary;
  final List<LeaveApplicationModel> applications = [];
  String selectedStatus = 'All';
  String? error;
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = false;
  bool _disposed = false;

  static const statuses = ['All', 'Open', 'Approved', 'Rejected', 'Cancelled'];

  Future<void> initialize() => refresh();

  Future<void> refresh() async {
    if (isLoading) return;
    isLoading = true;
    error = null;
    _notify();
    try {
      final results = await Future.wait([
        _service.getMyLeaveSummary(recentLimit: 5),
        _service.getMyLeaveApplications(
          status: selectedStatus,
          start: 0,
          pageLength: _pageSize,
        ),
      ]);
      summary = results[0] as LeaveSummaryModel;
      final page = results[1] as LeaveApplicationListModel;
      applications
        ..clear()
        ..addAll(page.applications);
      hasMore = page.hasMore;
    } catch (e) {
      error = _cleanError(e);
    } finally {
      isLoading = false;
      _notify();
    }
  }

  Future<void> changeStatus(String status) async {
    if (status == selectedStatus) return;
    selectedStatus = status;
    await refresh();
  }

  Future<void> loadMore() async {
    if (!hasMore || isLoading || isLoadingMore) return;
    isLoadingMore = true;
    _notify();
    try {
      final page = await _service.getMyLeaveApplications(
        status: selectedStatus,
        start: applications.length,
        pageLength: _pageSize,
      );
      final known = applications.map((e) => e.name).toSet();
      applications.addAll(page.applications.where((e) => !known.contains(e.name)));
      hasMore = page.hasMore;
    } catch (e) {
      error = _cleanError(e);
    } finally {
      isLoadingMore = false;
      _notify();
    }
  }

  int countFor(String status) {
    final counts = summary?.counts;
    if (counts == null) return 0;
    switch (status) {
      case 'Open': return counts.open;
      case 'Approved': return counts.approved;
      case 'Rejected': return counts.rejected;
      case 'Cancelled': return counts.cancelled;
      default: return counts.total;
    }
  }

  String _cleanError(Object value) =>
      value.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

  void _notify() { if (!_disposed) notifyListeners(); }

  @override
  void dispose() { _disposed = true; super.dispose(); }
}
