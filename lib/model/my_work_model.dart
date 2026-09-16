enum MyWorkType { task, todo, unknown }

enum MyWorkSection { overdue, today, upcoming, pendingReview, completed }

class MyWorkItemModel {
  final MyWorkType workType;
  final String name;
  final String? todo;
  final String title;
  final String description;
  final String status;
  final String? todoStatus;
  final String priority;
  final DateTime? dueDate;
  final DateTime? expectedStartDate;
  final DateTime? expectedEndDate;
  final String? referenceType;
  final String? referenceName;
  final String? project;
  final String? company;
  final double progress;
  final String? reviewRemarks;
  final DateTime? completedOn;
  final bool canCompleteDirectly;
  final String? route;

  const MyWorkItemModel({
    required this.workType,
    required this.name,
    required this.title,
    required this.description,
    required this.status,
    this.todo,
    this.todoStatus,
    this.priority = 'Medium',
    this.dueDate,
    this.expectedStartDate,
    this.expectedEndDate,
    this.referenceType,
    this.referenceName,
    this.project,
    this.company,
    this.progress = 0,
    this.reviewRemarks,
    this.completedOn,
    this.canCompleteDirectly = false,
    this.route,
  });

  factory MyWorkItemModel.fromJson(Map<String, dynamic> json) {
    final workType = _workType(json['work_type']);
    final referenceName = _nullableText(json['reference_name']);
    final todo = _nullableText(json['todo']);

    return MyWorkItemModel(
      workType: workType,
      name: _text(
        json['name'] ?? (workType == MyWorkType.task ? referenceName : todo),
      ),
      todo: todo,
      title: _text(
        json['title'] ?? json['subject'] ?? json['description'],
        fallback: 'Untitled work',
      ),
      description: _text(json['description']),
      status: _text(json['status'], fallback: 'Open'),
      todoStatus: _nullableText(json['todo_status']),
      priority: _text(json['priority'], fallback: 'Medium'),
      dueDate: _date(json['due_date']),
      expectedStartDate: _date(json['expected_start_date']),
      expectedEndDate: _date(json['expected_end_date']),
      referenceType: _nullableText(json['reference_type']),
      referenceName: referenceName,
      project: _nullableText(json['project']),
      company: _nullableText(json['company']),
      progress: _double(json['progress']),
      reviewRemarks: _nullableText(json['review_remarks']),
      completedOn: _date(json['completed_on']),
      canCompleteDirectly: _bool(json['can_complete_directly']),
      route: _nullableText(json['route']),
    );
  }

  bool get isTask => workType == MyWorkType.task;
  bool get isTodo => workType == MyWorkType.todo;
  bool get isPendingReview => status.trim().toLowerCase() == 'pending review';
  bool get isCompleted {
    final value = status.trim().toLowerCase();
    return value == 'completed' || value == 'closed';
  }

  /// Task DocType name used by TaskDetailsScreen.
  String? get taskName {
    if (!isTask) return null;
    return _nullableText(referenceName) ?? _nullableText(name);
  }

  /// ToDo name required by complete_employee_todo.
  String? get todoName => _nullableText(todo) ?? (isTodo ? _nullableText(name) : null);
}

class MyWorkCountsModel {
  final int overdue;
  final int today;
  final int upcoming;
  final int pendingReview;
  final int completed;

  const MyWorkCountsModel({
    this.overdue = 0,
    this.today = 0,
    this.upcoming = 0,
    this.pendingReview = 0,
    this.completed = 0,
  });

  factory MyWorkCountsModel.fromJson(Map<String, dynamic> json) {
    return MyWorkCountsModel(
      overdue: _int(json['overdue']),
      today: _int(json['today']),
      upcoming: _int(json['upcoming']),
      pendingReview: _int(json['pending_review']),
      completed: _int(json['completed']),
    );
  }

  int get open => overdue + today + upcoming + pendingReview;
  int get total => open + completed;
}

class MyWorkResponseModel {
  final bool success;
  final String message;
  final int workCount;
  final int openCount;
  final MyWorkCountsModel counts;
  final List<MyWorkItemModel> overdue;
  final List<MyWorkItemModel> today;
  final List<MyWorkItemModel> upcoming;
  final List<MyWorkItemModel> pendingReview;
  final List<MyWorkItemModel> completed;

  const MyWorkResponseModel({
    required this.success,
    this.message = '',
    this.workCount = 0,
    this.openCount = 0,
    this.counts = const MyWorkCountsModel(),
    this.overdue = const [],
    this.today = const [],
    this.upcoming = const [],
    this.pendingReview = const [],
    this.completed = const [],
  });

  factory MyWorkResponseModel.fromJson(Map<String, dynamic> json) {
    final data = unwrapFrappeResponse(json);
    final overdue = _items(data['overdue']);
    final today = _items(data['today']);
    final upcoming = _items(data['upcoming']);
    final pendingReview = _items(data['pending_review']);
    final completed = _items(data['completed']);
    final counts = MyWorkCountsModel.fromJson(_map(data['counts']));
    final calculatedOpen =
        overdue.length + today.length + upcoming.length + pendingReview.length;

    return MyWorkResponseModel(
      success: _bool(data['success']),
      message: _text(data['message']),
      workCount: _int(data['work_count'], calculatedOpen),
      openCount: _int(data['open_count'], calculatedOpen),
      counts: counts,
      overdue: overdue,
      today: today,
      upcoming: upcoming,
      pendingReview: pendingReview,
      completed: completed,
    );
  }

  bool get hasOpenWork => openCount > 0;
  bool get hasAnyWork => counts.total > 0 || allItems.isNotEmpty;

  List<MyWorkItemModel> get openItems => List.unmodifiable([
        ...overdue,
        ...today,
        ...pendingReview,
        ...upcoming,
      ]);

  List<MyWorkItemModel> get allItems => List.unmodifiable([
        ...overdue,
        ...today,
        ...pendingReview,
        ...upcoming,
        ...completed,
      ]);

  List<MyWorkItemModel> itemsFor(MyWorkSection section) {
    switch (section) {
      case MyWorkSection.overdue:
        return overdue;
      case MyWorkSection.today:
        return today;
      case MyWorkSection.upcoming:
        return upcoming;
      case MyWorkSection.pendingReview:
        return pendingReview;
      case MyWorkSection.completed:
        return completed;
    }
  }
}

class DashboardWorkResponseModel {
  final bool success;
  final String message;
  final int workCount;
  final MyWorkCountsModel counts;
  final List<MyWorkItemModel> work;

  const DashboardWorkResponseModel({
    required this.success,
    this.message = '',
    this.workCount = 0,
    this.counts = const MyWorkCountsModel(),
    this.work = const [],
  });

  factory DashboardWorkResponseModel.fromJson(Map<String, dynamic> json) {
    final data = unwrapFrappeResponse(json);
    final work = _items(data['work']);
    return DashboardWorkResponseModel(
      success: _bool(data['success']),
      message: _text(data['message']),
      workCount: _int(data['work_count'], work.length),
      counts: MyWorkCountsModel.fromJson(_map(data['counts'])),
      work: work,
    );
  }
}

class CompleteTodoResultModel {
  final bool success;
  final String message;
  final String todo;
  final String status;

  const CompleteTodoResultModel({
    required this.success,
    this.message = '',
    this.todo = '',
    this.status = '',
  });

  factory CompleteTodoResultModel.fromJson(Map<String, dynamic> json) {
    final data = unwrapFrappeResponse(json);
    return CompleteTodoResultModel(
      success: _bool(data['success']),
      message: _text(data['message']),
      todo: _text(data['todo']),
      status: _text(data['status']),
    );
  }
}

Map<String, dynamic> unwrapFrappeResponse(Map<String, dynamic> json) {
  final message = json['message'];
  return message is Map ? Map<String, dynamic>.from(message) : json;
}

List<MyWorkItemModel> _items(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => MyWorkItemModel.fromJson(Map<String, dynamic>.from(item)))
      .toList(growable: false);
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

MyWorkType _workType(dynamic value) {
  switch (value?.toString().trim().toLowerCase()) {
    case 'task':
      return MyWorkType.task;
    case 'todo':
      return MyWorkType.todo;
    default:
      return MyWorkType.unknown;
  }
}

String _text(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _nullableText(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

DateTime? _date(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : DateTime.tryParse(text);
}

bool _bool(dynamic value) {
  return value == true || value == 1 || value == '1' || value == 'true';
}

int _int(dynamic value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _double(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}
