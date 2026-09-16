import 'package:dio/dio.dart';

import '../model/attendance_calendar_model.dart';
import 'api_service.dart';
import '../services/api_endpoints.dart';
class AttendanceService {
  final ApiService _apiService;

  AttendanceService({
    ApiService? apiService,
  }) : _apiService = apiService ?? ApiService();

  // ============================================================
  // Attendance Calendar
  // ============================================================


  // ============================================================
  // Get Attendance Calendar
  // ============================================================

  Future<AttendanceCalendarModel> getAttendanceCalendar({
    required String fromDate,
    required String toDate,
  }) async {
    try {
      final Response response = await _apiService.post(
      url: ApiEndpoints.attendanceCalendar,
        data: {
          'from_date': fromDate,
          'to_date': toDate,
        },
      );

      final responseData = response.data;

      if (responseData == null) {
        throw Exception(
          'Empty response from attendance API',
        );
      }

      // Frappe whitelisted method response:
      //
      // {
      //   "message": {
      //      ...
      //   }
      // }

      final dynamic message =
      responseData['message'];

      if (message == null) {
        throw Exception(
          'Invalid attendance API response',
        );
      }

      if (message is! Map<String, dynamic>) {
        throw Exception(
          'Invalid attendance data received',
        );
      }

      final attendanceData =
      AttendanceCalendarModel.fromJson(message);

      if (!attendanceData.success) {
        throw Exception(
          'Unable to load attendance',
        );
      }

      return attendanceData;
    } on DioException catch (e) {
      throw Exception(
        _getDioErrorMessage(e),
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  Future<ShiftInfoModel> getMyShiftInfo() async {
    try {
      final Response response = await _apiService.post(
        url: ApiEndpoints.myShiftInfo,
        data: {},
      );

      final responseData = response.data;

      if (responseData == null) {
        throw Exception(
          'Empty response from shift info API',
        );
      }

      final dynamic message = responseData['message'];

      if (message == null) {
        throw Exception(
          'Invalid shift info API response',
        );
      }

      if (message is! Map<String, dynamic>) {
        throw Exception(
          'Invalid shift information received',
        );
      }

      final shiftData = ShiftInfoModel.fromJson(message);

      if (!shiftData.success) {
        throw Exception(
          'Unable to load shift information',
        );
      }

      return shiftData;
    } on DioException catch (e) {
      throw Exception(
        _getDioErrorMessage(e),
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  // ============================================================
  // Dio Error Handling
  // ============================================================

  String _getDioErrorMessage(
      DioException error,
      ) {
    if (error.response != null) {
      final data = error.response?.data;

      if (data is Map<String, dynamic>) {
        final message = data['message'];

        if (message != null) {
          return message.toString();
        }

        final exception = data['exception'];

        if (exception != null) {
          return exception.toString();
        }
      }

      return 'Server error: ${error.response?.statusCode}';
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please try again.';

      case DioExceptionType.sendTimeout:
        return 'Request timeout. Please try again.';

      case DioExceptionType.receiveTimeout:
        return 'Server took too long to respond.';

      case DioExceptionType.connectionError:
        return 'Unable to connect to the server.';

      case DioExceptionType.cancel:
        return 'Request was cancelled.';

      case DioExceptionType.badCertificate:
        return 'Secure connection failed.';

      case DioExceptionType.badResponse:
        return 'Invalid server response.';

      case DioExceptionType.unknown:
        return 'Something went wrong. Please try again.';

      default:
        return 'Something went wrong. Please try again.';
    }
  }
}