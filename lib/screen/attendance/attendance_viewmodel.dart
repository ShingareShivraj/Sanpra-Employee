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
  ShiftInfoModel? _shiftData;

  bool _isLoading = false;
  bool _isShiftLoading = false;

  String? _errorMessage;
  String? _shiftErrorMessage;

  // ============================================================
  // Getters
  // ============================================================

  AttendanceCalendarModel? get attendanceData =>
      _attendanceData;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get hasData => _attendanceData != null;

  ShiftInfoModel? get shiftData => _shiftData;

  bool get isShiftLoading => _isShiftLoading;

  String? get shiftErrorMessage => _shiftErrorMessage;

  bool get hasShiftData =>
      _shiftData?.shift != null;

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

  Future<void> loadShiftInfo() async {
    _isShiftLoading = true;
    _shiftErrorMessage = null;

    notifyListeners();

    try {
      _shiftData = await _attendanceService.getMyShiftInfo();
    } catch (e) {
      _shiftErrorMessage = _cleanErrorMessage(e);
    } finally {
      _isShiftLoading = false;
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

  Future<void> refreshShiftInfo() async {
    await loadShiftInfo();
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
    _shiftData = null;
    _errorMessage = null;
    _shiftErrorMessage = null;

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

  AttendanceDetail? getAttendanceDetailForDate(String date) {
    return _attendanceData?.getAttendanceDetail(date);
  }
  bool isLateMarkForDate(String date) {
    return _attendanceData
        ?.getAttendanceDetail(date)
        ?.lateEntry ??
        false;
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