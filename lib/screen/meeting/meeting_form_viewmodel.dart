import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../model/meeting/meeting_action_item_model.dart';
import '../../model/meeting/meeting_model.dart';
import '../../services/meeting_service.dart';

class MeetingFormViewModel extends ChangeNotifier {
  final MeetingService _service;
  final MeetingModel? initialMeeting;

  MeetingFormViewModel({
    this.initialMeeting,
    MeetingService? service,
  }) : _service = service ?? MeetingService() {
    _selectedEmployeeIds.addAll(
      initialMeeting?.participants.map((item) => item.employee) ?? const [],
    );
  }

  final List<MeetingEmployeeModel> _employees = [];
  final Set<String> _selectedEmployeeIds = {};
  Timer? _searchTimer;
  bool _initialLoading = false;
  bool _employeesLoading = false;
  bool _saving = false;
  bool _hasMoreEmployees = false;
  String _employeeSearch = '';
  String? _error;

  List<MeetingEmployeeModel> get employees => List.unmodifiable(_employees);
  Set<String> get selectedEmployeeIds => Set.unmodifiable(_selectedEmployeeIds);
  bool get initialLoading => _initialLoading;
  bool get employeesLoading => _employeesLoading;
  bool get saving => _saving;
  bool get hasMoreEmployees => _hasMoreEmployees;
  String? get error => _error;
  bool get isEditing => initialMeeting != null;

  Future<void> initialise() async {
    if (_initialLoading) return;
    _initialLoading = true;
    _error = null;
    notifyListeners();
    try {
      final access = await _service.getAccess();
      if (!access.isMeetingManager) {
        throw const MeetingServiceException(
          'Only a Mobile Meeting Manager can manage meetings.',
        );
      }
      await _fetchEmployees(reset: true);
    } catch (error) {
      _error = _message(error);
    } finally {
      _initialLoading = false;
      notifyListeners();
    }
  }

  void searchEmployees(String value) {
    _employeeSearch = value.trim();
    _searchTimer?.cancel();
    _searchTimer = Timer(
      const Duration(milliseconds: 350),
      () => loadEmployees(reset: true),
    );
  }

  Future<void> loadEmployees({required bool reset}) async {
    if (_employeesLoading || (!reset && !_hasMoreEmployees)) return;
    _employeesLoading = true;
    if (reset) _error = null;
    notifyListeners();
    try {
      await _fetchEmployees(reset: reset);
    } catch (error) {
      _error = _message(error);
    } finally {
      _employeesLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchEmployees({required bool reset}) async {
    final response = await _service.getCompanyEmployees(
      search: _employeeSearch,
      start: reset ? 0 : _employees.length,
      pageLength: 50,
    );
    if (reset) _employees.clear();
    final names = _employees.map((employee) => employee.name).toSet();
    _employees.addAll(
      response.employees.where((employee) => names.add(employee.name)),
    );
    _hasMoreEmployees = response.hasMore;
  }

  void toggleEmployee(String employee) {
    if (!_selectedEmployeeIds.add(employee)) {
      _selectedEmployeeIds.remove(employee);
    }
    notifyListeners();
  }

  void removeEmployee(String employee) {
    if (_selectedEmployeeIds.remove(employee)) notifyListeners();
  }

  Future<bool> save({
    required String meetingTitle,
    required String description,
    required String meetingAgenda,
    required DateTime meetingDate,
    required DateTime startTime,
    required DateTime endTime,
    required MeetingPlatform platform,
    required String meetingUrl,
    List<MeetingActionItemModel> actionItems = const [],
  }) async {
    if (_saving) return false;
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      if (isEditing) {
        await _service.updateMeeting(
          meetingName: initialMeeting!.name,
          meetingTitle: meetingTitle,
          description: description,
          meetingAgenda: meetingAgenda,
          meetingDate: meetingDate,
          startTime: startTime,
          endTime: endTime,
          meetingPlatform: platform,
          meetingUrl: meetingUrl,
          participantEmployees: _selectedEmployeeIds.toList(),
        );
      } else {
        await _service.createMeeting(
          meetingTitle: meetingTitle,
          description: description,
          meetingAgenda: meetingAgenda,
          meetingDate: meetingDate,
          startTime: startTime,
          endTime: endTime,
          meetingPlatform: platform,
          meetingUrl: meetingUrl,
          participantEmployees: _selectedEmployeeIds.toList(),
          actionItems: actionItems,
        );
      }
      return true;
    } catch (error) {
      _error = _message(error);
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  String _message(Object error) => error.toString().replaceFirst(
        RegExp(r'^(Exception|MeetingServiceException):\s*'),
        '',
      );

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}
