import 'package:flutter/foundation.dart';

import '../../../model/leaves/leave_application_model.dart';
import '../../../model/leaves/leave_type_model.dart';
import '../../../services/leave_service.dart';

class ApplyLeaveViewModel extends ChangeNotifier {
  ApplyLeaveViewModel({LeaveService? service}) : _service = service ?? LeaveService();
  final LeaveService _service;

  List<LeaveTypeModel> leaveTypes = [];
  LeaveTypeModel? selectedLeaveType;
  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();
  bool isHalfDay = false;
  DateTime? halfDayDate;
  bool isLoading = false;
  bool isSubmitting = false;
  String? error;
  bool _disposed = false;

  double get requestedDays {
    final days = toDate.difference(_day(fromDate)).inDays + 1;
    return (days < 1 ? 1 : days).toDouble() - (isHalfDay ? .5 : 0);
  }

  Future<void> initialize() async {
    isLoading = true; error = null; _notify();
    try {
      final result = await _service.getMyLeaveTypes(onDate: fromDate);
      leaveTypes = result.leaveTypes;
      if (leaveTypes.isNotEmpty) selectedLeaveType = leaveTypes.first;
    } catch (e) { error = _cleanError(e); }
    finally { isLoading = false; _notify(); }
  }

  void selectLeaveType(LeaveTypeModel? value) {
    selectedLeaveType = value; error = null; _notify();
  }

  void setDateRange(DateTime from, DateTime to) {
    fromDate = _day(from);
    toDate = _day(to.isBefore(from) ? from : to);
    if (halfDayDate != null &&
        (halfDayDate!.isBefore(fromDate) || halfDayDate!.isAfter(toDate))) {
      halfDayDate = fromDate;
    }
    _notify();
  }

  void setHalfDay(bool value) {
    isHalfDay = value;
    halfDayDate = value ? (halfDayDate ?? fromDate) : null;
    _notify();
  }

  void setHalfDayDate(DateTime value) { halfDayDate = _day(value); _notify(); }

  Future<LeaveApplicationModel?> submit(String reason) async {
    if (isSubmitting) return null;
    if (selectedLeaveType == null) { error = 'Please select a leave type.'; _notify(); return null; }
    if (reason.trim().isEmpty) { error = 'Please enter the reason for leave.'; _notify(); return null; }
    if (isHalfDay && halfDayDate == null) { error = 'Please select the half-day date.'; _notify(); return null; }
    isSubmitting = true; error = null; _notify();
    try {
      return await _service.applyLeave(
        leaveType: selectedLeaveType!.leaveType,
        fromDate: fromDate,
        toDate: toDate,
        reason: reason,
        halfDay: isHalfDay,
        halfDayDate: halfDayDate,
      );
    } catch (e) { error = _cleanError(e); return null; }
    finally { isSubmitting = false; _notify(); }
  }

  DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
  String _cleanError(Object e) => e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  void _notify() { if (!_disposed) notifyListeners(); }
  @override void dispose() { _disposed = true; super.dispose(); }
}
