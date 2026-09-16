import 'meeting_action_item_model.dart';
import 'meeting_participant_model.dart';

enum MeetingPlatform {
  googleMeet('Google Meet'),
  microsoftTeams('Microsoft Teams'),
  zoom('Zoom'),
  webex('Webex'),
  jitsi('Jitsi'),
  other('Other');

  const MeetingPlatform(this.apiValue);

  final String apiValue;

  static MeetingPlatform fromApiValue(dynamic value) {
    final text = value?.toString().trim().toLowerCase();
    return MeetingPlatform.values.firstWhere(
      (platform) => platform.apiValue.toLowerCase() == text,
      orElse: () => MeetingPlatform.other,
    );
  }
}

enum MeetingStatus {
  scheduled('Scheduled'),
  completed('Completed'),
  cancelled('Cancelled');

  const MeetingStatus(this.apiValue);

  final String apiValue;

  bool get isScheduled => this == MeetingStatus.scheduled;
  bool get isCompleted => this == MeetingStatus.completed;
  bool get isCancelled => this == MeetingStatus.cancelled;

  static MeetingStatus fromApiValue(dynamic value) {
    final text = value?.toString().trim().toLowerCase();
    return MeetingStatus.values.firstWhere(
      (status) => status.apiValue.toLowerCase() == text,
      orElse: () => MeetingStatus.scheduled,
    );
  }
}

enum MeetingListView {
  upcoming('upcoming'),
  past('past'),
  all('all');

  const MeetingListView(this.apiValue);
  final String apiValue;
}

class MeetingModel {
  final String name;
  final String meetingTitle;
  final String company;
  final String description;
  final String meetingAgenda;
  final DateTime? meetingDate;
  final String startTime;
  final String endTime;
  final DateTime? startAt;
  final DateTime? endAt;
  final MeetingPlatform meetingPlatform;
  final String meetingUrl;
  final String organizer;
  final String organizerName;
  final MeetingStatus status;
  final int participantCount;
  final bool isOrganizer;
  final String outcome;
  final String decisions;
  final List<MeetingParticipantModel> participants;
  final List<MeetingActionItemModel> actionItems;
  final DateTime? creation;
  final DateTime? modified;

  const MeetingModel({
    required this.name,
    required this.meetingTitle,
    required this.company,
    this.description = '',
    this.meetingAgenda = '',
    this.meetingDate,
    this.startTime = '',
    this.endTime = '',
    this.startAt,
    this.endAt,
    this.meetingPlatform = MeetingPlatform.other,
    this.meetingUrl = '',
    this.organizer = '',
    this.organizerName = '',
    this.status = MeetingStatus.scheduled,
    this.participantCount = 0,
    this.isOrganizer = false,
    this.outcome = '',
    this.decisions = '',
    this.participants = const [],
    this.actionItems = const [],
    this.creation,
    this.modified,
  });

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    final participants = _modelList(
      json['participants'],
      MeetingParticipantModel.fromJson,
    );
    final actions = _modelList(
      json['action_items'],
      MeetingActionItemModel.fromJson,
    );
    final meetingDate = _date(json['meeting_date']);
    final startTime = _string(json['start_time']);
    final endTime = _string(json['end_time']);

    return MeetingModel(
      name: _string(json['name']),
      meetingTitle: _string(json['meeting_title']),
      company: _string(json['company']),
      description: _string(json['description']),
      meetingAgenda: _string(json['meeting_agenda']),
      meetingDate: meetingDate,
      startTime: startTime,
      endTime: endTime,
      startAt: _dateTime(json['start_at']) ??
          _combineDateAndTime(meetingDate, startTime),
      endAt:
          _dateTime(json['end_at']) ?? _combineDateAndTime(meetingDate, endTime),
      meetingPlatform: MeetingPlatform.fromApiValue(json['meeting_platform']),
      meetingUrl: _string(json['meeting_url']),
      organizer: _string(json['organizer']),
      organizerName: _string(
        json['organizer_name'],
        fallback: _string(json['organizer']),
      ),
      status: MeetingStatus.fromApiValue(json['status']),
      participantCount:
          _integer(json['participant_count'], fallback: participants.length),
      isOrganizer: _bool(json['is_organizer']),
      outcome: _string(json['outcome']),
      decisions: _string(json['decisions']),
      participants: participants,
      actionItems: actions,
      creation: _dateTime(json['creation']),
      modified: _dateTime(json['modified']),
    );
  }

  bool get canJoin => status.isScheduled && meetingUrl.trim().isNotEmpty;
  bool get hasAgenda => meetingAgenda.trim().isNotEmpty;
  bool get hasOutcome => outcome.trim().isNotEmpty;
  bool get hasDecisions => decisions.trim().isNotEmpty;
  bool get hasActionItems => actionItems.isNotEmpty;
  bool get isPast => status.isCompleted || status.isCancelled ||
      (endAt != null && endAt!.isBefore(DateTime.now()));
  bool get isUpcoming => status.isScheduled && !isPast;

  MeetingModel copyWith({
    String? name,
    String? meetingTitle,
    String? company,
    String? description,
    String? meetingAgenda,
    DateTime? meetingDate,
    String? startTime,
    String? endTime,
    DateTime? startAt,
    DateTime? endAt,
    MeetingPlatform? meetingPlatform,
    String? meetingUrl,
    String? organizer,
    String? organizerName,
    MeetingStatus? status,
    int? participantCount,
    bool? isOrganizer,
    String? outcome,
    String? decisions,
    List<MeetingParticipantModel>? participants,
    List<MeetingActionItemModel>? actionItems,
    DateTime? creation,
    DateTime? modified,
  }) {
    return MeetingModel(
      name: name ?? this.name,
      meetingTitle: meetingTitle ?? this.meetingTitle,
      company: company ?? this.company,
      description: description ?? this.description,
      meetingAgenda: meetingAgenda ?? this.meetingAgenda,
      meetingDate: meetingDate ?? this.meetingDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      meetingPlatform: meetingPlatform ?? this.meetingPlatform,
      meetingUrl: meetingUrl ?? this.meetingUrl,
      organizer: organizer ?? this.organizer,
      organizerName: organizerName ?? this.organizerName,
      status: status ?? this.status,
      participantCount: participantCount ?? this.participantCount,
      isOrganizer: isOrganizer ?? this.isOrganizer,
      outcome: outcome ?? this.outcome,
      decisions: decisions ?? this.decisions,
      participants: participants ?? this.participants,
      actionItems: actionItems ?? this.actionItems,
      creation: creation ?? this.creation,
      modified: modified ?? this.modified,
    );
  }
}

class MeetingEmployeeModel {
  final String name;
  final String employeeName;
  final String? department;
  final String? designation;
  final String? image;
  final String? userId;

  const MeetingEmployeeModel({
    required this.name,
    required this.employeeName,
    this.department,
    this.designation,
    this.image,
    this.userId,
  });

  factory MeetingEmployeeModel.fromJson(Map<String, dynamic> json) {
    final name = _string(json['name']);
    return MeetingEmployeeModel(
      name: name,
      employeeName: _string(json['employee_name'], fallback: name),
      department: _optionalString(json['department']),
      designation: _optionalString(json['designation']),
      image: _optionalString(json['image']),
      userId: _optionalString(json['user_id']),
    );
  }
}

class MeetingAccessModel {
  final bool success;
  final MeetingEmployeeModel employee;
  final bool isMeetingManager;
  final bool canCreate;
  final bool canManage;

  const MeetingAccessModel({
    required this.success,
    required this.employee,
    required this.isMeetingManager,
    required this.canCreate,
    required this.canManage,
  });

  factory MeetingAccessModel.fromJson(Map<String, dynamic> json) {
    return MeetingAccessModel(
      success: _bool(json['success'], fallback: true),
      employee: MeetingEmployeeModel.fromJson(_map(json['employee'])),
      isMeetingManager: _bool(json['is_meeting_manager']),
      canCreate: _bool(json['can_create']),
      canManage: _bool(json['can_manage']),
    );
  }
}

class MeetingListResponseModel {
  final List<MeetingModel> meetings;
  final bool hasMore;

  const MeetingListResponseModel({
    required this.meetings,
    required this.hasMore,
  });

  factory MeetingListResponseModel.fromJson(Map<String, dynamic> json) {
    return MeetingListResponseModel(
      meetings: _modelList(json['meetings'], MeetingModel.fromJson),
      hasMore: _bool(json['has_more']),
    );
  }
}

class MeetingDetailsResponseModel {
  final MeetingModel meeting;
  final bool canManage;
  final bool isParticipant;

  const MeetingDetailsResponseModel({
    required this.meeting,
    required this.canManage,
    required this.isParticipant,
  });

  factory MeetingDetailsResponseModel.fromJson(Map<String, dynamic> json) {
    return MeetingDetailsResponseModel(
      meeting: MeetingModel.fromJson(_map(json['meeting'])),
      canManage: _bool(json['can_manage']),
      isParticipant: _bool(json['is_participant']),
    );
  }
}

class MeetingEmployeePageModel {
  final List<MeetingEmployeeModel> employees;
  final bool hasMore;

  const MeetingEmployeePageModel({
    required this.employees,
    required this.hasMore,
  });

  factory MeetingEmployeePageModel.fromJson(Map<String, dynamic> json) {
    return MeetingEmployeePageModel(
      employees: _modelList(json['employees'], MeetingEmployeeModel.fromJson),
      hasMore: _bool(json['has_more']),
    );
  }
}

class MeetingMutationResponseModel {
  final String message;
  final MeetingModel meeting;
  final List<MeetingTaskResultModel> tasks;

  const MeetingMutationResponseModel({
    required this.message,
    required this.meeting,
    this.tasks = const [],
  });

  factory MeetingMutationResponseModel.fromJson(Map<String, dynamic> json) {
    return MeetingMutationResponseModel(
      message: _string(json['message']),
      meeting: MeetingModel.fromJson(_map(json['meeting'])),
      tasks: _modelList(json['tasks'], MeetingTaskResultModel.fromJson),
    );
  }
}

class MeetingTaskResultModel {
  final String? task;
  final bool alreadyCreated;

  const MeetingTaskResultModel({this.task, required this.alreadyCreated});

  factory MeetingTaskResultModel.fromJson(Map<String, dynamic> json) {
    return MeetingTaskResultModel(
      task: _optionalString(json['task']),
      alreadyCreated: _bool(json['already_created']),
    );
  }
}

List<T> _modelList<T>(dynamic value, T Function(Map<String, dynamic>) parser) {
  if (value is! List) return <T>[];
  return value
      .whereType<Map>()
      .map((row) => parser(Map<String, dynamic>.from(row)))
      .toList(growable: false);
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

DateTime? _combineDateAndTime(DateTime? date, String time) {
  if (date == null || time.trim().isEmpty) return null;
  final pieces = time.trim().split(':');
  if (pieces.length < 2) return null;
  final hour = int.tryParse(pieces[0]);
  final minute = int.tryParse(pieces[1]);
  final second = pieces.length > 2
      ? int.tryParse(pieces[2].split('.').first) ?? 0
      : 0;
  if (hour == null || minute == null) return null;
  return DateTime(date.year, date.month, date.day, hour, minute, second);
}

DateTime? _date(dynamic value) {
  final parsed = _dateTime(value);
  return parsed == null ? null : DateTime(parsed.year, parsed.month, parsed.day);
}

DateTime? _dateTime(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : DateTime.tryParse(text.replaceFirst(' ', 'T'));
}

String _string(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _optionalString(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

bool _bool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value.toString().trim().toLowerCase();
  if ({'1', 'true', 'yes', 'on'}.contains(text)) return true;
  if ({'0', 'false', 'no', 'off'}.contains(text)) return false;
  return fallback;
}

int _integer(dynamic value, {int fallback = 0}) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;
