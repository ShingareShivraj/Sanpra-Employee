import 'package:flutter/foundation.dart';

import '../../model/attendance_calendar_model.dart';
import '../../services/attendance_calendar_service.dart';

class AttendanceViewModel extends ChangeNotifier {
  final AttendanceService _attendanceService;

  AttendanceViewModel({
    AttendanceService? attendanceService,
  }) : _attendanceService =
      attendanceService ?? AttendanceService();

  // ============================================================
  // State
  // ============================================================

  AttendanceCalendarModel? _attendanceData;

  bool _isLoading = false;

  String? _errorMessage;

  // ============================================================
  // Getters
  // ============================================================

  AttendanceCalendarModel? get attendanceData =>
      _attendanceData;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get hasData => _attendanceData != null;

  // ============================================================
  // Load Attendance
  // ============================================================

  Future<void> loadAttendance({
    required String fromDate,
    required String toDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final data =
      await _attendanceService.getAttendanceCalendar(
        fromDate: fromDate,
        toDate: toDate,
      );

      _attendanceData = data;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // ============================================================
  // Refresh Attendance
  // ============================================================

  Future<void> refreshAttendance({
    required String fromDate,
    required String toDate,
  }) async {
    await loadAttendance(
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  // ============================================================
  // Clear Error
  // ============================================================

  void clearError() {
    _errorMessage = null;

    notifyListeners();
  }

  // ============================================================
  // Clear Data
  // ============================================================

  void clearData() {
    _attendanceData = null;
    _errorMessage = null;

    notifyListeners();
  }

  // ============================================================
  // Calendar Status
  // ============================================================

  String? getStatusForDate(String date) {
    return _attendanceData?.getCalendarStatus(date);
  }

  // ============================================================
  // Attendance Status
  // ============================================================

  String? getAttendanceStatusForDate(String date) {
    return _attendanceData?.getAttendanceStatus(date);
  }

  // ============================================================
  // Holiday
  // ============================================================

  String? getHolidayNameForDate(String date) {
    return _attendanceData?.getHolidayName(date);
  }

  bool isHoliday(String date) {
    return _attendanceData?.isHoliday(date) ?? false;
  }

  // ============================================================
  // Summary
  // ============================================================

  int get presentCount =>
      _attendanceData?.presentCount ?? 0;

  int get absentCount =>
      _attendanceData?.absentCount ?? 0;

  int get halfDayCount =>
      _attendanceData?.halfDayCount ?? 0;

  int get onLeaveCount =>
      _attendanceData?.onLeaveCount ?? 0;

  int get holidayCount =>
      _attendanceData?.holidayCount ?? 0;

  // ============================================================
  // Employee / Company
  // ============================================================

  String get employee =>
      _attendanceData?.employee ?? '';

  String get company =>
      _attendanceData?.company ?? '';

  String get financialYear =>
      _attendanceData?.financialYear ?? '';

  // ============================================================
  // Error Handling
  // ============================================================

  String _cleanErrorMessage(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(
        'Exception: '.length,
      );
    }

    return message;
  }
}