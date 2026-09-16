import 'dart:convert';

import 'package:dio/dio.dart';

import '../model/meeting/meeting_action_item_model.dart';
import '../model/meeting/meeting_model.dart';
import '../model/meeting/meeting_participant_model.dart';
import 'api_endpoints.dart';
import 'api_service.dart';

class MeetingService {
  final ApiService _api;

  MeetingService({ApiService? api}) : _api = api ?? ApiService();

  Future<MeetingAccessModel> getAccess() async {
    return MeetingAccessModel.fromJson(
      await _get(ApiEndpoints.meetingAccess),
    );
  }

  Future<MeetingEmployeePageModel> getCompanyEmployees({
    String? search,
    int start = 0,
    int pageLength = 50,
  }) async {
    final data = await _get(
      ApiEndpoints.meetingEmployees,
      query: {
        if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
        'limit_start': start < 0 ? 0 : start,
        'limit_page_length': pageLength.clamp(1, 100),
      },
    );
    return MeetingEmployeePageModel.fromJson(data);
  }

  Future<MeetingListResponseModel> getMeetings({
    MeetingListView view = MeetingListView.upcoming,
    String? search,
    int start = 0,
    int pageLength = 20,
  }) async {
    final data = await _get(
      ApiEndpoints.myMeetings,
      query: {
        'view': view.apiValue,
        if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
        'limit_start': start < 0 ? 0 : start,
        'limit_page_length': pageLength.clamp(1, 100),
      },
    );
    return MeetingListResponseModel.fromJson(data);
  }

  Future<MeetingDetailsResponseModel> getMeetingDetails(
    String meetingName,
  ) async {
    _required(meetingName, 'Meeting is required.');
    final data = await _get(
      ApiEndpoints.meetingDetails,
      query: {'meeting_name': meetingName.trim()},
    );
    return MeetingDetailsResponseModel.fromJson(data);
  }

  Future<MeetingMutationResponseModel> createMeeting({
    required String meetingTitle,
    String description = '',
    String meetingAgenda = '',
    required DateTime meetingDate,
    required DateTime startTime,
    required DateTime endTime,
    required MeetingPlatform meetingPlatform,
    required String meetingUrl,
    required List<String> participantEmployees,
    List<MeetingActionItemModel> actionItems = const [],
  }) async {
    _validateMeeting(
      meetingTitle: meetingTitle,
      meetingUrl: meetingUrl,
      startTime: startTime,
      endTime: endTime,
    );
    final data = await _post(
      ApiEndpoints.createMeeting,
      data: {
        'meeting_title': meetingTitle.trim(),
        'description': description.trim(),
        'meeting_agenda': meetingAgenda.trim(),
        'meeting_date': _dateOnly(meetingDate),
        'start_time': _timeOnly(startTime),
        'end_time': _timeOnly(endTime),
        'meeting_platform': meetingPlatform.apiValue,
        'meeting_url': meetingUrl.trim(),
        'participants': participantEmployees
            .map((employee) => {'employee': employee.trim()})
            .toList(growable: false),
        'action_items': actionItems
            .map((item) => item.toJson())
            .toList(growable: false),
      },
    );
    return MeetingMutationResponseModel.fromJson(data);
  }

  Future<MeetingMutationResponseModel> updateMeeting({
    required String meetingName,
    required String meetingTitle,
    String description = '',
    String meetingAgenda = '',
    required DateTime meetingDate,
    required DateTime startTime,
    required DateTime endTime,
    required MeetingPlatform meetingPlatform,
    required String meetingUrl,
    required List<String> participantEmployees,
  }) async {
    _required(meetingName, 'Meeting is required.');
    _validateMeeting(
      meetingTitle: meetingTitle,
      meetingUrl: meetingUrl,
      startTime: startTime,
      endTime: endTime,
    );
    final data = await _post(
      ApiEndpoints.updateMeeting,
      data: {
        'meeting_name': meetingName.trim(),
        'meeting_title': meetingTitle.trim(),
        'description': description.trim(),
        'meeting_agenda': meetingAgenda.trim(),
        'meeting_date': _dateOnly(meetingDate),
        'start_time': _timeOnly(startTime),
        'end_time': _timeOnly(endTime),
        'meeting_platform': meetingPlatform.apiValue,
        'meeting_url': meetingUrl.trim(),
        'participants': participantEmployees
            .map((employee) => {'employee': employee.trim()})
            .toList(growable: false),
      },
    );
    return MeetingMutationResponseModel.fromJson(data);
  }

  Future<MeetingModel> cancelMeeting(String meetingName) async {
    _required(meetingName, 'Meeting is required.');
    final data = await _post(
      ApiEndpoints.cancelMeeting,
      data: {'meeting_name': meetingName.trim()},
    );
    final meetingData = _map(data['meeting']);
    if (meetingData.isNotEmpty) return MeetingModel.fromJson(meetingData);
    return (await getMeetingDetails(meetingName)).meeting;
  }

  Future<MeetingModel> updateAttendance({
    required String meetingName,
    required List<MeetingParticipantModel> participants,
  }) async {
    _required(meetingName, 'Meeting is required.');
    if (participants.isEmpty) {
      throw const MeetingServiceException('Attendance list cannot be empty.');
    }
    final data = await _post(
      ApiEndpoints.updateMeetingAttendance,
      data: {
        'meeting_name': meetingName.trim(),
        'attendance': participants
            .map((participant) => participant.toAttendanceJson())
            .toList(growable: false),
      },
    );
    return MeetingModel.fromJson(_map(data['meeting']));
  }

  Future<MeetingModel> updateOutcome({
    required String meetingName,
    required String outcome,
    required String decisions,
    bool markCompleted = false,
  }) async {
    _required(meetingName, 'Meeting is required.');
    final data = await _post(
      ApiEndpoints.updateMeetingOutcome,
      data: {
        'meeting_name': meetingName.trim(),
        'outcome': outcome.trim(),
        'decisions': decisions.trim(),
        'mark_completed': markCompleted ? 1 : 0,
      },
    );
    return MeetingModel.fromJson(_map(data['meeting']));
  }

  Future<MeetingActionMutationResult> addActionItem({
    required String meetingName,
    required MeetingActionItemModel actionItem,
  }) async {
    _required(meetingName, 'Meeting is required.');
    _validateActionItem(actionItem);
    final data = await _post(
      ApiEndpoints.addMeetingActionItem,
      data: {
        'meeting_name': meetingName.trim(),
        ...actionItem.toJson(),
      },
    );
    return MeetingActionMutationResult.fromJson(data);
  }

  Future<MeetingModel> updateActionItem({
    required String meetingName,
    required MeetingActionItemModel actionItem,
  }) async {
    _required(meetingName, 'Meeting is required.');
    _required(actionItem.rowName ?? '', 'Action item is required.');
    _validateActionItem(actionItem);
    final data = await _post(
      ApiEndpoints.updateMeetingActionItem,
      data: {
        'meeting_name': meetingName.trim(),
        ...actionItem.toJson(includeCreateTask: false),
      },
    );
    return MeetingModel.fromJson(_map(data['meeting']));
  }

  /// Updates only status/notes. Use this after an action item has created a
  /// Task, because its action, assignee and due date are then intentionally
  /// locked by the backend to prevent the meeting and Task from diverging.
  Future<MeetingModel> updateActionItemStatus({
    required String meetingName,
    required String actionItemName,
    required MeetingActionItemStatus status,
    String? notes,
  }) async {
    _required(meetingName, 'Meeting is required.');
    _required(actionItemName, 'Action item is required.');
    final data = await _post(
      ApiEndpoints.updateMeetingActionItem,
      data: {
        'meeting_name': meetingName.trim(),
        'action_item_name': actionItemName.trim(),
        'status': status.apiValue,
        if (notes != null) 'notes': notes.trim(),
      },
    );
    return MeetingModel.fromJson(_map(data['meeting']));
  }

  Future<MeetingModel> deleteActionItem({
    required String meetingName,
    required String actionItemName,
  }) async {
    _required(meetingName, 'Meeting is required.');
    _required(actionItemName, 'Action item is required.');
    final data = await _post(
      ApiEndpoints.deleteMeetingActionItem,
      data: {
        'meeting_name': meetingName.trim(),
        'action_item_name': actionItemName.trim(),
      },
    );
    return MeetingModel.fromJson(_map(data['meeting']));
  }

  Future<MeetingTaskResultModel> createTaskFromActionItem({
    required String meetingName,
    required String actionItemName,
  }) async {
    _required(meetingName, 'Meeting is required.');
    _required(actionItemName, 'Action item is required.');
    final data = await _post(
      ApiEndpoints.createMeetingTask,
      data: {
        'meeting_name': meetingName.trim(),
        'action_item_name': actionItemName.trim(),
      },
    );
    return MeetingTaskResultModel.fromJson(data);
  }

  Future<Map<String, dynamic>> _get(
    String url, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _api.get(url: url, queryParameters: query);
      return _requireSuccess(_unwrapMessage(response.data));
    } on DioException catch (error) {
      throw MeetingServiceException(_dioMessage(error));
    } on MeetingServiceException {
      rethrow;
    } catch (error) {
      throw MeetingServiceException(_cleanError(error));
    }
  }

  Future<Map<String, dynamic>> _post(
    String url, {
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _api.post(url: url, data: data);
      return _requireSuccess(_unwrapMessage(response.data));
    } on DioException catch (error) {
      throw MeetingServiceException(_dioMessage(error));
    } on MeetingServiceException {
      rethrow;
    } catch (error) {
      throw MeetingServiceException(_cleanError(error));
    }
  }

  Map<String, dynamic> _unwrapMessage(dynamic value) {
    final root = _map(value);
    return root['message'] is Map ? _map(root['message']) : root;
  }

  Map<String, dynamic> _requireSuccess(Map<String, dynamic> data) {
    if (data['success'] == false) {
      throw MeetingServiceException(
        data['message']?.toString().trim().isNotEmpty == true
            ? data['message'].toString()
            : 'Unable to complete the meeting request.',
      );
    }
    return data;
  }

  void _validateMeeting({
    required String meetingTitle,
    required String meetingUrl,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    _required(meetingTitle, 'Meeting title is required.');
    _required(meetingUrl, 'Meeting URL is required.');
    final uri = Uri.tryParse(meetingUrl.trim());
    if (uri == null ||
        !{'http', 'https'}.contains(uri.scheme.toLowerCase()) ||
        uri.host.isEmpty) {
      throw const MeetingServiceException(
        'Enter a valid HTTP or HTTPS meeting URL.',
      );
    }
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    if (endMinutes <= startMinutes) {
      throw const MeetingServiceException(
        'End time must be after start time.',
      );
    }
  }

  void _validateActionItem(MeetingActionItemModel item) {
    _required(item.action, 'Action item is required.');
    _required(item.assignedTo, 'Assigned employee is required.');
  }

  void _required(String value, String message) {
    if (value.trim().isEmpty) throw MeetingServiceException(message);
  }

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String _timeOnly(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}:00';

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  static String _dioMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final serverMessages = data['_server_messages'];
      if (serverMessages is String && serverMessages.isNotEmpty) {
        try {
          final decoded = jsonDecode(serverMessages);
          if (decoded is List && decoded.isNotEmpty) {
            final first = jsonDecode(decoded.first.toString());
            if (first is Map && first['message'] != null) {
              return _stripHtml(first['message'].toString());
            }
          }
        } catch (_) {}
      }
      final message = data['message'];
      if (message is Map && message['message'] != null) {
        return _stripHtml(message['message'].toString());
      }
      if (message is String && message.trim().isNotEmpty) {
        return _stripHtml(message);
      }
      if (data['exception'] != null) {
        return data['exception']
            .toString()
            .split('\n')
            .first
            .replaceFirst(RegExp(r'^[\w.]+:\s*'), '');
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The meeting request timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to the server.';
      default:
        return error.message ?? 'Unable to complete the meeting request.';
    }
  }

  static String _stripHtml(String value) =>
      value.replaceAll(RegExp(r'<[^>]*>'), '').trim();

  static String _cleanError(Object error) =>
      error.toString().replaceFirst(RegExp(r'^MeetingServiceException:\s*'), '');
}

class MeetingActionMutationResult {
  final MeetingActionItemModel actionItem;
  final MeetingModel meeting;
  final MeetingTaskResultModel? task;

  const MeetingActionMutationResult({
    required this.actionItem,
    required this.meeting,
    this.task,
  });

  factory MeetingActionMutationResult.fromJson(Map<String, dynamic> json) {
    final taskData = json['task'];
    return MeetingActionMutationResult(
      actionItem:
          MeetingActionItemModel.fromJson(MeetingService._map(json['action_item'])),
      meeting: MeetingModel.fromJson(MeetingService._map(json['meeting'])),
      task: taskData is Map
          ? MeetingTaskResultModel.fromJson(Map<String, dynamic>.from(taskData))
          : null,
    );
  }
}

class MeetingServiceException implements Exception {
  final String message;

  const MeetingServiceException(this.message);

  @override
  String toString() => message;
}
