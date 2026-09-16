import 'package:flutter/foundation.dart';

import '../../model/meeting/meeting_action_item_model.dart';
import '../../model/meeting/meeting_model.dart';
import '../../model/meeting/meeting_participant_model.dart';
import '../../services/meeting_service.dart';

class MeetingDetailViewModel extends ChangeNotifier {
  final MeetingService _service;
  final String meetingName;

  MeetingDetailViewModel({
    required this.meetingName,
    MeetingModel? initialMeeting,
    MeetingService? service,
  })  : _service = service ?? MeetingService(),
        _meeting = initialMeeting;

  MeetingModel? _meeting;
  final List<MeetingEmployeeModel> _companyEmployees = [];
  bool _canManage = false;
  bool _isParticipant = false;
  bool _loading = false;
  bool _refreshing = false;
  bool _actionLoading = false;
  String? _error;

  MeetingModel? get meeting => _meeting;
  List<MeetingEmployeeModel> get companyEmployees =>
      List.unmodifiable(_companyEmployees);
  bool get canManage => _canManage;
  bool get isParticipant => _isParticipant;
  bool get loading => _loading;
  bool get refreshing => _refreshing;
  bool get actionLoading => _actionLoading;
  String? get error => _error;

  Future<void> initialise() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _fetch();
    } catch (error) {
      _error = _message(error);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    _error = null;
    notifyListeners();
    try {
      await _fetch();
    } catch (error) {
      _error = _message(error);
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  Future<void> _fetch() async {
    final response = await _service.getMeetingDetails(meetingName);
    _meeting = response.meeting;
    _canManage = response.canManage;
    _isParticipant = response.isParticipant;
    if (_canManage && _companyEmployees.isEmpty) {
      final employees = await _service.getCompanyEmployees(pageLength: 100);
      _companyEmployees
        ..clear()
        ..addAll(employees.employees);
    }
  }

  Future<bool> cancelMeeting() => _run(() async {
        _meeting = await _service.cancelMeeting(meetingName);
      });

  Future<bool> updateAttendance(
    List<MeetingParticipantModel> participants,
  ) =>
      _run(() async {
        _meeting = await _service.updateAttendance(
          meetingName: meetingName,
          participants: participants,
        );
      });

  Future<bool> updateOutcome({
    required String outcome,
    required String decisions,
    bool markCompleted = false,
  }) =>
      _run(() async {
        _meeting = await _service.updateOutcome(
          meetingName: meetingName,
          outcome: outcome,
          decisions: decisions,
          markCompleted: markCompleted,
        );
      });

  Future<bool> addActionItem(MeetingActionItemModel item) => _run(() async {
        final result = await _service.addActionItem(
          meetingName: meetingName,
          actionItem: item,
        );
        _meeting = result.meeting;
      });

  Future<bool> updateActionItem(MeetingActionItemModel item) => _run(() async {
        _meeting = await _service.updateActionItem(
          meetingName: meetingName,
          actionItem: item,
        );
      });

  Future<bool> deleteActionItem(String rowName) => _run(() async {
        _meeting = await _service.deleteActionItem(
          meetingName: meetingName,
          actionItemName: rowName,
        );
      });

  Future<MeetingTaskResultModel?> createTask(String rowName) async {
    if (_actionLoading) return null;
    _actionLoading = true;
    _error = null;
    notifyListeners();
    try {
      return await _service.createTaskFromActionItem(
        meetingName: meetingName,
        actionItemName: rowName,
      );
    } catch (error) {
      _error = _message(error);
      return null;
    } finally {
      _actionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _run(Future<void> Function() action) async {
    if (_actionLoading) return false;
    _actionLoading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (error) {
      _error = _message(error);
      return false;
    } finally {
      _actionLoading = false;
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
}
