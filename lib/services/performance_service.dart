import 'dart:convert';

import 'package:dio/dio.dart';

import '../model/performance/monthly_performance_model.dart';
import '../model/performance/performance_access_model.dart';
import '../model/performance/performance_employee_model.dart';
import 'api_endpoints.dart';
import 'api_service.dart';

class PerformanceService {
  final ApiService _api;

  PerformanceService({ApiService? api}) : _api = api ?? ApiService();

  /// Returns employee identity, default month/year, and manager access.
  Future<PerformanceAccessModel> getPerformanceAccess() async {
    final data = await _get(ApiEndpoints.performanceAccess);
    return PerformanceAccessModel.fromJson(data);
  }

  /// Returns the authenticated employee's own monthly performance.
  Future<MonthlyPerformanceModel> getMyPerformance({
    required int month,
    required int year,
  }) async {
    _validatePeriod(month, year);
    final data = await _get(
      ApiEndpoints.myMonthlyPerformance,
      query: {'month': month, 'year': year},
    );
    return MonthlyPerformanceResponseModel.fromJson(data).performance;
  }

  /// Returns a specific employee's report.
  ///
  /// Backend authorization remains authoritative: a normal employee cannot
  /// use this method to access another employee's data.
  Future<MonthlyPerformanceModel> getEmployeePerformance({
    required String employee,
    required int month,
    required int year,
  }) async {
    _validatePeriod(month, year);
    _required(employee, 'Employee is required.');
    final data = await _get(
      ApiEndpoints.monthlyPerformance,
      query: {
        'employee': employee.trim(),
        'month': month,
        'year': year,
      },
    );
    return MonthlyPerformanceResponseModel.fromJson(data).performance;
  }

  /// Returns the manager's paginated, same-company employee report list.
  Future<EmployeesPerformanceResponseModel> getEmployeesPerformance({
    required int month,
    required int year,
    String? search,
    String? department,
    int start = 0,
    int pageLength = 25,
  }) async {
    _validatePeriod(month, year);
    final data = await _get(
      ApiEndpoints.employeesMonthlyPerformance,
      query: {
        'month': month,
        'year': year,
        if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
        if (department?.trim().isNotEmpty == true) 'department': department!.trim(),
        'start': start < 0 ? 0 : start,
        'page_length': pageLength.clamp(1, 100),
      },
    );
    return EmployeesPerformanceResponseModel.fromJson(data);
  }

  /// Returns same-company departments for the optional manager filter.
  Future<PerformanceDepartmentsModel> getPerformanceDepartments() async {
    final data = await _get(ApiEndpoints.performanceDepartments);
    return PerformanceDepartmentsModel.fromJson(data);
  }

  Future<Map<String, dynamic>> _get(
    String url, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _api.get(url: url, queryParameters: query);
      return _requireSuccess(_unwrapMessage(response.data));
    } on DioException catch (error) {
      throw PerformanceServiceException(_dioMessage(error));
    } on PerformanceServiceException {
      rethrow;
    } catch (error) {
      throw PerformanceServiceException(_cleanError(error));
    }
  }

  Map<String, dynamic> _unwrapMessage(dynamic value) {
    final root = _map(value);
    return root['message'] is Map ? _map(root['message']) : root;
  }

  Map<String, dynamic> _requireSuccess(Map<String, dynamic> data) {
    if (data['success'] == false) {
      throw PerformanceServiceException(
        data['message']?.toString().trim().isNotEmpty == true
            ? data['message'].toString()
            : 'Unable to load performance data.',
      );
    }
    return data;
  }

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  void _validatePeriod(int month, int year) {
    if (month < 1 || month > 12) {
      throw const PerformanceServiceException('Month must be between 1 and 12.');
    }
    if (year < 2000) {
      throw const PerformanceServiceException('Please select a valid report year.');
    }
  }

  void _required(String value, String message) {
    if (value.trim().isEmpty) throw PerformanceServiceException(message);
  }

  String _dioMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final serverMessages = data['_server_messages'];
      if (serverMessages is String && serverMessages.isNotEmpty) {
        try {
          final decoded = jsonDecode(serverMessages);
          if (decoded is List && decoded.isNotEmpty) {
            final first = jsonDecode(decoded.first.toString());
            if (first is Map && first['message'] != null) {
              return _stripHtml(first['message'].toString());
            }
          }
        } catch (_) {}
      }

      final message = data['message'];
      if (message is Map && message['message'] != null) {
        return _stripHtml(message['message'].toString());
      }
      if (message is String && message.trim().isNotEmpty) {
        return _stripHtml(message);
      }
      if (data['exception'] != null) {
        return _cleanExceptionName(data['exception'].toString());
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The performance request timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to the server.';
      default:
        return error.message ?? 'Unable to load performance data.';
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  String _cleanExceptionName(String value) {
    final text = value.split('\n').first.trim();
    return text.replaceFirst(RegExp(r'^[\w.]+:\s*'), '');
  }

  String _stripHtml(String value) {
    return value.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}

class PerformanceServiceException implements Exception {
  final String message;

  const PerformanceServiceException(this.message);

  @override
  String toString() => message;
}
