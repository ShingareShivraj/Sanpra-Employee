import 'package:dio/dio.dart';

import '../model/attendance_responce.dart';
import 'api_endpoints.dart';
import 'api_service.dart';
import '../model/attendance_status_model.dart';
class AttendanceService {
  final ApiService _api = ApiService();

  // ==========================================================
  // CHECK IN
  // ==========================================================

  Future<AttendanceResponseModel> checkIn({
    required double latitude,
    required double longitude,
    String? deviceId,
  }) async {
    try {
      final Response response = await _api.post(
        url: ApiEndpoints.checkIn,
        data: {
          "log_type": "IN",
          "latitude": latitude,
          "longitude": longitude,
          "device_id": deviceId,
        },
      );

      return AttendanceResponseModel.fromJson(
        response.data["message"] ?? response.data,
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data["message"] ??
            e.message ??
            "Unable to check in.",
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ==========================================================
  // CHECK OUT
  // ==========================================================

  Future<AttendanceResponseModel> checkOut({
    required double latitude,
    required double longitude,
    String? deviceId,
  }) async {
    try {
      final Response response = await _api.post(
        url: ApiEndpoints.checkOut,
        data: {
          "log_type": "OUT",
          "latitude": latitude,
          "longitude": longitude,
          "device_id": deviceId,
        },
      );

      return AttendanceResponseModel.fromJson(
        response.data["message"] ?? response.data,
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data["message"] ??
            e.message ??
            "Unable to check out.",
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ==========================================================
  // TODAY STATUS
  // ==========================================================

  Future<AttendanceStatusModel> attendanceStatus() async {
    try {
      final response = await _api.get(
        url: ApiEndpoints.attendanceStatus,
      );

      return AttendanceStatusModel.fromJson(
        response.data["message"],
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data["message"] ??
            e.message ??
            "Unable to fetch attendance status.",
      );
    }
  }

  // ==========================================================
  // HISTORY
  // ==========================================================

  Future<Response> attendanceHistory() async {
    try {
      return await _api.get(
        url: ApiEndpoints.attendanceHistory,
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data["message"] ??
            e.message ??
            "Unable to fetch attendance history.",
      );
    }
  }
}