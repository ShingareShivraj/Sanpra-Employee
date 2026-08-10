class AttendanceStatusModel {
  final bool success;
  final String status;
  final String checkInTime;
  final String checkOutTime;

  AttendanceStatusModel({
    required this.success,
    required this.status,
    required this.checkInTime,
    required this.checkOutTime,
  });

  factory AttendanceStatusModel.fromJson(Map<String, dynamic> json) {
    return AttendanceStatusModel(
      success: json["success"] ?? false,
      status: json["status"] ?? "Not Checked In",
      checkInTime: json["check_in_time"] ?? "",
      checkOutTime: json["check_out_time"] ?? "",
    );
  }
}