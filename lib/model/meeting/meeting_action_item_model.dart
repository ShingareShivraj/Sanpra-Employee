enum MeetingActionItemStatus {
  pending('Pending'),
  completed('Completed');

  const MeetingActionItemStatus(this.apiValue);

  final String apiValue;

  bool get isCompleted => this == MeetingActionItemStatus.completed;

  static MeetingActionItemStatus fromApiValue(dynamic value) {
    final text = value?.toString().trim().toLowerCase();
    return MeetingActionItemStatus.values.firstWhere(
      (status) => status.apiValue.toLowerCase() == text,
      orElse: () => MeetingActionItemStatus.pending,
    );
  }
}

class MeetingActionItemModel {
  final String? rowName;
  final String action;
  final String assignedTo;
  final String assignedToName;
  final DateTime? dueDate;
  final MeetingActionItemStatus status;
  final String notes;

  /// Request-only option. When true during creation, the backend also creates
  /// and assigns an ERPNext Task for this action item.
  final bool createTask;

  const MeetingActionItemModel({
    this.rowName,
    required this.action,
    required this.assignedTo,
    this.assignedToName = '',
    this.dueDate,
    this.status = MeetingActionItemStatus.pending,
    this.notes = '',
    this.createTask = false,
  });

  factory MeetingActionItemModel.fromJson(Map<String, dynamic> json) {
    final assignedTo = _string(json['assigned_to']);
    return MeetingActionItemModel(
      rowName: _optionalString(json['row_name'] ?? json['name']),
      action: _string(json['action']),
      assignedTo: assignedTo,
      assignedToName:
          _string(json['assigned_to_name'], fallback: assignedTo),
      dueDate: _date(json['due_date']),
      status: MeetingActionItemStatus.fromApiValue(json['status']),
      notes: _string(json['notes']),
      createTask: _bool(json['create_task']),
    );
  }

  Map<String, dynamic> toJson({bool includeCreateTask = true}) => {
        if (rowName?.isNotEmpty == true) 'action_item_name': rowName,
        'action': action.trim(),
        'assigned_to': assignedTo.trim(),
        'due_date': dueDate == null ? '' : _dateOnly(dueDate!),
        'status': status.apiValue,
        'notes': notes.trim(),
        if (includeCreateTask) 'create_task': createTask ? 1 : 0,
      };

  MeetingActionItemModel copyWith({
    String? rowName,
    String? action,
    String? assignedTo,
    String? assignedToName,
    DateTime? dueDate,
    bool clearDueDate = false,
    MeetingActionItemStatus? status,
    String? notes,
    bool? createTask,
  }) {
    return MeetingActionItemModel(
      rowName: rowName ?? this.rowName,
      action: action ?? this.action,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createTask: createTask ?? this.createTask,
    );
  }
}

String _dateOnly(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DateTime? _date(dynamic value) {
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

bool _bool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return {'1', 'true', 'yes', 'on'}
      .contains(value?.toString().trim().toLowerCase());
}
