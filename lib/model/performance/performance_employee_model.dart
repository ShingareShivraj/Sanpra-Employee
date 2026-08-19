class PerformanceEmployeeModel {
  final String employee;
  final String employeeName;
  final String? user;
  final String? company;
  final String? department;
  final String? designation;
  final String? image;
  final String? employmentStatus;

  /// Summary percentages are populated by the manager-list API.
  final int? attendancePercentage;
  final int? taskPercentage;
  final int? todoPercentage;
  final int? issuePercentage;
  final int? overallPercentage;
  final int applicableMetricCount;

  const PerformanceEmployeeModel({
    required this.employee,
    required this.employeeName,
    this.user,
    this.company,
    this.department,
    this.designation,
    this.image,
    this.employmentStatus,
    this.attendancePercentage,
    this.taskPercentage,
    this.todoPercentage,
    this.issuePercentage,
    this.overallPercentage,
    this.applicableMetricCount = 0,
  });

  factory PerformanceEmployeeModel.fromJson(Map<String, dynamic> json) {
    final employee = _string(json['employee']);
    return PerformanceEmployeeModel(
      employee: employee,
      employeeName: _string(json['employee_name'], fallback: employee),
      user: _optionalString(json['user']),
      company: _optionalString(json['company']),
      department: _optionalString(json['department']),
      designation: _optionalString(json['designation']),
      image: _optionalString(json['image']),
      employmentStatus: _optionalString(json['employment_status']),
      attendancePercentage: _nullableInt(json['attendance_percentage']),
      taskPercentage: _nullableInt(json['task_percentage']),
      todoPercentage: _nullableInt(json['todo_percentage']),
      issuePercentage: _nullableInt(json['issue_percentage']),
      overallPercentage: _nullableInt(json['overall_percentage']),
      applicableMetricCount: _int(json['applicable_metric_count']),
    );
  }

  bool get hasOverallPerformance => overallPercentage != null;

  String get subtitle {
    final values = <String>[
      if (designation?.isNotEmpty == true) designation!,
      if (department?.isNotEmpty == true) department!,
    ];
    return values.join(' • ');
  }
}

class EmployeesPerformanceResponseModel {
  final bool success;
  final int month;
  final int year;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime? calendarPeriodEnd;
  final bool isCurrentMonth;
  final bool isPartialMonth;
  final String monthLabel;
  final String? company;
  final List<PerformanceEmployeeModel> employees;
  final int total;
  final int start;
  final int pageLength;
  final bool hasMore;

  const EmployeesPerformanceResponseModel({
    required this.success,
    required this.month,
    required this.year,
    this.periodStart,
    this.periodEnd,
    this.calendarPeriodEnd,
    required this.isCurrentMonth,
    required this.isPartialMonth,
    required this.monthLabel,
    this.company,
    required this.employees,
    required this.total,
    required this.start,
    required this.pageLength,
    required this.hasMore,
  });

  factory EmployeesPerformanceResponseModel.fromJson(Map<String, dynamic> json) {
    final rows = json['employees'] is List ? json['employees'] as List : const [];
    return EmployeesPerformanceResponseModel(
      success: _bool(json['success'], fallback: true),
      month: _int(json['month']),
      year: _int(json['year']),
      periodStart: _date(json['period_start']),
      periodEnd: _date(json['period_end']),
      calendarPeriodEnd: _date(json['calendar_period_end']),
      isCurrentMonth: _bool(json['is_current_month']),
      isPartialMonth: _bool(json['is_partial_month']),
      monthLabel: _string(json['month_label']),
      company: _optionalString(json['company']),
      employees: rows
          .whereType<Map>()
          .map((row) => PerformanceEmployeeModel.fromJson(
                Map<String, dynamic>.from(row),
              ))
          .toList(growable: false),
      total: _int(json['total']),
      start: _int(json['start']),
      pageLength: _int(json['page_length']),
      hasMore: _bool(json['has_more']),
    );
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

int _int(dynamic value, {int fallback = 0}) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? fallback;

int? _nullableInt(dynamic value) {
  if (value == null || value.toString().trim().isEmpty) return null;
  return value is num ? value.round() : int.tryParse(value.toString());
}

bool _bool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  return {'1', 'true', 'yes', 'on'}.contains(value.toString().toLowerCase());
}

DateTime? _date(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : DateTime.tryParse(text.replaceFirst(' ', 'T'));
}
