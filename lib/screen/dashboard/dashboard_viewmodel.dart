import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../model/attendance_status_model.dart';
import '../../model/task_model.dart';
import '../../services/attendance_service.dart';
import '../../services/location_service.dart';
import '../../services/login_service.dart';
import '../../services/task_service.dart';
import '../../model/my_work_model.dart';
import '../../services/my_work_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final AttendanceService _attendanceService = AttendanceService();
  final LocationService _locationService = LocationService();
  final MyWorkService _myWorkService = MyWorkService();

  String attendanceStatus = 'Not Checked In';

  String checkInTime = '';
  String checkOutTime = '';

  DateTime? checkInDateTime;
  DateTime? checkOutDateTime;
  bool _attendanceLoading = false;
  bool get attendanceLoading => _attendanceLoading;

  bool _loading = true;
  bool get loading => _loading;

  String employeeName = '';
  String designation = '';
  String department = '';
  String company = '';
  String email = '';

  bool isChatManager = false;
  bool isTaskManager = false;
  bool canCreateTask = false;
  bool canAssignTask = false;
  bool canReviewTask = false;
  bool isIssueManager = false;

  int dashboardWorkCount = 0;
  MyWorkCountsModel workCounts = const MyWorkCountsModel();
  List<MyWorkItemModel> dashboardWork = [];

  Future<void> loadDashboardWork() async {
    try {
      final response = await _myWorkService.getDashboardWork(limit: 5);

      dashboardWorkCount = response.workCount;
      workCounts = response.counts;
      dashboardWork = response.work;
    } catch (_) {
      dashboardWorkCount = 0;
      workCounts = const MyWorkCountsModel();
      dashboardWork = [];
    }

    notifyListeners();
  }

  Future<void> loadAttendanceStatus() async {
    try {
      final AttendanceStatusModel response =
      await _attendanceService.attendanceStatus();

      attendanceStatus = response.status;

      // Keep the original DateTime from the API.
      if (response.checkInTime.isNotEmpty) {
        checkInDateTime = DateTime.parse(response.checkInTime);

        // Keep formatted time for displaying in the UI.
        checkInTime = DateFormat('hh:mm a').format(checkInDateTime!);
      } else {
        checkInDateTime = null;
        checkInTime = '';
      }

      // Keep the original checkout DateTime from the API.
      if (response.checkOutTime.isNotEmpty) {
        checkOutDateTime = DateTime.parse(response.checkOutTime);

        // Keep formatted time for displaying in the UI.
        checkOutTime =
            DateFormat('hh:mm a').format(checkOutDateTime!);
      } else {
        checkOutDateTime = null;
        checkOutTime = '';
      }

      notifyListeners();
    } catch (_) {
      // Keep the last known/default attendance state.
    }
  }

  Future<void> loadData() async {
    _loading = true;
    notifyListeners();

    try {
      employeeName = await _authService.getEmployeeName() ?? '';
      designation = await _authService.getDesignation() ?? '';
      department = await _authService.getDepartment() ?? '';
      company = await _authService.getCompany() ?? '';
      email = await _authService.getEmail() ?? '';
      isChatManager = await _authService.hasRole('Chat Manager');
      isTaskManager = await _authService.getIsTaskManager();
      canCreateTask = await _authService.getCanCreateTask();
      canAssignTask = await _authService.getCanAssignTask();
      canReviewTask = await _authService.getCanReviewTask();
      isIssueManager = await _authService.hasRole('Issue Manager');

      await Future.wait([
        loadAttendanceStatus(),
        loadDashboardWork(),
      ]);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> checkIn() async {
    try {
      _attendanceLoading = true;
      notifyListeners();
      final Position position = await _locationService.getCurrentLocation();
      await _attendanceService.checkIn(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      await loadAttendanceStatus();
    } catch (_) {
      rethrow;
    } finally {
      _attendanceLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkOut() async {
    try {
      _attendanceLoading = true;
      notifyListeners();
      final Position position = await _locationService.getCurrentLocation();
      await _attendanceService.checkOut(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      await loadAttendanceStatus();
    } catch (_) {
      rethrow;
    } finally {
      _attendanceLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
  }
}
