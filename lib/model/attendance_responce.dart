class AttendanceResponseModel {
  final bool success;
  final String message;
  final String employee;
  final String checkin;
  final String time;

  AttendanceResponseModel({
    required this.success,
    required this.message,
    required this.employee,
    required this.checkin,
    required this.time,
  });

  factory AttendanceResponseModel.fromJson(
      Map<String, dynamic> json) {

    return AttendanceResponseModel(
      success: json["success"] ?? false,
      message: json["message"] ?? "",
      employee: json["employee"] ?? "",
      checkin: json["checkin"] ?? "",
      time: json["time"] ?? "",
    );
  }
}