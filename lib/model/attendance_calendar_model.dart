class AttendanceDetail {
  final String? checkIn;
  final String? checkOut;
  final String? shiftType;
  final double workingHours;
  final bool lateEntry;

  AttendanceDetail({
    this.checkIn,
    this.checkOut,
    this.shiftType,
    required this.workingHours,
    this.lateEntry = false,


  });

  factory AttendanceDetail.fromJson(Map<String, dynamic> json) {
    return AttendanceDetail(
      checkIn: json['check_in']?.toString(),
      checkOut: json['check_out']?.toString(),
      shiftType: json['shift_type']?.toString(),
      workingHours: (json['working_hours'] as num?)?.toDouble() ?? 0,
      lateEntry: json['late_entry'] == 1 ||
          json['late_entry'] == true,

    );
  }
}

class ShiftInfoModel {
  final bool success;
  final String employee;
  final ShiftInfo? shift;

  ShiftInfoModel({
    required this.success,
    required this.employee,
    this.shift,
  });

  factory ShiftInfoModel.fromJson(Map<String, dynamic> json) {
    return ShiftInfoModel(
      success: json['success'] == true,
      employee: json['employee']?.toString() ?? '',
      shift: json['shift'] != null
          ? ShiftInfo.fromJson(
        Map<String, dynamic>.from(json['shift']),
      )
          : null,
    );
  }
}

class ShiftInfo {
  final String name;
  final String? startTime;
  final String? endTime;
  final String? holidayList;
  final double halfDayThreshold;
  final double absentThreshold;
  final dynamic beginCheckInBeforeShiftStartTime;
  final dynamic allowCheckOutAfterShiftEndTime;
  final bool enableAutoAttendance;
  final bool determineCheckInAndCheckOut;

  ShiftInfo({
    required this.name,
    this.startTime,
    this.endTime,
    this.holidayList,
    required this.halfDayThreshold,
    required this.absentThreshold,
    this.beginCheckInBeforeShiftStartTime,
    this.allowCheckOutAfterShiftEndTime,
    required this.enableAutoAttendance,
    required this.determineCheckInAndCheckOut,
  });

  factory ShiftInfo.fromJson(Map<String, dynamic> json) {
    return ShiftInfo(
      name: json['name']?.toString() ?? '',
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      holidayList: json['holiday_list']?.toString(),
      halfDayThreshold:
      (json['working_hours_threshold_for_half_day'] as num?)
          ?.toDouble() ??
          0,
      absentThreshold:
      (json['working_hours_threshold_for_absent'] as num?)
          ?.toDouble() ??
          0,
      beginCheckInBeforeShiftStartTime:
      json['begin_check_in_before_shift_start_time'],
      allowCheckOutAfterShiftEndTime:
      json['allow_check_out_after_shift_end_time'],
      enableAutoAttendance:
      json['enable_auto_attendance'] == 1 ||
          json['enable_auto_attendance'] == true,
      determineCheckInAndCheckOut:
      json['determine_check_in_and_check_out'] == 1 ||
          json['determine_check_in_and_check_out'] == true,
    );
  }
}


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
  final Map<String, AttendanceDetail> attendanceDetails;

  AttendanceCalendarModel({
    required this.success,
    required this.employee,
    required this.company,
    required this.financialYear,
    required this.attendance,
    required this.attendanceDetails,
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
      attendanceDetails: _parseAttendanceDetails(
        json['attendance_details'],
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
  ///
  static Map<String, AttendanceDetail> _parseAttendanceDetails(
      dynamic value) {
    if (value == null || value is! Map) {
      return {};
    }

    return value.map(
          (key, value) => MapEntry(
        key.toString(),
        AttendanceDetail.fromJson(
          Map<String, dynamic>.from(value),
        ),
      ),
    );
  }
  AttendanceDetail? getAttendanceDetail(String date) {
    return attendanceDetails[date];
  }
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