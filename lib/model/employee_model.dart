import 'task_model.dart';

class EmployeeModel {
  final String name;
  final String employeeName;
  final String userId;
  final String company;
  final String? department;
  final String? designation;
  final String? image;

  const EmployeeModel({
    required this.name,
    required this.employeeName,
    required this.userId,
    required this.company,
    this.department,
    this.designation,
    this.image,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) => EmployeeModel(
        name: json['name']?.toString() ?? '',
        employeeName: json['employee_name']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        company: json['company']?.toString() ?? '',
        department: _nullable(json['department']),
        designation: _nullable(json['designation']),
        image: _nullable(json['image']),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'employee_name': employeeName,
        'user_id': userId,
        'company': company,
        'department': department,
        'designation': designation,
        'image': image,
      };
}

class EmployeeListResponseModel {
  final bool success;
  final String message;
  final String? company;
  final int employeeCount;
  final List<EmployeeModel> employees;

  const EmployeeListResponseModel({
    required this.success,
    this.message = '',
    this.company,
    this.employeeCount = 0,
    this.employees = const [],
  });

  factory EmployeeListResponseModel.fromJson(Map<String, dynamic> json) {
    final data = unwrapFrappeResponse(json);
    final rows = data['employees'];
    final employees = rows is List
        ? rows
            .whereType<Map>()
            .map((row) => EmployeeModel.fromJson(Map<String, dynamic>.from(row)))
            .toList()
        : <EmployeeModel>[];

    return EmployeeListResponseModel(
      success: _bool(data['success']),
      message: data['message']?.toString() ?? '',
      company: _nullable(data['company']),
      employeeCount: _int(data['employee_count'], fallback: employees.length),
      employees: employees,
    );
  }
}

String? _nullable(dynamic value) =>
    value == null || value.toString().trim().isEmpty ? null : value.toString();
bool _bool(dynamic value) =>
    value == true || value == 1 || value == '1' || value == 'true';
int _int(dynamic value, {int fallback = 0}) => value is num
    ? value.toInt()
    : int.tryParse(value?.toString() ?? '') ?? fallback;
