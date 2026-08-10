class EmployeeProfileModel {
  final String image;
  final String employeeName;
  final String employeeId;
  final String email;
  final String cellNumber;
  final String gender;
  final DateTime? dateOfBirth;
  final String company;
  final String department;
  final String designation;
  final String reportsTo;
  final String reportsToName;
  final String employmentType;
  final String status;

  const EmployeeProfileModel({
    required this.image,
    required this.employeeName,
    required this.employeeId,
    required this.email,
    required this.cellNumber,
    required this.gender,
    required this.dateOfBirth,
    required this.company,
    required this.department,
    required this.designation,
    required this.reportsTo,
    required this.reportsToName,
    required this.employmentType,
    required this.status,
  });

  factory EmployeeProfileModel.fromJson(Map<String, dynamic> json) {
    String text(String key) => json[key]?.toString().trim() ?? '';
    return EmployeeProfileModel(
      image: text('image'),
      employeeName: text('employee_name'),
      employeeId: text('employee_id'),
      email: text('email'),
      cellNumber: text('cell_number'),
      gender: text('gender'),
      dateOfBirth: DateTime.tryParse(text('date_of_birth')),
      company: text('company'),
      department: text('department'),
      designation: text('designation'),
      reportsTo: text('reports_to'),
      reportsToName: text('reports_to_name'),
      employmentType: text('employment_type'),
      status: text('status'),
    );
  }
}

class EmployeeProfileResponseModel {
  final bool success;
  final String message;
  final EmployeeProfileModel? profile;

  const EmployeeProfileResponseModel({
    required this.success,
    required this.message,
    required this.profile,
  });

  factory EmployeeProfileResponseModel.fromJson(Map<String, dynamic> json) {
    final raw = json['profile'];
    return EmployeeProfileResponseModel(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      profile: raw is Map
          ? EmployeeProfileModel.fromJson(Map<String, dynamic>.from(raw))
          : null,
    );
  }
}
