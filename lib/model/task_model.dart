class TaskModel {
  final String name;
  final String? todo;
  final String subject;
  final String description;
  final String status;
  final String priority;
  final String? company;
  final String? project;
  final DateTime? expectedStartDate;
  final DateTime? expectedEndDate;
  final DateTime? dueDate;
  final double progress;
  final String? todoStatus;
  final String? assignedTo;
  final String? assignedBy;
  final DateTime? assignedOn;
  final List<TaskAssigneeModel> assignees;
  final String? completionRemarks;
  final String? completionPhoto;
  final String? completionPhotoUrl;
  final double? completionLatitude;
  final double? completionLongitude;
  final DateTime? completionTime;
  final String? reviewedBy;
  final String? reviewRemarks;
  final String? owner;
  final String? ownerName;
  final DateTime? creation;
  final DateTime? modified;
  final bool canStart;
  final bool canSubmitCompletion;
  final bool canReview;
  final DateTime? reviewTime;

  const TaskModel({
    required this.name,
    required this.subject,
    this.todo,
    this.description = '',
    this.status = '',
    this.priority = 'Medium',
    this.company,
    this.project,
    this.expectedStartDate,
    this.expectedEndDate,
    this.dueDate,
    this.progress = 0,
    this.todoStatus,
    this.assignedTo,
    this.assignedBy,
    this.assignedOn,
    this.assignees = const [],
    this.completionRemarks,
    this.completionPhoto,
    this.completionPhotoUrl,
    this.completionLatitude,
    this.completionLongitude,
    this.completionTime,
    this.reviewedBy,
    this.reviewRemarks,
    this.owner,
    this.ownerName,
    this.creation,
    this.modified,
    this.canStart = false,
    this.canSubmitCompletion = false,
    this.canReview = false,
    this.reviewTime,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
    name: _text(json['name'] ?? json['task_name']),
    todo: _nullableText(json['todo'] ?? json['todo_name']),
    subject: _text(json['subject'] ?? json['description']),
    description: _text(json['description']),
    status: _text(json['status']),
    priority: _text(json['priority'], fallback: 'Medium'),
    company: _nullableText(json['company'] ?? json['custom_company']),
    project: _nullableText(json['project']),
    expectedStartDate:
    _date(json['expected_start_date'] ?? json['exp_start_date']),
    expectedEndDate:
    _date(json['expected_end_date'] ?? json['exp_end_date']),
    dueDate: _date(json['due_date'] ?? json['date'] ?? json['exp_end_date']),
    progress: _double(json['progress']) ?? 0,
    todoStatus: _nullableText(json['todo_status']),
    assignedTo: _nullableText(json['assigned_to'] ?? json['allocated_to']),
    assignedBy: _nullableText(json['assigned_by']),
    assignedOn: _date(json['assigned_on']),
    assignees: _list(json['assignees'])
        .map((item) => TaskAssigneeModel.fromJson(_json(item)))
        .toList(),
    completionRemarks:
    _nullableText(json['completion_remarks'] ?? json['custom_completion_remarks']),
    completionPhoto:
    _nullableText(json['completion_photo'] ?? json['custom_completion_photo']),
    completionPhotoUrl: _nullableText(json['completion_photo_url']),
    completionLatitude: _double(
      json['completion_latitude'] ?? json['custom_completion_latitude'],
    ),
    completionLongitude: _double(
      json['completion_longitude'] ?? json['custom_completion_longitude'],
    ),
    completionTime:
    _date(json['completion_time'] ?? json['custom_completion_time']),
    reviewedBy: _nullableText(json['reviewed_by'] ?? json['custom_reviewed_by']),
    reviewRemarks:
    _nullableText(json['review_remarks'] ?? json['custom_review_remarks']),
    owner: _nullableText(json['owner']),
    ownerName: _nullableText(json['owner_name']),
    creation: _date(json['creation']),
    modified: _date(json['modified']),
    canStart: _boolean(json["can_start"]),

    canSubmitCompletion:
    _boolean(json["can_submit_completion"]),

    canReview:
    _boolean(json["can_review"]),
    reviewTime:
    _date(json['review_time'] ?? json['custom_review_time']),
  );

  bool get isOpen => status.toLowerCase() == 'open';
  bool get isWorking => status.toLowerCase() == 'working';
  bool get isPendingReview => status.toLowerCase() == 'pending review';
  bool get isCompleted => status.toLowerCase() == 'completed';

  Map<String, dynamic> toJson() => {
    'name': name,
    'todo': todo,
    'subject': subject,
    'description': description,
    'status': status,
    'priority': priority,
    'company': company,
    'project': project,
    'expected_start_date': _dateText(expectedStartDate),
    'expected_end_date': _dateText(expectedEndDate),
    'due_date': _dateText(dueDate),
    'progress': progress,
    'todo_status': todoStatus,
    'assigned_to': assignedTo,
    'assigned_by': assignedBy,
    'assigned_on': assignedOn?.toIso8601String(),
    'assignees': assignees.map((item) => item.toJson()).toList(),
    'completion_remarks': completionRemarks,
    'completion_photo': completionPhoto,
    'completion_photo_url': completionPhotoUrl,
    'completion_latitude': completionLatitude,
    'completion_longitude': completionLongitude,
    'completion_time': completionTime?.toIso8601String(),
    'reviewed_by': reviewedBy,
    'review_remarks': reviewRemarks,
    'owner': owner,
    'creation': creation?.toIso8601String(),
    'modified': modified?.toIso8601String(),
    "can_start": canStart,
    "can_submit_completion": canSubmitCompletion,
    "can_review": canReview,
    "review_time": reviewTime?.toIso8601String(),
  };
}


class ProjectModel {
  final String name;
  final String? projectName;
  final String? status;
  final String? priority;
  final DateTime? expectedStartDate;
  final DateTime? expectedEndDate;
  final double? percentComplete;
  final String? company;

  const ProjectModel({
    required this.name,
    this.projectName,
    this.status,
    this.priority,
    this.expectedStartDate,
    this.expectedEndDate,
    this.percentComplete,
    this.company,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      name: _text(json['name']),
      projectName: _nullableText(json['project_name']),
      status: _nullableText(json['status']),
      priority: _nullableText(json['priority']),
      expectedStartDate: _date(json['expected_start_date']),
      expectedEndDate: _date(json['expected_end_date']),
      percentComplete: _double(json['percent_complete']),
      company: _nullableText(json['company']),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'project_name': projectName,
    'status': status,
    'priority': priority,
    'expected_start_date': _dateText(expectedStartDate),
    'expected_end_date': _dateText(expectedEndDate),
    'percent_complete': percentComplete,
    'company': company,
  };
}


class CompanyProjectsResponseModel {
  final bool success;
  final String message;
  final String? company;
  final int projectCount;
  final List<ProjectModel> projects;

  const CompanyProjectsResponseModel({
    required this.success,
    this.message = '',
    this.company,
    this.projectCount = 0,
    this.projects = const [],
  });

  factory CompanyProjectsResponseModel.fromJson(
      Map<String, dynamic> json,
      ) {
    final data = unwrapFrappeResponse(json);

    return CompanyProjectsResponseModel(
      success: _boolean(data['success']),
      message: _text(data['message']),
      company: _nullableText(data['company']),
      projectCount: _integer(data['project_count']),
      projects: _list(data['projects'])
          .map((item) => ProjectModel.fromJson(_json(item)))
          .toList(),
    );
  }
}

class TaskAssigneeModel {
  final String? todo;
  final String user;
  final String? fullName;
  final String? status;

  const TaskAssigneeModel({
    required this.user,
    this.todo,
    this.fullName,
    this.status,
  });

  factory TaskAssigneeModel.fromJson(Map<String, dynamic> json) =>
      TaskAssigneeModel(
        todo: _nullableText(json['todo'] ?? json['name']),
        user: _text(json['user'] ?? json['allocated_to']),
        fullName: _nullableText(json['full_name'] ?? json['employee_name']),
        status: _nullableText(json['status']),
      );

  Map<String, dynamic> toJson() => {
    'todo': todo,
    'user': user,
    'full_name': fullName,
    'status': status,
  };
}

class TaskCountsModel {
  final int open;
  final int overdue;
  final int today;
  final int upcoming;
  final int pendingReview;
  final int completed;

  const TaskCountsModel({
    this.open = 0,
    this.overdue = 0,
    this.today = 0,
    this.upcoming = 0,
    this.pendingReview = 0,
    this.completed = 0,
  });

  factory TaskCountsModel.fromJson(Map<String, dynamic> json) => TaskCountsModel(
    open: _integer(json['open']),
    overdue: _integer(json['overdue']),
    today: _integer(json['today']),
    upcoming: _integer(json['upcoming']),
    pendingReview: _integer(json['pending_review']),
    completed: _integer(json['completed']),
  );
}

class EmployeeTasksResponseModel {
  final bool success;
  final String message;
  final TaskCountsModel counts;
  final List<TaskModel> overdue;
  final List<TaskModel> today;
  final List<TaskModel> upcoming;
  final List<TaskModel> pendingReview;
  final List<TaskModel> completed;

  const EmployeeTasksResponseModel({
    required this.success,
    this.message = '',
    this.counts = const TaskCountsModel(),
    this.overdue = const [],
    this.today = const [],
    this.upcoming = const [],
    this.pendingReview = const [],
    this.completed = const [],
  });

  factory EmployeeTasksResponseModel.fromJson(Map<String, dynamic> json) {
    final data = unwrapFrappeResponse(json);
    List<TaskModel> tasks(String key) => _list(data[key])
        .map((item) => TaskModel.fromJson(_json(item)))
        .toList();

    return EmployeeTasksResponseModel(
      success: _boolean(data['success']),
      message: _text(data['message']),
      counts: TaskCountsModel.fromJson(_json(data['counts'])),
      overdue: tasks('overdue'),
      today: tasks('today'),
      upcoming: tasks('upcoming'),
      pendingReview: tasks('pending_review'),
      completed: tasks('completed'),
    );
  }
}

Map<String, dynamic> unwrapFrappeResponse(Map<String, dynamic> json) {
  final message = json['message'];
  return message is Map ? Map<String, dynamic>.from(message) : json;
}

Map<String, dynamic> _json(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
List<dynamic> _list(dynamic value) => value is List ? value : const [];
String _text(dynamic value, {String fallback = ''}) =>
    value == null ? fallback : value.toString();
String? _nullableText(dynamic value) =>
    value == null || value.toString().trim().isEmpty ? null : value.toString();
bool _boolean(dynamic value) =>
    value == true || value == 1 || value == '1' || value == 'true';
int _integer(dynamic value) => value is num
    ? value.toInt()
    : int.tryParse(value?.toString() ?? '') ?? 0;
double? _double(dynamic value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '');
DateTime? _date(dynamic value) => value == null || value.toString().isEmpty
    ? null
    : DateTime.tryParse(value.toString());
String? _dateText(DateTime? value) =>
    value == null ? null : value.toIso8601String().split('T').first;
