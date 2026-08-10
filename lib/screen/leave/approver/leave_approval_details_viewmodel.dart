import 'package:flutter/foundation.dart';

import '../../../model/leaves/leave_application_model.dart';
import '../../../services/leave_service.dart';

class LeaveApprovalDetailsViewModel extends ChangeNotifier {
  LeaveApprovalDetailsViewModel(this.applicationName, {LeaveService? service})
      : _service = service ?? LeaveService();

  final String applicationName;
  final LeaveService _service;
  LeaveApplicationModel? application;
  bool isLoading = false;
  bool isApproving = false;
  bool isRejecting = false;
  String? error;
  bool _disposed = false;

  bool get isProcessing => isApproving || isRejecting;
  bool get canApprove => application?.canApprove == true && !isProcessing;
  bool get canReject => application?.canReject == true && !isProcessing;

  Future<void> load() async {
    if (isLoading) return;
    isLoading = true;
    error = null;
    _notify();
    try {
      application = await _service.getLeaveApprovalDetails(applicationName);
    } catch (e) {
      error = _cleanError(e);
    } finally {
      isLoading = false;
      _notify();
    }
  }

  Future<bool> approve({String? remark}) async {
    if (!canApprove) return false;
    isApproving = true;
    error = null;
    _notify();
    try {
      application = await _service.approveLeaveApplication(
        applicationName,
        remark: remark,
      );
      return true;
    } catch (e) {
      error = _cleanError(e);
      return false;
    } finally {
      isApproving = false;
      _notify();
    }
  }

  Future<bool> reject(String reason) async {
    final value = reason.trim();
    if (!canReject) return false;
    if (value.isEmpty) {
      error = 'Rejection reason is required.';
      _notify();
      return false;
    }
    isRejecting = true;
    error = null;
    _notify();
    try {
      application = await _service.rejectLeaveApplication(
        applicationName,
        reason: value,
      );
      return true;
    } catch (e) {
      error = _cleanError(e);
      return false;
    } finally {
      isRejecting = false;
      _notify();
    }
  }

  void clearError() {
    error = null;
    _notify();
  }

  String _cleanError(Object e) =>
      e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
