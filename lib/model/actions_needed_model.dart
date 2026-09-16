enum ActionNeededCategory {
  myWork,
  issues,
  chat,
  meetings,
  leave,
  unknown;

  factory ActionNeededCategory.fromApi(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'my_work':
        return ActionNeededCategory.myWork;
      case 'issues':
        return ActionNeededCategory.issues;
      case 'chat':
        return ActionNeededCategory.chat;
      case 'meetings':
        return ActionNeededCategory.meetings;
      case 'leave':
        return ActionNeededCategory.leave;
      default:
        return ActionNeededCategory.unknown;
    }
  }

  String get apiValue {
    switch (this) {
      case ActionNeededCategory.myWork:
        return 'my_work';
      case ActionNeededCategory.issues:
        return 'issues';
      case ActionNeededCategory.chat:
        return 'chat';
      case ActionNeededCategory.meetings:
        return 'meetings';
      case ActionNeededCategory.leave:
        return 'leave';
      case ActionNeededCategory.unknown:
        return 'unknown';
    }
  }

  String get label {
    switch (this) {
      case ActionNeededCategory.myWork:
        return 'My Work';
      case ActionNeededCategory.issues:
        return 'Issues';
      case ActionNeededCategory.chat:
        return 'Chat';
      case ActionNeededCategory.meetings:
        return 'Meetings';
      case ActionNeededCategory.leave:
        return 'Leave';
      case ActionNeededCategory.unknown:
        return 'Other';
    }
  }

  int get sortOrder {
    switch (this) {
      case ActionNeededCategory.myWork:
        return 0;
      case ActionNeededCategory.issues:
        return 1;
      case ActionNeededCategory.chat:
        return 2;
      case ActionNeededCategory.meetings:
        return 3;
      case ActionNeededCategory.leave:
        return 4;
      case ActionNeededCategory.unknown:
        return 5;
    }
  }
}

class ActionNeededItemModel {
  final String id;
  final ActionNeededCategory category;
  final String categoryValue;
  final String doctype;
  final String name;
  final String title;
  final String description;
  final String actionType;
  final String priority;
  final DateTime? date;
  final String? time;
  final int unreadCount;

  const ActionNeededItemModel({
    required this.id,
    required this.category,
    required this.categoryValue,
    required this.doctype,
    required this.name,
    required this.title,
    required this.description,
    required this.actionType,
    required this.priority,
    this.date,
    this.time,
    this.unreadCount = 0,
  });

  factory ActionNeededItemModel.fromJson(Map<String, dynamic> json) {
    final categoryValue = _string(json['category']);
    return ActionNeededItemModel(
      id: _string(json['id']),
      category: ActionNeededCategory.fromApi(categoryValue),
      categoryValue: categoryValue,
      doctype: _string(json['doctype']),
      name: _string(json['name']),
      title: _string(json['title'], fallback: _string(json['name'])),
      description: _string(json['description']),
      actionType: _string(json['action_type'], fallback: 'open'),
      priority: _string(json['priority'], fallback: 'normal'),
      date: _date(json['date']),
      time: _optionalString(json['time']),
      unreadCount: _integer(json['unread_count']),
    );
  }

  /// Combines the backend date and time when both values are available.
  DateTime? get scheduledAt {
    final value = date;
    if (value == null) return null;
    final parts = time?.split(':') ?? const <String>[];
    if (parts.length < 2) return DateTime(value.year, value.month, value.day);
    return DateTime(
      value.year,
      value.month,
      value.day,
      int.tryParse(parts[0]) ?? 0,
      int.tryParse(parts[1]) ?? 0,
      parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0,
    );
  }

  bool get isChat => category == ActionNeededCategory.chat;
  bool get hasUnreadMessages => isChat && unreadCount > 0;
}

class ActionsNeededResponseModel {
  final bool success;
  final int total;
  final int returned;
  final bool hasMore;
  final DateTime? generatedAt;
  final List<ActionNeededItemModel> actions;

  const ActionsNeededResponseModel({
    required this.success,
    required this.total,
    required this.returned,
    required this.hasMore,
    this.generatedAt,
    this.actions = const [],
  });

  factory ActionsNeededResponseModel.fromJson(Map<String, dynamic> json) {
    final actions = _mapList(json['actions'])
        .map(ActionNeededItemModel.fromJson)
        .toList(growable: false);
    return ActionsNeededResponseModel(
      success: _boolean(json['success'], fallback: true),
      total: _integer(json['total'], fallback: actions.length),
      returned: _integer(json['returned'], fallback: actions.length),
      hasMore: _boolean(json['has_more']),
      generatedAt: _date(json['generated_at']),
      actions: actions,
    );
  }

  bool get isEmpty => actions.isEmpty;
  bool get isNotEmpty => actions.isNotEmpty;

  Map<ActionNeededCategory, List<ActionNeededItemModel>> get groupedActions {
    final result = <ActionNeededCategory, List<ActionNeededItemModel>>{};
    for (final action in actions) {
      result.putIfAbsent(action.category, () => []).add(action);
    }
    return result;
  }
}

String _string(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _optionalString(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

int _integer(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _boolean(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  switch (value?.toString().trim().toLowerCase()) {
    case 'true':
    case '1':
    case 'yes':
      return true;
    case 'false':
    case '0':
    case 'no':
      return false;
    default:
      return fallback;
  }
}

DateTime? _date(dynamic value) {
  if (value is DateTime) return value;
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : DateTime.tryParse(text);
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}
