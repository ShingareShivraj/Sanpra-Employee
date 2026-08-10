class AttendanceCalendarModel {
  final bool success;
  final String employee;
  final String company;
  final String financialYear;

  /// Key   = date in yyyy-MM-dd format
  /// Value = P / A / H / L
  ///
  /// P = Present
  /// A = Absent
  /// H = Half Day
  /// L = On Leave
  final Map<String, String> attendance;

  /// Key   = date in yyyy-MM-dd format
  /// Value = holiday description
  final Map<String, String> holidays;

  AttendanceCalendarModel({
    required this.success,
    required this.employee,
    required this.company,
    required this.financialYear,
    required this.attendance,
    required this.holidays,
  });

  factory AttendanceCalendarModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return AttendanceCalendarModel(
      success: json['success'] == true,
      employee: json['employee']?.toString() ?? '',
      company: json['company']?.toString() ?? '',
      financialYear:
      json['financial_year']?.toString() ?? '',

      attendance: _parseStringMap(
        json['attendance'],
      ),

      holidays: _parseStringMap(
        json['holidays'],
      ),
    );
  }

  /// Converts dynamic JSON maps into:
  ///
  /// Map<String, String>
  ///
  /// This protects the model if Frappe returns
  /// null or unexpected values.
  static Map<String, String> _parseStringMap(
      dynamic value,
      ) {
    if (value == null) {
      return {};
    }

    if (value is! Map) {
      return {};
    }

    return value.map(
          (key, value) => MapEntry(
        key.toString(),
        value?.toString() ?? '',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'employee': employee,
      'company': company,
      'financial_year': financialYear,
      'attendance': attendance,
      'holidays': holidays,
    };
  }

  // ============================================================
  // Attendance helpers
  // ============================================================

  /// Returns the attendance status for a date.
  ///
  /// Example:
  /// getAttendanceStatus('2026-08-10')
  /// → 'P'
  String? getAttendanceStatus(String date) {
    return attendance[date];
  }

  /// Returns the holiday name for a date.
  ///
  /// Example:
  /// getHolidayName('2026-08-15')
  /// → 'Independence Day'
  String? getHolidayName(String date) {
    return holidays[date];
  }

  /// Returns true if the date has an Attendance record.
  bool hasAttendance(String date) {
    return attendance.containsKey(date);
  }

  /// Returns true if the date is a holiday.
  bool isHoliday(String date) {
    return holidays.containsKey(date);
  }

  /// Returns the final display status for the calendar.
  ///
  /// Attendance has priority over holiday.
  ///
  /// P → Present
  /// A → Absent
  /// H → Half Day
  /// L → On Leave
  /// HOLIDAY → Holiday
  /// null → No record / unmarked
  String? getCalendarStatus(String date) {
    final attendanceStatus = attendance[date];

    // Attendance always gets priority.
    if (attendanceStatus != null) {
      return attendanceStatus;
    }

    // If there is no attendance, check holiday.
    if (holidays.containsKey(date)) {
      return 'HOLIDAY';
    }

    // No attendance and no holiday.
    return null;
  }

  // ============================================================
  // Summary helpers
  // ============================================================

  int get presentCount {
    return attendance.values
        .where((status) => status == 'P')
        .length;
  }

  int get absentCount {
    return attendance.values
        .where((status) => status == 'A')
        .length;
  }

  int get halfDayCount {
    return attendance.values
        .where((status) => status == 'H')
        .length;
  }

  int get onLeaveCount {
    return attendance.values
        .where((status) => status == 'L')
        .length;
  }

  int get holidayCount {
    return holidays.length;
  }
}