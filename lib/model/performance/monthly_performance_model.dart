import 'performance_employee_model.dart';

class AttendancePerformanceModel {
  final bool applicable;
  final int? percentage;
  final double? percentageExact;
  final double present;
  final int workingDays;
  final String? naReason;
  final Map<String, int> statusCounts;
  final int holidayCount;

  const AttendancePerformanceModel({
    required this.applicable,
    this.percentage,
    this.percentageExact,
    required this.present,
    required this.workingDays,
    this.naReason,
    this.statusCounts = const {},
    this.holidayCount = 0,
  });

  factory AttendancePerformanceModel.fromJson(Map<String, dynamic> json) {
    final rawCounts = json['status_counts'];
    final counts = <String, int>{};
    if (rawCounts is Map) {
      for (final entry in rawCounts.entries) {
        counts[entry.key.toString()] = _int(entry.value);
      }
    }
    return AttendancePerformanceModel(
      applicable: _bool(json['applicable']),
      percentage: _nullableInt(json['percentage']),
      percentageExact: _nullableDouble(json['percentage_exact']),
      present: _double(json['present']),
      workingDays: _int(json['working_days']),
      naReason: _optionalString(json['na_reason']),
      statusCounts: Map.unmodifiable(counts),
      holidayCount: _int(json['holiday_count']),
    );
  }

  String get displayPercentage => percentage == null ? 'N/A' : '$percentage%';
}

class CompletionPerformanceModel {
  final bool applicable;
  final int? percentage;
  final double? percentageExact;
  final int completed;
  final int total;
  final String? naReason;

  const CompletionPerformanceModel({
    required this.applicable,
    this.percentage,
    this.percentageExact,
    required this.completed,
    required this.total,
    this.naReason,
  });

  factory CompletionPerformanceModel.fromJson(Map<String, dynamic> json) =>
      CompletionPerformanceModel(
        applicable: _bool(json['applicable']),
        percentage: _nullableInt(json['percentage']),
        percentageExact: _nullableDouble(json['percentage_exact']),
        completed: _int(json['completed']),
        total: _int(json['total']),
        naReason: _optionalString(json['na_reason']),
      );

  String get displayPercentage => percentage == null ? 'N/A' : '$percentage%';
}

class IssuePerformanceModel {
  final bool applicable;
  final int? percentage;
  final double? percentageExact;
  final int resolved;
  final int total;
  final String? naReason;

  const IssuePerformanceModel({
    required this.applicable,
    this.percentage,
    this.percentageExact,
    required this.resolved,
    required this.total,
    this.naReason,
  });

  factory IssuePerformanceModel.fromJson(Map<String, dynamic> json) =>
      IssuePerformanceModel(
        applicable: _bool(json['applicable']),
        percentage: _nullableInt(json['percentage']),
        percentageExact: _nullableDouble(json['percentage_exact']),
        resolved: _int(json['resolved']),
        total: _int(json['total']),
        naReason: _optionalString(json['na_reason']),
      );

  String get displayPercentage => percentage == null ? 'N/A' : '$percentage%';
}

class MonthlyPerformanceModel {
  final PerformanceEmployeeModel employee;
  final int month;
  final int year;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime? calendarPeriodEnd;
  final bool isCurrentMonth;
  final bool isPartialMonth;
  final String monthLabel;
  final AttendancePerformanceModel attendance;
  final CompletionPerformanceModel tasks;
  final CompletionPerformanceModel todos;
  final IssuePerformanceModel issues;
  final int? overallPercentage;
  final double? overallPercentageExact;
  final int applicableMetricCount;
  final String? overallNaReason;

  const MonthlyPerformanceModel({
    required this.employee,
    required this.month,
    required this.year,
    this.periodStart,
    this.periodEnd,
    this.calendarPeriodEnd,
    required this.isCurrentMonth,
    required this.isPartialMonth,
    required this.monthLabel,
    required this.attendance,
    required this.tasks,
    required this.todos,
    required this.issues,
    this.overallPercentage,
    this.overallPercentageExact,
    required this.applicableMetricCount,
    this.overallNaReason,
  });

  factory MonthlyPerformanceModel.fromJson(Map<String, dynamic> json) {
    return MonthlyPerformanceModel(
      employee: PerformanceEmployeeModel.fromJson(json),
      month: _int(json['month']),
      year: _int(json['year']),
      periodStart: _date(json['period_start']),
      periodEnd: _date(json['period_end']),
      calendarPeriodEnd: _date(json['calendar_period_end']),
      isCurrentMonth: _bool(json['is_current_month']),
      isPartialMonth: _bool(json['is_partial_month']),
      monthLabel: _string(json['month_label']),
      attendance: AttendancePerformanceModel.fromJson(_map(json['attendance'])),
      tasks: CompletionPerformanceModel.fromJson(_map(json['tasks'])),
      todos: CompletionPerformanceModel.fromJson(_map(json['todos'])),
      issues: IssuePerformanceModel.fromJson(_map(json['issues'])),
      overallPercentage: _nullableInt(json['overall_percentage']),
      overallPercentageExact: _nullableDouble(json['overall_percentage_exact']),
      applicableMetricCount: _int(json['applicable_metric_count']),
      overallNaReason: _optionalString(json['overall_na_reason']),
    );
  }

  bool get hasOverallPerformance => overallPercentage != null;
  String get displayOverall => overallPercentage == null ? 'N/A' : '$overallPercentage%';
}

class MonthlyPerformanceResponseModel {
  final bool success;
  final MonthlyPerformanceModel performance;

  const MonthlyPerformanceResponseModel({
    required this.success,
    required this.performance,
  });

  factory MonthlyPerformanceResponseModel.fromJson(Map<String, dynamic> json) {
    return MonthlyPerformanceResponseModel(
      success: _bool(json['success'], fallback: true),
      performance: MonthlyPerformanceModel.fromJson(_map(json['performance'])),
    );
  }
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

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

double _double(dynamic value, {double fallback = 0}) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? fallback;

double? _nullableDouble(dynamic value) {
  if (value == null || value.toString().trim().isEmpty) return null;
  return value is num ? value.toDouble() : double.tryParse(value.toString());
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
