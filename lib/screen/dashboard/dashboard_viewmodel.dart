import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../model/attendance_responce.dart';
import '../../model/attendance_status_model.dart';
import '../../services/attendance_service.dart';
import '../../services/location_service.dart';
import '../../services/login_service.dart';
import '../../services/task_service.dart';
import '../../model/task_model.dart';

class DashboardViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final AttendanceService _attendanceService = AttendanceService();
  final LocationService _locationService = LocationService();
  final TaskService _taskService = TaskService();

  String attendanceStatus = "Not Checked In";
  String checkInTime = "";

  bool _attendanceLoading = false;
  bool get attendanceLoading => _attendanceLoading;

  bool _loading = true;
  bool get loading => _loading;

  String employeeName = "";
  String designation = "";
  String department = "";
  String company = "";
  String email = "";
  // ============================================================
// TASK PERMISSIONS
// ============================================================
  bool isChatManager = false;
  bool isTaskManager = false;

  bool canCreateTask = false;

  bool canAssignTask = false;

  bool canReviewTask = false;
  bool isIssueManager = false;

  // Dashboard tasks from get_dashboard_tasks API
  int todayTaskCount = 0;
  List<TaskModel> todayTasks = [];



  Future<void> loadDashboardTasks() async {
    try {
      final response = await _taskService.getDashboardTasks();

      todayTaskCount = response.taskCount;
      todayTasks = response.tasks;
    } catch (_) {
      todayTaskCount = 0;
      todayTasks = [];
    }

    notifyListeners();
  }

  Future<void> loadAttendanceStatus() async {
    try {
      final AttendanceStatusModel response =
      await _attendanceService.attendanceStatus();

      attendanceStatus = response.status;

      if (response.checkInTime.isNotEmpty) {
        final DateTime date = DateTime.parse(response.checkInTime);

        checkInTime = DateFormat("hh:mm a").format(date);
      } else {
        checkInTime = "";
      }

      notifyListeners();
    } catch (_) {
      // Keep the existing/default attendance status.
    }
  }

  Future<void> loadData() async {
    _loading = true;
    notifyListeners();

    try {
      employeeName = await _authService.getEmployeeName() ?? "";
      designation = await _authService.getDesignation() ?? "";
      department = await _authService.getDepartment() ?? "";
      company = await _authService.getCompany() ?? "";
      email = await _authService.getEmail() ?? "";
      // ============================================================
// TASK PERMISSIONS
// ============================================================
      isChatManager =
      await _authService.hasRole("Chat Manager");

      isTaskManager =
      await _authService.getIsTaskManager();

      canCreateTask =
      await _authService.getCanCreateTask();

      canAssignTask =
      await _authService.getCanAssignTask();

      canReviewTask =
      await _authService.getCanReviewTask();


      isIssueManager =
      await _authService.hasRole("Issue Manager");

      await Future.wait([
        loadAttendanceStatus(),
        loadDashboardTasks(),
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

      final Position position =
      await _locationService.getCurrentLocation();

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

      final Position position =
      await _locationService.getCurrentLocation();

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