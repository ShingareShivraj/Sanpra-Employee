enum MeetingAttendanceStatus {
  invited('Invited'),
  attended('Attended'),
  absent('Absent');

  const MeetingAttendanceStatus(this.apiValue);

  final String apiValue;

  static MeetingAttendanceStatus fromApiValue(dynamic value) {
    final text = value?.toString().trim().toLowerCase();
    return MeetingAttendanceStatus.values.firstWhere(
      (status) => status.apiValue.toLowerCase() == text,
      orElse: () => MeetingAttendanceStatus.invited,
    );
  }
}

class MeetingParticipantModel {
  final String? rowName;
  final String employee;
  final String employeeName;
  final String? department;
  final String? designation;
  final String? image;
  final MeetingAttendanceStatus attendanceStatus;

  const MeetingParticipantModel({
    this.rowName,
    required this.employee,
    required this.employeeName,
    this.department,
    this.designation,
    this.image,
    this.attendanceStatus = MeetingAttendanceStatus.invited,
  });

  factory MeetingParticipantModel.fromJson(Map<String, dynamic> json) {
    final employee = _string(json['employee']);
    return MeetingParticipantModel(
      rowName: _optionalString(json['row_name'] ?? json['name']),
      employee: employee,
      employeeName: _string(json['employee_name'], fallback: employee),
      department: _optionalString(json['department']),
      designation: _optionalString(json['designation']),
      image: _optionalString(json['image']),
      attendanceStatus:
          MeetingAttendanceStatus.fromApiValue(json['attendance_status']),
    );
  }

  /// Payload used by create/update meeting APIs.
  Map<String, dynamic> toParticipantJson() => {'employee': employee.trim()};

  /// Payload used by update_meeting_attendance.
  Map<String, dynamic> toAttendanceJson() => {
        'employee': employee.trim(),
        'attendance_status': attendanceStatus.apiValue,
      };

  MeetingParticipantModel copyWith({
    String? rowName,
    String? employee,
    String? employeeName,
    String? department,
    String? designation,
    String? image,
    MeetingAttendanceStatus? attendanceStatus,
  }) {
    return MeetingParticipantModel(
      rowName: rowName ?? this.rowName,
      employee: employee ?? this.employee,
      employeeName: employeeName ?? this.employeeName,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      image: image ?? this.image,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
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
