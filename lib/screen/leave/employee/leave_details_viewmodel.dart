import 'package:flutter/foundation.dart';

import '../../../model/leaves/leave_application_model.dart';
import '../../../services/leave_service.dart';

class LeaveDetailsViewModel extends ChangeNotifier {
  LeaveDetailsViewModel(this.applicationName, {LeaveService? service})
      : _service = service ?? LeaveService();
  final String applicationName;
  final LeaveService _service;
  LeaveApplicationModel? application;
  bool isLoading = false;
  bool isCancelling = false;
  String? error;
  bool _disposed = false;

  Future<void> load() async {
    isLoading = true; error = null; _notify();
    try { application = await _service.getLeaveApplication(applicationName); }
    catch (e) { error = _cleanError(e); }
    finally { isLoading = false; _notify(); }
  }

  Future<bool> cancel() async {
    if (isCancelling || application?.canCancel != true) return false;
    isCancelling = true; error = null; _notify();
    try { application = await _service.cancelLeaveApplication(applicationName); return true; }
    catch (e) { error = _cleanError(e); return false; }
    finally { isCancelling = false; _notify(); }
  }

  String _cleanError(Object e) => e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  void _notify() { if (!_disposed) notifyListeners(); }
  @override void dispose() { _disposed = true; super.dispose(); }
}
