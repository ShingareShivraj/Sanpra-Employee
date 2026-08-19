import 'performance_employee_model.dart';

class PerformanceAccessModel {
  final bool success;
  final bool isPerformanceManager;
  final PerformanceEmployeeModel employee;
  final int defaultMonth;
  final int defaultYear;
  final int minimumYear;

  const PerformanceAccessModel({
    required this.success,
    required this.isPerformanceManager,
    required this.employee,
    required this.defaultMonth,
    required this.defaultYear,
    required this.minimumYear,
  });

  factory PerformanceAccessModel.fromJson(Map<String, dynamic> json) {
    final employeeJson = json['employee'] is Map
        ? Map<String, dynamic>.from(json['employee'] as Map)
        : <String, dynamic>{};
    return PerformanceAccessModel(
      success: _bool(json['success'], fallback: true),
      isPerformanceManager: _bool(json['is_performance_manager']),
      employee: PerformanceEmployeeModel.fromJson(employeeJson),
      defaultMonth: _int(json['default_month'], fallback: DateTime.now().month),
      defaultYear: _int(json['default_year'], fallback: DateTime.now().year),
      minimumYear: _int(json['minimum_year'], fallback: 2000),
    );
  }

  bool get canViewEmployeePerformance => isPerformanceManager;
}

class PerformanceDepartmentsModel {
  final bool success;
  final String? company;
  final List<String> departments;

  const PerformanceDepartmentsModel({
    required this.success,
    this.company,
    required this.departments,
  });

  factory PerformanceDepartmentsModel.fromJson(Map<String, dynamic> json) {
    final rows = json['departments'] is List ? json['departments'] as List : const [];
    final company = json['company']?.toString().trim() ?? '';
    return PerformanceDepartmentsModel(
      success: _bool(json['success'], fallback: true),
      company: company.isEmpty ? null : company,
      departments: rows
          .map((value) => value.toString().trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList(growable: false)
        ..sort(),
    );
  }
}

int _int(dynamic value, {required int fallback}) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? fallback;

bool _bool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  return {'1', 'true', 'yes', 'on'}.contains(value.toString().toLowerCase());
}
